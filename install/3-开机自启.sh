#!/bin/bash
# ============================================================
#  OpenHW Lab · M301H 下载机 + NAS —— 子系统启动脚本 (/root/nasstart.sh)
#  起 aria2 + samba(网盘) + minidlna(DLNA) + 管理面板 nasd(:8080)
#  由盒子侧 /data/nasstart.sh chroot 调用（开机自启）。幂等。
# ============================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root

# 存储根：默认子系统内 /root/nas；接 USB 硬盘时改成 /media/usb/nas（并先 mount）
NAS_ROOT="${NAS_ROOT:-/root/nas}"
mkdir -p "$NAS_ROOT/downloads" "$NAS_ROOT/media" 2>/dev/null
mkdir -p /var/log/samba /var/lib/samba/private /var/run/samba /var/lib/samba/usershares \
         /run/samba /run/minidlna /var/cache/minidlna /var/log 2>/dev/null
[ -f /root/aria2.session ] || touch /root/aria2.session

# aria2 下载引擎
pgrep -f '[a]ria2c' >/dev/null 2>&1 || aria2c --conf-path=/root/aria2.conf -D 2>/dev/null

# Samba 网盘
pgrep -x smbd >/dev/null 2>&1 || smbd -D -s /root/smb.conf 2>/dev/null
pgrep -x nmbd >/dev/null 2>&1 || nmbd -D -s /root/smb.conf 2>/dev/null

# 管理面板 :8080
pgrep -f '[n]asd.py' >/dev/null 2>&1 || \
  NAS_ROOT="$NAS_ROOT" NAS_DL="$NAS_ROOT/downloads" ARIANG_DIR=/root/ariang \
  nohup python3 /root/nasd.py >>/root/nasd.log 2>&1 </dev/null &

# DLNA 媒体库（可选）
if [ -f /root/minidlna.conf ]; then
  pgrep -x minidlnad >/dev/null 2>&1 || minidlnad -f /root/minidlna.conf 2>/dev/null
fi

# 存储自动切换：插了外接盘就下载/网盘切到它，拔了回内部（每 10s 巡检）
pgrep -f '[d]iskwatch\.sh' >/dev/null 2>&1 || \
  setsid nohup sh -c 'while true; do bash /root/diskwatch.sh >>/root/diskwatch.log 2>&1; sleep 10; done' >/dev/null 2>&1 </dev/null &

sleep 1
echo "nasstart done: aria2=$(pgrep -c -f '[a]ria2c') smbd=$(pgrep -c -x smbd) nmbd=$(pgrep -c -x nmbd) nasd=$(pgrep -c -f '[n]asd.py') $(date)"
