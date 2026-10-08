#!/system/bin/sh
# 在 /data/linux chroot 里执行命令。用法: cr.sh "cmd ..."
exec /system/bin/busybox chroot /data/linux /usr/bin/env -i \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/root TERM=xterm LANG=C.UTF-8 LC_ALL=C.UTF-8 \
  /bin/bash -lc "$*"
