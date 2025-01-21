FROM alpine AS builder

RUN mkdir -p /files \
    && ARCH=$(cat etc/apk/arch) \
    && case $ARCH in x86)DL=i586;; x86_64)DL=x86_64;; armhf)DL=arm32hf;; armv7)DL=arm32v7;; aarch64)DL=arm64;; ppc64le)DL=powerpc64;; riscv64)DL=riscv64;; s390x)DL=s390x;; esac \
    && wget https://github.com/heiher/natmap/releases/latest/download/natmap-linux-$DL -O /files/natmap \
    && wget https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4.zip -O hath.zip \
    && apk add unzip \
    && unzip hath.zip HentaiAtHome.jar -d /files \
    &&([[ $ARCH =~ 'x86_64|aarch64|ppc64le|s390x' ]] \
    && apk add openjdk11 \
    && DEPS=$(jdeps /files/HentaiAtHome.jar | awk '{print$NF}' | uniq) \
    && jlink --no-header-files --no-man-pages --compress=2 --strip-debug --add-modules $(echo $DEPS | tr ' ' ,) --output /files/jre) \
    &&([[ $ARCH =~ 'riscv64' ]] \
    && apk add openjdk21 binutils \
    && DEPS=$(jdeps /files/HentaiAtHome.jar | awk '{print$NF}' | uniq) \
    && jlink --no-header-files --no-man-pages --compress=zip-9 --strip-debug --add-modules $(echo $DEPS | tr ' ' ,) --output /files/jre)

FROM alpine AS release

COPY --from=builder /files /files
COPY /files /files
ENV PATH="$PATH:/files"
ENV BUILD=176

RUN chmod +x /files/* \
    && apk add curl miniupnpc \
    &&([[ $(cat etc/apk/arch) =~ 'x86|armhf|armv7' ]] && apk add openjdk8-jre-base) \
    && rm -rf /var/cache/apk

CMD ["start.sh"]

LABEL org.opencontainers.image.source="https://github.com/Oniicyan/HatH-STUN-Docker"
LABEL org.opencontainers.image.description="Docker of Hentai@Home (H@H, HatH) client with STUN (NAT Traversal) support"
