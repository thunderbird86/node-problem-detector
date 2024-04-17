# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "builder-base" can be overriden using dockerb buildx's --build-context flag,
# by users who want to use a different images for the builder. E.g. if you need to use an older OS 
# to avoid dependencies on very recent glibc versions.
# E.g. of the param: --build-context builder-base=docker-image://golang:<something>@sha256:<something>
# Must override builder-base, not builder, since the latter is referred to later in the file and so must not be
# directly replaced. See here, and note that "stage" parameter mentioned there has been renamed to 
# "build-context": https://github.com/docker/buildx/pull/904#issuecomment-1005871838

FROM --platform=linux/amd64 golang:1.22.2-bookworm as builder

ENV GOPATH /gopath/
ENV PATH $GOPATH/bin:$PATH

RUN apt-get update --fix-missing && apt-get --yes install libsystemd-dev gcc-aarch64-linux-gnu
RUN go version

COPY . /app
WORKDIR /app

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
    		-o bin/node-problem-detector \
    		-ldflags '-X $(PKG)/pkg/version.version=v0.8.18' \
    		-tags "journald" \
    		./cmd/nodeproblemdetector

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
    		-o bin/health-checker \
    		-ldflags '-X $(PKG)/pkg/version.version=v0.8.18' \
    		-tags "journald" \
    		cmd/healthchecker/health_checker.go

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build \
    		-o bin/log-counter \
    		-ldflags '-X $(PKG)/pkg/version.version=v0.8.18' \
    		-tags "journald" \
    		cmd/logcounter/log_counter.go


FROM --platform=linux/amd64 alpine:3.19.1

LABEL maintainer="Vasilchenko Anton <anton.vasilchenko@workato.com>"

RUN apk add --no-cache util-linux bash elogind-dev

# Avoid symlink of /etc/localtime.
RUN test -h /etc/localtime && rm -f /etc/localtime && cp /usr/share/zoneinfo/UTC /etc/localtime || true

COPY --from=builder /app/bin/ /usr/local/bin/
COPY --from=builder /app/config/ /config

ENTRYPOINT ["node-problem-detector", "--config.system-log-monitor=/config/kernel-monitor.json"]
