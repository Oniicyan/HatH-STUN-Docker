# 下载 NATMap，识别对应的指令集架构
ARCH=$(cat etc/apk/arch)
case $ARCH in
  x86) DL=i586;;
  x86_64) DL=x86_64;;
  armhf) DL=arm32hf;;
  armv7) DL=arm32v7;;
  aarch64) DL=arm64;;
  ppc64le) DL=powerpc64;;
  riscv64) DL=riscv64;;
  s390x) DL=s390x;;
esac
wget https://github.com/heiher/natmap/releases/latest/download/natmap-linux-$DL -O /files/natmap

DEPS=java.base

# ppc64le 可安装 openjdk11，但目前版本 qemu 下执行 jlink 报错
# 问题解决前，在发行镜像上安装 openjdk8-jre-base
[[ $ARCH =~ 'x86_64|aarch64|ppc64le|s390x' ]] && \
apk add openjdk11 && \
jlink --no-header-files --no-man-pages --compress=2 --strip-debug --add-modules $DEPS --output /files/jre

# riscv64 不支持 openjdk21 以前的版本
[[ $ARCH =~ 'riscv64' ]] && \
apk add openjdk21 binutils && \
jlink --no-header-files --no-man-pages --compress=zip-9 --strip-debug --add-modules $DEPS --output /files/jre

exit 0
