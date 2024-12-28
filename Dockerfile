FROM alpine AS builder

RUN mkdir -p /files \
    && wget https://github.com/heiher/natmap/releases/latest/download/natmap-linux-$(arch) -O /files/natmap \
    && wget https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4.zip -O hath.zip \
    && apk --no-cache add unzip \
    && unzip hath.zip HentaiAtHome.jar -d /files

FROM eclipse-temurin:8-jre-noble AS release

COPY --from=builder /files /files
COPY /files /files

RUN apt-get update \
    && apt-get install -y netcat-openbsd xxd \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /files/*

CMD ["/files/start.sh"]
