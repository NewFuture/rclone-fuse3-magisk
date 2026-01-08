#!/system/bin/sh

touch "$RCLONESYNC_PID"

SYNC_LOG="$RCLONE_LOG_DIR/rclone_sync.log"
TASK_COUNT=0

# 安全解析参数行 (支持带空格的引号参数)
# Safely parse argument line (supports quoted arguments with spaces)
# Args: $1 = line to parse, $2 = command (sync/copy), $3 = log file
parse_and_execute() {
  line="$1"
  cmd="$2"
  logfile="$3"
  
  # 验证输入，防止命令注入
  # Validate input to prevent command injection
  # 检查危险字符：反引号、命令替换、管道、重定向等
  # Check for dangerous characters: backticks, command substitution, pipes, redirects, etc.
  case "$line" in
    *\`*|*\$\(*|*\;*|*\|*|*\&\&*|*\|\|*|*\>*|*\<*|*\&*)
      echo "Error: Line contains unsafe characters, skipping: $line" >> "$logfile"
      return 1
      ;;
  esac
  
  # 使用 eval 安全地解析引号参数
  # Use eval to safely parse quoted arguments after validation
  eval "set -- $line"
  
  # 执行 rclone 命令
  # Execute rclone command
  nice -n 19 ionice -c3 /vendor/bin/rclone "$cmd" "$@" >> "$logfile" 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: rclone $cmd failed for arguments: $*" >> "$logfile"
    return 1
  fi
  return 0
}

sync_all() {
  TASK_COUNT=0
  # rclone sync
  if [ -f "$RCLONESYNC_CONF" ]; then
    unset RCLONE_RC 
    while read -r line; do
      # 跳过空行和注释
      # Skip empty lines and comments
      [ -z "$line" ] && continue
      echo "$line" | grep -qE '^\s*#' && continue

      # 解析并执行同步任务
      # Parse and execute sync task
      parse_and_execute "$line" "sync" "$SYNC_LOG" && TASK_COUNT=$((TASK_COUNT + 1))
    done < "$RCLONESYNC_CONF"
  fi

  # rclone copy
  if [ -f "$RCLONECOPY_CONF" ]; then
    COPY_LOG="$RCLONE_LOG_DIR/rclone_copy.log"
    unset RCLONE_RC 
    while read -r line; do
      # 跳过空行和注释
      # Skip empty lines and comments
      [ -z "$line" ] && continue
      echo "$line" | grep -qE '^\s*#' && continue

      # 解析并执行复制任务
      # Parse and execute copy task
      parse_and_execute "$line" "copy" "$COPY_LOG" && TASK_COUNT=$((TASK_COUNT + 1))
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