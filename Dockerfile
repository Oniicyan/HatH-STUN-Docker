FROM alpine AS Builder

RUN sh Builder.sh

FROM alpine AS Release

COPY --from=Builder /files /files
COPY /files /files
ENV PATH="$PATH:/files"
ENV BUILD=176

RUN chmod +x /files/* \
    && apk add curl miniupnpc \
    && ([[ $(cat etc/apk/arch) =~ 'x86|armhf|armv7' ]] && apk add openjdk8-jre-base) \
    && rm -rf /var/cache/apk

CMD ["start.sh"]

LABEL org.opencontainers.image.source="https://github.com/Oniicyan/HatH-STUN-Docker"
LABEL org.opencontainers.image.description="Docker of Hentai@Home (H@H, HatH) client with STUN (NAT Traversal) support"
