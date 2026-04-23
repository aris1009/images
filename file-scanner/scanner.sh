#!/bin/sh
# scanner.sh — generic ClamAV-backed file scanner
# Reads /config/scanner.json and spawns one inotifywait watcher per pipeline.
# Clean files move to the clean dir; infected files go to quarantine + ntfy alert.
#
# set -e is intentionally NOT used: mv/curl failures must not crash the long-running watcher.
set -u

CONFIG=/config/scanner.json

CLAMD_HOST=$(jq -r '.clamd.host' "$CONFIG")
CLAMD_PORT=$(jq -r '.clamd.port' "$CONFIG")
NTFY_URL=$(jq -r '.ntfy.url' "$CONFIG")
NTFY_TOPIC=$(jq -r '.ntfy.topic' "$CONFIG")

# Generate a minimal clamdscan config pointing at the remote clamd
CLAMD_CONF=$(mktemp)
trap 'rm -f "$CLAMD_CONF"' EXIT
printf 'TCPSocket %s\nTCPAddr %s\n' "$CLAMD_PORT" "$CLAMD_HOST" > "$CLAMD_CONF"

# Wait for clamd to accept connections before starting watchers
echo "[scanner] Waiting for clamd at ${CLAMD_HOST}:${CLAMD_PORT}..."
until nc -z "$CLAMD_HOST" "$CLAMD_PORT" 2>/dev/null; do
    echo "[scanner] clamd not ready, retrying in 5s..."
    sleep 5
done
echo "[scanner] clamd is ready"

# scan_file: scan one file and route it to clean or quarantine.
# Never exits non-zero — errors are logged, file is left in place for retry.
scan_file() {
    name="$1"
    filepath="$2"
    clean_dir="$3"
    quarantine_dir="$4"
    filename=$(basename "$filepath")

    [ -f "$filepath" ] || return 0

    echo "[scanner:${name}] Scanning: ${filename}"

    scan_output=""
    if scan_output=$(clamdscan --stream --config-file="$CLAMD_CONF" "$filepath" 2>&1); then
        echo "[scanner:${name}] CLEAN: ${filename}"
        # Use cp + rm instead of mv: staging and consume are different bind mounts,
        # so mv falls back to copy+chown which fails without CAP_CHOWN.
        if cp "$filepath" "${clean_dir}/${filename}" && rm -f "$filepath"; then
            : # success
        else
            echo "[scanner:${name}] ERROR: could not move ${filename} to consume — check permissions" >&2
        fi
    else
        exit_code=$?
        if [ "$exit_code" -eq 1 ]; then
            echo "[scanner:${name}] INFECTED: ${filename} — quarantining"
            if mv "$filepath" "${quarantine_dir}/${filename}"; then
                if [ -n "${NTFY_TOKEN:-}" ]; then
                    curl -sf \
                        -H "Authorization: Bearer ${NTFY_TOKEN}" \
                        -H "Title: Infected file quarantined" \
                        -H "Priority: high" \
                        -H "Tags: warning,virus" \
                        -d "Pipeline: ${name} | File: ${filename}" \
                        "${NTFY_URL}/${NTFY_TOPIC}" || true
                fi
            else
                echo "[scanner:${name}] ERROR: could not quarantine ${filename}" >&2
            fi
        else
            # exit 2 = error (clamd unreachable, permission denied, etc.)
            # Leave file in staging; it will be retried on next inotify event or restart.
            echo "[scanner:${name}] ERROR (exit ${exit_code}): ${filename} — leaving in staging" >&2
            printf '%s\n' "$scan_output" >&2
        fi
    fi
}

# watch_pipeline: drain existing files, then watch for new ones.
# Restarts inotifywait automatically if it exits unexpectedly.
watch_pipeline() {
    name="$1"
    watch_dir="$2"
    clean_dir="$3"
    quarantine_dir="$4"

    mkdir -p "$watch_dir" "$clean_dir" "$quarantine_dir"
    echo "[scanner:${name}] Watching ${watch_dir}"

    # Drain any files already present (inotify won't fire for pre-existing files)
    # find -r covers subdirectories created by downloaders (e.g. Author/Title/book.epub)
    find "$watch_dir" -type f | while IFS= read -r existing; do
        scan_file "$name" "$existing" "$clean_dir" "$quarantine_dir"
    done

    # Periodic sweep: catches files dropped into new subdirs faster than inotifywait
    # can add them to its watch list (race condition on rapid mkdir+write).
    periodic_sweep() {
        while true; do
            sleep 30
            find "$watch_dir" -type f | while IFS= read -r existing; do
                scan_file "$name" "$existing" "$clean_dir" "$quarantine_dir"
            done
        done
    }
    periodic_sweep &

    while true; do
        # -r: recursive (catches files in subdirs created by LL or other downloaders)
        # %w%f: full path including subdir, not just filename
        inotifywait -m -r -e close_write,moved_to --format '%w%f' "$watch_dir" 2>/dev/null |
        while IFS= read -r filepath; do
            scan_file "$name" "$filepath" "$clean_dir" "$quarantine_dir"
        done

        echo "[scanner:${name}] inotifywait exited, restarting in 2s..."
        sleep 2

        # Drain any files that arrived while inotifywait was down
        find "$watch_dir" -type f | while IFS= read -r existing; do
            scan_file "$name" "$existing" "$clean_dir" "$quarantine_dir"
        done
    done
}

# Spawn one watcher per pipeline defined in the JSON config
pipeline_count=$(jq '.pipelines | length' "$CONFIG")
i=0
while [ "$i" -lt "$pipeline_count" ]; do
    name=$(jq -r ".pipelines[$i].name" "$CONFIG")
    watch=$(jq -r ".pipelines[$i].watch" "$CONFIG")
    clean=$(jq -r ".pipelines[$i].clean" "$CONFIG")
    quarantine=$(jq -r ".pipelines[$i].quarantine" "$CONFIG")

    watch_pipeline "$name" "$watch" "$clean" "$quarantine" &
    i=$((i + 1))
done

echo "[scanner] ${pipeline_count} pipeline(s) started. Waiting..."
wait
