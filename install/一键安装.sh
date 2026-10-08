#!/bin/bash
# ============================================================
#  OpenHW Lab · 魔百和 M301H 改「下载机 + NAS」—— 一键安装（在电脑上跑）
#  适用机型：魔百和 M301H（创维 CW / 型号 M301H_CW0_AH / 海思 Hi3798MV300）
#  用法：  ./一键安装.sh <盒子IP>
#  前提：  盒子已 root、已开 ADB（串口里: setprop service.adb.tcp.port 5555; start adbd）；
#          已按教程搭好 Linux 子系统 /data/linux（Ubuntu 20.04 armhf）；
#          电脑装了 adb，与盒子同一局域网。
#  作用：  推下载/网盘/面板/存储切换 脚本进子系统、装面板桌面、装开机自启(M301H 专属钩子)。
#          可重复执行（幂等）。
# ============================================================
set -e
IP="$1"
[ -z "$IP" ] && { echo "用法: $0 <盒子IP>"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
R=/data/linux
say(){ echo -e "\n\033[1;36m==> $*\033[0m"; }

say "连接盒子 $IP:5555"
adb connect "${IP}:5555"; adb wait-for-device

say "检查 Linux 子系统 $R"
adb shell "[ -d $R/root ] || { echo '未找到 $R（先按教程搭好子系统）'; exit 1; }"

say "推 服务脚本/配置 到子系统 /root"
adb push "$HERE/下载服务.py"   $R/root/nasd.py
adb push "$HERE/aria2.conf"   $R/root/aria2.conf
adb push "$HERE/smb.conf"     $R/root/smb.conf
adb push "$HERE/diskwatch.sh" $R/root/diskwatch.sh
adb push "$HERE/3-开机自启.sh" $R/root/nasstart.sh
adb shell "chmod 755 $R/root/nasstart.sh $R/root/diskwatch.sh"

say "装面板桌面 App（全屏 WebView 载 127.0.0.1:8080）"
adb push "$HERE/桌面.apk" /data/local/tmp/nas.apk
adb shell 'pm install -r /data/local/tmp/nas.apk'
adb shell 'am start -n com.openhardwarelab.desktop/.MainActivity' || true

say "装盒子开机脚本 /data/nasstart.sh + M301H 专属启动钩子(放 init.bigfish.sh 头部)"
adb push "$HERE/4-开机兜底.sh" /data/nasstart.sh
adb shell 'chmod 755 /data/nasstart.sh'
adb shell 'mount -o remount,rw /system 2>/dev/null || true'
adb shell '[ -f /system/etc/init.bigfish.sh.bak-orig ] || /system/bin/busybox cp /system/etc/init.bigfish.sh /system/etc/init.bigfish.sh.bak-orig'
adb push "$HERE/开机钩子.txt" /data/local/tmp/nas_hook.txt
adb shell '{ /system/bin/busybox head -2 /system/etc/init.bigfish.sh; /system/bin/cat /data/local/tmp/nas_hook.txt; /system/bin/busybox tail -n +3 /system/etc/init.bigfish.sh; } > /data/ib.new'
adb shell 'cat /data/ib.new > /system/etc/init.bigfish.sh && chmod 755 /system/etc/init.bigfish.sh'

say "立即起服务（无需重启）"
adb push "$HERE/cr.sh" /data/local/tmp/cr.sh
adb shell 'sh /data/local/tmp/cr.sh "bash /root/nasstart.sh"'

cat <<'TIP'

  完成。浏览器打开：  http://<盒子IP>:8080/   （加任务 / 看速度 / 看磁盘 / 二维码）
  电脑映射网络盘：    \\<盒子IP>\nas
  ⭐ 存储自动切换：插上硬盘/U盘约 10 秒后下载自动切到盘；拔掉自动回内部存储。
  重启后自检：/data/nasstart.log 里有 nasstart done: aria2=1 smbd=1 nmbd=1 nasd=1

  —— OpenHW Lab · 智能硬件开放实验室 · hi@openhwlab.com
TIP
