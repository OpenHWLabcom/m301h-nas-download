# 魔百和 M301H 改「下载机 + NAS」· China Mobile M301H (Skyworth) → Downloader + NAS

> **适用机型（重要）：魔百和 M301H — 创维 CW 版，型号 `M301H_CW0_AH`，主控海思 HiSilicon Hi3798MV300。**
> For the **China Mobile M301H** box (**Skyworth CW** build, model **`M301H_CW0_AH`**, SoC **HiSilicon Hi3798MV300**).

把吃灰的 **魔百和 M301H** 盒子变成一台 **24h 低功耗下载机 + 家庭网盘**。
Turn an idle **M301H** box into a low-power **downloader + home NAS**.

> 与通用版 [tvbox-nas-download](https://github.com/OpenHWLabcom/tvbox-nas-download) 同一产品思路；
> 本仓库是**针对 M301H（海思 Hi3798MV300）实测**的型号版，含该机型**专属**的开机自启方式与坑。

---

## 🇨🇳 中文

### 实测机型（本机）
| 项 | 值 |
|---|---|
| 盒子 | **魔百和 M301H**（中国移动魔百盒） |
| 型号 | **`M301H_CW0_AH`**（创维 CW 版） |
| 主控 | **海思 HiSilicon Hi3798MV300**（4×Cortex-A7 / 32 位 armv7 / armeabi-v7a） |
| 系统 | Android **4.4.2**（SDK19） |
| 存储 | `/data` ≈3.8G；内置 eMMC |
| 串口 | console = **ttyAMA0, 115200 8N1**（TTL 可进 root shell） |
| 网络 | 有线 eth0 |

### 功能
- **挂机下载**：aria2（BT / 磁力 / HTTP / 直链），**7×24** 不占电脑
- **家庭网盘**：Samba 共享 `\\<盒子IP>\nas`，Win/Mac/手机通吃
- **网页管理面板**（`:8080`）：加任务、看速度、看磁盘、任务暂停/继续/删除、**手机扫码**进面板
- **DLNA 媒体库**（minidlna）：电视/手机直接播下载的影视
- **⭐ 存储自动切换**：**插上硬盘/U 盘 → 下载 & 网盘自动用它；没插 → 用内部存储**（热插拔生效，支持 vfat / exFAT / **NTFS**）
- **开机全自动**：断电重启后下载/网盘/面板全自动拉起

### 环境要求
- **魔百和 M301H（创维 CW / 海思 Hi3798MV300）已 root**，有 **TTL 串口** 或 **ADB**
- 盒子里的 **Linux 子系统**：chroot 一个 **Ubuntu 20.04（armhf）** 到 `/data/linux`
- （可选）一块 **USB 硬盘 / U 盘**（ext4 / NTFS / exFAT / FAT 都行）

### 安装
```bash
cd install
./一键安装.sh <盒子IP>
```
详细图文：**[`docs/安装教程.md`](docs/安装教程.md)**

### 用法
- **面板**：`http://<盒子IP>:8080/`（加任务 / 看进度 / 看磁盘 / 二维码）
- **网盘**：`\\<盒子IP>\nas`（或 `smb://<盒子IP>/nas`）
- **aria2 RPC**：`http://<盒子IP>:6800/jsonrpc`（token `openhwlab`）
- **盒子屏幕**：开机自动进入「下载机 · NAS」面板

---

## 🇬🇧 English

### Tested hardware
**China Mobile M301H** box — **Skyworth CW** build, model **`M301H_CW0_AH`**, SoC **HiSilicon Hi3798MV300**
(4×Cortex-A7, 32-bit armv7), Android **4.4.2** (SDK19), serial console **ttyAMA0 @115200**, wired eth0.

### Features
- **Always-on downloads**: aria2 (BT / magnet / HTTP / direct links), 24/7
- **Home NAS**: Samba share `\\<box-ip>\nas`
- **Web panel** (`:8080`): add tasks, speed, disk, pause/resume/delete, **phone QR**
- **DLNA** (minidlna): media library for TV/phone
- **⭐ Auto storage switching**: **plug in a USB drive → downloads & share use it; unplug → internal storage** (hot-plug; vfat / exFAT / **NTFS**)
- **Fully automatic on boot**

### Install
```bash
cd install
./一键安装.sh <box-ip>
```
Guide: **[`docs/安装教程.md`](docs/安装教程.md)**

---

## 与通用版的关键差异 · Key differences vs the generic version

| | 通用版 | **M301H 型号版（本仓库）** |
|---|---|---|
| 目标机型 | 任意（需自行适配） | **魔百和 M301H_CW0_AH / 创维 / 海思 Hi3798MV300** |
| 开机自启 | 模板 | **已适配该 ROM**：`/system/etc/init.bigfish.sh`（钩子须放**文件头部**，末尾是死循环脚本） |
| 默认桌面 | App 声明 HOME | ⚠️ 该 ROM **硬编码禁止第三方 HOME**（`ellison. block home apk`）→ 开机脚本把面板拉到前台 |
| 存储 | 手动指定 | **自动切换**（插盘优先，含 NTFS/exFAT 挂载） |

---

## License · 许可
[MIT](docs/LICENSE) · 仅供学习与个人使用 / For learning and personal use only.

---

## 🔗 相关链接 · Links

- 官网 **OpenHW Lab**：https://www.openhwlab.com/
- 本项目仓库：https://github.com/OpenHWLabcom/m301h-nas-download
- 同系列：
  - 通用下载机NAS — https://github.com/OpenHWLabcom/tvbox-nas-download
  - 魔百和 CM201-1 打印机服务器 — https://github.com/OpenHWLabcom/cm201-1-print-server
  - 魔百和 CM201-2 打印机服务器 — https://github.com/OpenHWLabcom/cm201-2-print-server
  - 机顶盒改游戏机 — https://github.com/OpenHWLabcom/tvbox-game-console

联系 · Contact：hi@openhwlab.com
