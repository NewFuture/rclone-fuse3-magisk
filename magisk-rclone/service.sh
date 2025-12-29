#!/system/bin/sh
# This script runs at boot to ensure rclone mounts are established.

L(){
  log -t Magisk "[rclone] $1"
}

L "service script started:"  

[ "${MODPATH}"x = ""x ] && MODPATH="${0%/*}"
L "load env: $MODPATH/env"
set -a && . "$MODPATH/env" && set +a

sed -i 's/^description=\(.\{1,4\}| \)\?/description=/' "$RCLONEPROP"

# Wait for the system to boot completely
COUNT=0
until { [ "$(getprop sys.boot_completed)" = "1" ] && [ "$(getprop init.svc.bootanim)" = "stopped" ] && [ -e "/sdcard" ]; } || [ $((COUNT++)) -ge 20 ]; do 
  sleep 10;
done
L "system is ready after ${COUNT}. Starting the mounting process."

/vendor/bin/rclone listremotes | sed 's/:$//' | while read -r remote; do
  L "mount $remote => /mnt/rclone-$remote => /sdcard/$remote"
  /vendor/bin/rclone-mount "$remote" --daemon
done

L "all remotes mounted successfully."

sed -i 's/^description=\(.\{1,4\}| \)\?/description=🚀| /' "$RCLONEPROP"

# rclone sync
nice -n 19 ionice -c3 "$MODPATH/sync.service.sh" &
echo $! > "$RCLONESYNC_PID"
L "sync.service.sh started, PID: $(cat "$RCLONESYNC_PID")"

L "service script finished!"
