#!/bin/bash
# ============================================================
#  OpenHW Lab · M301H 存储自动切换（单次执行，由 nasstart 循环调用）
#  规则：插了外接盘/U盘 -> 下载 & 网盘 都用它；没插 -> 用内部存储。
#  实现：活动存储根始终是 /root/nas（SMB/面板/aria2 都指它）；
#        有外接盘时 bind-mount <盘>/nas 到 /root/nas，拔盘则卸载回内部目录。
# ============================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NAS=/root/nas
MARK=/root/nas-active
MANUAL=/media/usb
REM_FS='vfat|exfat|ntfs|ntfs-3g|fuseblk|iso9660|udf'
log(){ echo "$(date '+%F %T') $*"; }

# 找可写外接盘挂载点 -> 打印到 stdout 并 return 0
find_ext(){
  local src mp fs
  while read -r src mp fs rest; do
    case "$fs" in
      vfat|exfat|ntfs|ntfs-3g|fuseblk|iso9660|udf) ;;
      *) continue ;;
    esac
    case "$mp" in
      /storage/emulated*|/mnt/secure*|/mnt/asec*) continue ;;
      /mnt/media_rw/*|/storage/*|/mnt/sd*|/mnt/usb*) ;;
      *) continue ;;
    esac
    [ -d "$mp" ] || continue
    if ( : > "$mp/.wtest" ) 2>/dev/null; then rm -f "$mp/.wtest"; echo "$mp"; return 0; fi
  done < /proc/mounts
  # 未挂载的 sd 分区：手动挂（NTFS/exFAT/FAT）
  local dev
  for dev in $(ls /dev/block/sd*[0-9] 2>/dev/null); do
    grep -q "^$dev " /proc/mounts && continue
    mkdir -p "$MANUAL"
    if ntfs-3g -o rw,uid=0,gid=0,umask=0 "$dev" "$MANUAL" 2>/dev/null \
      || mount -t exfat -o rw,uid=0,gid=0,umask=0 "$dev" "$MANUAL" 2>/dev/null \
      || mount -t vfat  -o rw,uid=0,gid=0,umask=0,iocharset=utf8 "$dev" "$MANUAL" 2>/dev/null; then
      echo "$MANUAL"; return 0
    fi
  done
  return 1
}

bound_cur(){ grep " $NAS " /proc/mounts 2>/dev/null | awk '{print $1}' | head -1; }

mkdir -p "$NAS/downloads" "$NAS/media" 2>/dev/null
EXT="$(find_ext || true)"

if [ -n "$EXT" ]; then
  EXT_NAS="$EXT/nas"
  mkdir -p "$EXT_NAS/downloads" "$EXT_NAS/media" 2>/dev/null
  if [ -d "$EXT_NAS" ] && ( : > "$EXT_NAS/.wtest" ) 2>/dev/null; then
    rm -f "$EXT_NAS/.wtest"
    if [ "$(bound_cur)" != "$EXT_NAS" ]; then
      umount "$NAS" 2>/dev/null || umount -l "$NAS" 2>/dev/null
      if mount --bind "$EXT_NAS" "$NAS" 2>/dev/null; then
        log "存储切换到外接盘: $EXT_NAS"
      fi
    fi
    echo "USB:$EXT_NAS" > "$MARK"
  else
    [ -n "$(bound_cur)" ] && { umount "$NAS" 2>/dev/null; log "外接盘不可写 -> 回到内部存储"; }
    echo "internal" > "$MARK"
  fi
else
  if [ -n "$(bound_cur)" ]; then
    umount "$NAS" 2>/dev/null || umount -l "$NAS" 2>/dev/null
    log "外接盘已移除 -> 回到内部存储"
  fi
  echo "internal" > "$MARK"
fi
