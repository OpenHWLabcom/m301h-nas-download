#!/bin/bash
# 构建 下载机+NAS「桌面」APK (com.openhardwarelab.desktop, 开机直进管理面板 :8080)
set -e
cd "$(dirname "$0")"
SRC=$(cd "$(dirname "$0")"; pwd)
export JAVA_HOME=$PWD/jdk8u504-b01
export PATH=$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$PWD/aapt81/usr/lib/aarch64-linux-gnu:$PWD/aapt81/usr/lib/aarch64-linux-gnu/android
AAPT=$PWD/aapt81/usr/bin/aapt
AJ=$PWD/plat/android-4.4.2/android.jar

rm -rf mclasses mout monitor.unsigned.apk monitor.apk
mkdir -p mclasses mout

echo "[1/4] javac"
javac -source 7 -target 7 -bootclasspath "$AJ" -d mclasses "$SRC/MainActivity.java"

echo "[2/4] d8"
java -cp bt/android-11/lib/d8.jar com.android.tools.r8.D8 --min-api 19 --lib "$AJ" \
     --output mout mclasses/com/openhardwarelab/desktop/*.class

echo "[3/4] aapt"
$AAPT package -f -M AndroidManifest.xml -I "$AJ" -F monitor.unsigned.apk
( cd mout && $AAPT add ../monitor.unsigned.apk classes.dex )

echo "[4/4] sign"
[ -f openhwlab.keystore ] || keytool -genkeypair -keystore openhwlab.keystore -alias k -keyalg RSA \
  -keysize 2048 -validity 10000 -storepass android -keypass android \
  -dname "CN=OpenHW Lab, OU=dev, O=OpenHW Lab, L=Singapore, S=Singapore, C=SG"
jarsigner -keystore openhwlab.keystore -storepass android -keypass android monitor.unsigned.apk k
cp -f monitor.unsigned.apk monitor.apk
echo "=== OK ==="; ls -l monitor.apk
