LABEL org.opencontainers.image.source="https://github.com/Oniicyan/HatH-STUN-Docker"
LABEL org.opencontainers.image.description="Dockerfile of Hentai@Home with STUN available"

FROM alpine AS builder

RUN mkdir -p /files \
    && case $(arch) in x86_64) ARCH=x86_64;; armv7l) ARCH=arm32;; aarch64) ARCH=arm64;; ppc64le) ARCH=powerpc64;; esac \
    && wget https://github.com/heiher/natmap/releases/latest/download/natmap-linux-$ARCH -O /files/natmap \
    && wget https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4.zip -O hath.zip \
    && apk --no-cache add unzip \
    && unzip hath.zip HentaiAtHome.jar -d /files

FROM eclipse-temurin:8-jre-noble AS release

COPY --from=builder /files /files
COPY /files /files

RUN chmod +x /files/* \
    && apt-get update \
    && apt-get install -y miniupnpc \
    && rm -rf /var/lib/apt/lists/*

CMD ["start.sh"]
