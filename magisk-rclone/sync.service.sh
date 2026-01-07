#!/system/bin/sh

touch "$RCLONESYNC_PID"

SYNC_LOG="$RCLONE_LOG_DIR/rclone_sync.log"
TASK_COUNT=0

sync_all() {
  TASK_COUNT=0
  # rclone sync
  if [ -f "$RCLONESYNC_CONF" ]; then
    unset RCLONE_RC 
    while read -r line; do
      # 跳过空行和注释
      [ -z "$line" ] && continue
      echo "$line" | grep -qE '^\s*#' && continue

      args=( $line )
      nice -n 19 ionice -c3 /vendor/bin/rclone sync "${args[@]}" >> "$SYNC_LOG" 2>&1
      if [ $? -ne 0 ]; then
        echo "Error: rclone sync failed for arguments: ${args[*]}" >> "$SYNC_LOG"
      fi
      TASK_COUNT=$((TASK_COUNT + 1))
    done < "$RCLONESYNC_CONF"
  fi

  # rclone copy
  if [ -f "$RCLONECOPY_CONF" ]; then
    COPY_LOG="$RCLONE_LOG_DIR/rclone_copy.log"
    unset RCLONE_RC 
    while read -r line; do
      # 跳过空行和注释
      [ -z "$line" ] && continue
      echo "$line" | grep -qE '^\s*#' && continue

      args=( $line )
      nice -n 19 ionice -c3 /vendor/bin/rclone copy "${args[@]}" >> "$COPY_LOG" 2>&1
      if [ $? -ne 0 ]; then
        echo "Error: rclone copy failed for arguments: ${args[*]}" >> "$COPY_LOG"
      fi
      TASK_COUNT=$((TASK_COUNT + 1))
    done < "$RCLONECOPY_CONF"
  fi
}

rm -f "$SYNC_LOG"
while [ -f "$RCLONESYNC_PID" ]; do
  sync_all
  if [ $TASK_COUNT -eq 0 ]; then
    echo "No sync or copy tasks found in configuration files." >> "$SYNC_LOG"
    rm -f "$RCLONESYNC_PID"
    break
  fi
  sleep 180
done