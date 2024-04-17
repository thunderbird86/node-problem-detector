FROM --platform=linux/arm64 alpine:3.19.1

LABEL maintainer="Vasilchenko Anton <anton.vasilchenko@workato.com>"

RUN apk add --no-cache util-linux bash elogind-dev

# Avoid symlink of /etc/localtime.
RUN test -h /etc/localtime && rm -f /etc/localtime && cp /usr/share/zoneinfo/UTC /etc/localtime || true

COPY bin/ /usr/local/bin/

ENTRYPOINT ["node-problem-detector", "--config.system-log-monitor=/config/kernel-monitor.json"]