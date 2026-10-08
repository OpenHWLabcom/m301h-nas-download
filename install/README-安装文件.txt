========================================
  安装文件 · 说明
  OpenHW Lab · 魔百和 M301H 改「下载机 + NAS」
  适用机型：M301H_CW0_AH（创维 CW / 海思 Hi3798MV300）
========================================

先读上级目录 安装教程（docs/安装教程.md，另有 .txt/.html），照着做即可。

本目录文件：

  一键安装.sh        ← 电脑上跑：./一键安装.sh <盒子IP>
                        （推服务 + 装面板桌面 + 装 M301H 专属开机钩子，一步到位，幂等）
  下载服务.py        ← 网页管理面板（nasd.py,:8080）：加任务/速度/磁盘/二维码 → /root/nasd.py
  aria2.conf         ← 下载引擎配置（dir、RPC 6800、BT）→ /root/aria2.conf
  smb.conf           ← 网盘共享配置（[nas] path=/root/nas）→ /root/smb.conf
  diskwatch.sh       ← ⭐ 存储自动切换：插盘用它、拔盘回内部（vfat/exFAT/NTFS）→ /root/diskwatch.sh
  3-开机自启.sh      ← 子系统启动脚本（aria2/smbd/nmbd/nasd/diskwatch）→ /data/linux/root/nasstart.sh
  4-开机兜底.sh      ← 盒子侧开机脚本（挂子系统→chroot→起 adbd→拉面板）→ /data/nasstart.sh
  开机钩子.txt       ← 追加到 /system/etc/init.bigfish.sh 【头部】的钩子（on boot 触发）
  cr.sh              ← 便捷脚本：在子系统 chroot 里跑命令 → /data/local/tmp/cr.sh
  桌面.apk           ← 「下载机·NAS」全屏网页壳（com.openhardwarelab.desktop）

端口一览：
  8080  网页面板    6800  aria2 RPC    445/139  Samba 网盘    8200  DLNA

怎么用：
  A) 省事：连好 adb，跑  ./一键安装.sh <盒子IP>
  B) 手动：按「安装教程」一步步复制文件、执行命令（可照抄）

依赖（子系统里装；本机 chroot 里 apt 可用）：
  aria2 samba samba-common-bin minidlna qrencode python3
  ntfs-3g exfat-fuse exfat-utils dosfstools ca-certificates

⭐ 存储策略：**插了硬盘/U盘 → 下载&网盘自动用它；没插 → 内部存储**（热插拔生效）。
   支持 vfat / exFAT / NTFS（vold 只自动挂 FAT，其余由 diskwatch 手动挂）。

⚠️ 该 ROM 硬编码禁止第三方 App 当默认 HOME（ellison. block home apk）→ 面板由开机脚本拉到前台。

—— OpenHW Lab · 智能硬件开放实验室 · hi@openhwlab.com
