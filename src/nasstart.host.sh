#!/system/bin/sh
# ============================================================
#  OpenHW Lab · M301H 下载机 + NAS 开机自启（Android 根上下文）
#  挂子系统 /data/linux -> chroot 跑 /root/nasstart.sh
#  -> 延时把「下载机 · NAS」桌面拉到前台
#  由 /system/etc/init.bigfish.sh 头部在 on boot 时后台调用。
# ============================================================
R=/data/linux

# 等子系统就绪
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  [ -d $R/usr ] && break
  /system/bin/busybox sleep 1
done

/system/bin/busybox mount -t proc  proc  $R/proc   2>/dev/null
/system/bin/busybox mount -t sysfs sysfs $R/sys    2>/dev/null
/system/bin/busybox mount -o bind  /dev  $R/dev    2>/dev/null
/system/bin/busybox mount -t devpts devpts $R/dev/pts 2>/dev/null

# 起下载 + 网盘 + 面板
/system/bin/busybox chroot $R /usr/bin/env -i \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/root LANG=C.UTF-8 \
  /bin/bash /root/nasstart.sh >>/data/nasstart.log 2>&1

# 延时把「下载机 · NAS」桌面拉到前台
/system/bin/busybox setsid sh -c '/system/bin/busybox sleep 20; am start -n com.openhardwarelab.desktop/.MainActivity' >/dev/null 2>&1 &

# ADB over TCP 保活（开机早期可能失败，重试几次）——远程救急
setprop service.adb.tcp.port 5555
for j in 1 2 3 4 5 6 7 8; do
  ps | /system/bin/busybox grep -q '[s]bin/adbd' && break
  /system/bin/start adbd 2>/dev/null
  /system/bin/busybox sleep 4
done
ps | /system/bin/busybox grep -q '[s]bin/adbd' || /sbin/adbd 2>/dev/null &
