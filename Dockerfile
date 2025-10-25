ARG GO_BUILDER=docker.io/library/golang:1.24
ARG BASE_IMAGE=docker.io/library/alpine:3.12
ARG UI_BUILDER=docker.io/library/node:22-alpine3.21

FROM ${UI_BUILDER} AS builder_ui

WORKDIR /workspace
COPY ui ui
RUN cd ui && npm install && npm run build-only

FROM ${GO_BUILDER} AS builder

ARG VERSION
ARG GOPROXY
WORKDIR /workspace
COPY --from=builder_ui /workspace/ui/dist /workspace/ui/dist
COPY . .

RUN GOPROXY=${GOPROXY} go mod download
RUN GOPROXY=${GOPROXY} CGO_ENABLED=0 go build -ldflags "-w -s -X github.com/linuxsuren/api-testing/pkg/version.version=${VERSION}\
    -X github.com/linuxsuren/api-testing/pkg/version.date=$(date +%Y-%m-%d)" -o atest-store-math .

FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.source=https://github.com/linuxsuren/atest-ext-store-math
LABEL org.opencontainers.image.description="Store Extension of the API Testing."

COPY --from=builder /workspace/atest-store-math /usr/local/bin/atest-store-math

CMD [ "atest-store-math" ]
