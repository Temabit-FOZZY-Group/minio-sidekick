# syntax=docker/dockerfile:1.6

ARG GOLANG_VERSION="1.21"
ARG BUILD_IMAGE="golang:${GOLANG_VERSION}-alpine"
ARG GOLANGCI_LINT_IMAGE="golangci/golangci-lint:latest"
ARG BASE_IMAGE="scratch"

# =============================================================================
FROM ${BUILD_IMAGE} as base

SHELL ["/bin/sh", "-e", "-u", "-o", "pipefail", "-o", "errexit", "-o", "nounset", "-c"]

WORKDIR /src/sidekick

ARG GO111MODULE="on"
ARG CGO_ENABLED="0"
ARG GOARCH="amd64"
ARG GOOS="linux"
ENV GO111MODULE="${GO111MODULE}" \
    CGO_ENABLED="${CGO_ENABLED}"  \
    GOARCH="${GOARCH}" \
    GOOS="${GOOS}"

COPY ./go.* ./

RUN <<'EOD'
if [ -f "go.mod" ]; then
    if [ ! -f "go.sum" ]; then
        go mod tidy
    fi
    go mod download
fi
EOD

# =============================================================================
FROM ${GOLANGCI_LINT_IMAGE} AS lint-base

# =============================================================================
FROM base AS lint

RUN --mount=type=bind,source=./,target=./ \
    --mount=from=lint-base,src=/usr/bin/golangci-lint,target=/usr/bin/golangci-lint \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/golangci-lint \
    \
    golangci-lint run \
        --color never \
        --timeout 10m0s ./... | tee /linter_result.txt

# =============================================================================
FROM base AS test

RUN --mount=type=bind,source=./,target=./ \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -v -coverprofile=/cover.out ./...

# =============================================================================
FROM base as build

ARG APP_VERSION="docker"

RUN --mount=type=bind,source=./,target=./ \
    --mount=from=lint-base,src=/usr/bin/golangci-lint,target=/usr/bin/golangci-lint \
    --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    \
    go build \
        -tags musl \
        -ldflags '-w -s -X main.version=${APP_VERSION}' -a \
        -o /sidekick

# wait until other stages are done
# COPY --from=lint /linter_result.txt /linter_result.txt
COPY --from=test /cover.out /cover.out

# =============================================================================
FROM ${BASE_IMAGE} as release
COPY --link --from=build /sidekick /sidekick
ENTRYPOINT [ "/sidekick" ]
