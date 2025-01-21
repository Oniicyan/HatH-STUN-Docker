FROM alpine AS builder

RUN mkdir -p /files \
    && case $(arch) in x86_64) ARCH=x86_64;; armv7l) ARCH=arm32;; aarch64) ARCH=arm64;; ppc64le) ARCH=powerpc64;; esac \
    && wget https://github.com/heiher/natmap/releases/latest/download/natmap-linux-$ARCH -O /files/natmap \
    && wget https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4.zip -O hath.zip \
    && apk add unzip openjdk11\
    && unzip hath.zip HentaiAtHome.jar -d /files \
    && DEPS=$(jdeps HentaiAtHome.jar | awk '{print$NF}' | uniq) \
    && jlink --no-header-files --no-man-pages --compress=2 --strip-debug --add-modules $(echo $DEPS | tr ' ' ,) --output /files/jre-min

FROM alpine AS release

COPY --from=builder /files /files
COPY /files /files
ENV PATH="$PATH:/files"
ENV BUILD=176

RUN chmod +x /files/* \
    && apk add curl miniupnpc \
    && rm -rf /var/cache/apk

CMD ["start.sh"]

LABEL org.opencontainers.image.source="https://github.com/Oniicyan/HatH-STUN-Docker"
LABEL org.opencontainers.image.description="Docker of Hentai@Home (H@H, HatH) client with STUN (NAT Traversal) support"
