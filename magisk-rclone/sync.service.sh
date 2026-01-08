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
  # 检查危险字符：反引号、命令替换、管道、重定向、变量扩展等
  # Check for dangerous characters: backticks, command substitution, pipes, redirects, variable expansion, etc.
  case "$line" in
    *\`*)
      echo "Error: Line contains backticks, skipping: $line" >> "$logfile"
      return 1
      ;;
    *\$\(*)
      echo "Error: Line contains command substitution \$(), skipping: $line" >> "$logfile"
      return 1
      ;;
    *\$\{*)
      echo "Error: Line contains parameter expansion \${}, skipping: $line" >> "$logfile"
      return 1
      ;;
    *\;*)
      echo "Error: Line contains semicolon, skipping: $line" >> "$logfile"
      return 1
      ;;
    *\|*)
      echo "Error: Line contains pipe, skipping: $line" >> "$logfile"
      return 1
      ;;
    *\&\&*|*\|\|*)
      echo "Error: Line contains logical operators, skipping: $line" >> "$logfile"
      return 1
      ;;
  esac
  
  # 检查行尾的后台运算符和重定向
  # Check for background operator and redirection at line boundaries
  # 注意：不检查中间的 & 和 < > 以允许 URL 参数和其他合法用途
  # Note: Don't check for & and < > in the middle to allow URL parameters and other legitimate uses
  case "$line" in
    *\&\ *|*\ \&)
      echo "Error: Line contains background operator, skipping: $line" >> "$logfile"
      return 1
      ;;
  esac
  
  # 检查不平衡的引号（可能导致注入）
  # Check for unbalanced quotes (could lead to injection)
  _count_quotes() {
    _str="$1"
    _quote="$2"
    _count=0
    while [ -n "$_str" ]; do
      case "$_str" in
        *"$_quote"*)
          _count=$((_count + 1))
          _str="${_str#*"$_quote"}"
          ;;
        *)
          break
          ;;
      esac
    done
    echo "$_count"
  }
  
  _dquote_count=$(_count_quotes "$line" '"')
  _squote_count=$(_count_quotes "$line" "'")
  
  if [ $((_dquote_count % 2)) -ne 0 ]; then
    echo "Error: Unbalanced double quotes in line, skipping: $line" >> "$logfile"
    return 1
  fi
  
  if [ $((_squote_count % 2)) -ne 0 ]; then
    echo "Error: Unbalanced single quotes in line, skipping: $line" >> "$logfile"
    return 1
  fi
  
  # 使用 eval 安全地解析引号参数
  # Use eval to safely parse quoted arguments after validation
  # 注意：eval 在验证后是安全的，因为：
  # Note: eval is safe after validation because:
  # 1. 所有危险字符已被阻止（命令注入、变量扩展等）
  # 1. All dangerous characters are blocked (command injection, variable expansion, etc.)
  # 2. POSIX sh 没有内置的引号解析器，eval 是唯一可移植的方法
  # 2. POSIX sh has no built-in quote parser, eval is the only portable method
  # 3. 替代方案（如 xargs、自定义解析器）在 Android 5+ 上不可用或太复杂
  # 3. Alternatives (like xargs, custom parsers) are unavailable on Android 5+ or too complex
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