FROM alpine AS builder

COPY builder.sh builder.sh

RUN mkdir -p /files \
    && wget https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4.zip -O hath.zip \
    && apk add unzip && unzip hath.zip HentaiAtHome.jar -d /files \
    && sh builder.sh

FROM alpine AS release

COPY --from=builder /files /files
COPY /files /files
ENV PATH="$PATH:/files:/files/jre/bin"
ENV BUILD=176

RUN chmod +x /files/* && \
    apk add --update curl miniupnpc && \
    sh -c "[[ $(cat etc/apk/arch) =~ '^(x86|armhf|armv7)$' ]] && apk add openjdk8-jre-base || return 0" && \
    rm -rf /var/cache/apk

CMD ["start.sh"]

LABEL org.opencontainers.image.source="https://github.com/Oniicyan/HatH-STUN-Docker"
LABEL org.opencontainers.image.description="Hentai@Home (H@H, HatH) client with STUN (NAT Traversal) support"
