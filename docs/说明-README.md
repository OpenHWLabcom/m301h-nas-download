# 说明 README —— 魔百和 M301H 变「下载机 + NAS」(开发者)

> 适用机型：**魔百和 M301H**（创维 CW / 型号 `M301H_CW0_AH` / 海思 Hi3798MV300）。

## 组成

```
[手机/电脑浏览器] --:8080-->  nasd.py  (管理面板: 加任务/进度/磁盘/二维码)
                                  |
                                  v
                           aria2  (下载引擎, RPC :6800)  -->  外接盘 / 内部存储
[电脑/手机]  --SMB:445-->   smbd   (家庭网盘 \\<盒子IP>\nas)
[电视]       --DLNA---->    minidlna (可选)
[盒子屏幕]   桌面.apk (全屏 WebView) --> http://127.0.0.1:8080/  (开机拉到前台)
                  ^
       diskwatch.sh 每 10s 巡检：有外接盘就 bind 到 /root/nas，否则内部
```

## 文件

| 文件 | 说明 |
|---|---|
| `下载服务.py` (nasd.py) | 管理面板 + 下载/磁盘状态 + 二维码 + 任务控制；显示「当前存储」 |
| `aria2.conf` | aria2 配置（dir=/root/nas/downloads / RPC 6800 / BT） |
| `smb.conf` | Samba 共享（path=/root/nas） |
| `diskwatch.sh` | ⭐ 存储自动切换（外接盘优先，vfat/exFAT/NTFS） |
| `3-开机自启.sh` (nasstart.sh) | 子系统启动：aria2/smbd/nmbd/nasd/minidlna + diskwatch 循环 |
| `4-开机兜底.sh` | 盒子侧启动（挂子系统 + chroot + 起 adbd + 拉面板） |
| `开机钩子.txt` | 加到 `/system/etc/init.bigfish.sh` **头部**的钩子 |
| `桌面.apk` | 全屏网页壳（com.openhardwarelab.desktop） |
| `src/` | 上述脚本 + 面板 App 源码(android-kiosk) + 构建脚本 |

## 接口（nasd.py）
- `GET /` 面板 · `GET /api/state` 状态 JSON（含 disk.target=当前存储）
- `POST /api/add`{url} · `POST /api/pause|resume|remove`{gid} · `GET /ariang/`

## 环境变量
`NASD_PORT`(8080) · `ARIA2_RPC`(http://127.0.0.1:6800/jsonrpc) · `ARIA2_SECRET`(openhwlab) ·
`NAS_ROOT`(/root/nas) · `NAS_DL`(/root/nas/downloads) · `ARIANG_DIR`(/root/ariang) · `BOX_IP`

## 存储
- 活动根 `/root/nas`；`diskwatch.sh` 有盘 `mount --bind <盘>/nas /root/nas`，无盘 `umount`。
- 状态 `/root/nas-active`（`USB:<路径>` / `internal`）。

—— OpenHW Lab
