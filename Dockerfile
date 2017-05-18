FROM golang:1.8.1-alpine as hub_builder

RUN apk add --no-cache git
RUN go get github.com/github/hub
RUN go get github.com/dgageot/getme

FROM alpine:3.5

RUN apk add --no-cache \
  curl \
  git \
  jq \
  tar

ENV GITHUB_TOKEN ""
ENV GITHUB_REPO ""
ENV BUILD_JSON "build.json"
ENV USER_NAME ""
ENV USER_EMAIL ""
ENV BASE "master"
ENV DESCRIPTOR_URL ""

COPY --from=hub_builder /go/bin/hub /usr/bin
COPY --from=hub_builder /go/bin/getme /usr/bin
COPY run.sh .
CMD ["./run.sh"]
