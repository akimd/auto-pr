FROM golang:1.8.1-alpine as hub_builder

RUN apk add --no-cache git
RUN go get github.com/github/hub
RUN go get github.com/dgageot/getme
RUN go get -u github.com/golang/dep/cmd/dep

FROM alpine:3.5

RUN apk add --no-cache \
  curl \
  git \
  jq \
  tar \ 
  go \ 
  perl \ 
  openssh \
  alpine-sdk 

ENV GITHUB_TOKEN ""
ENV GITHUB_REPO ""
ENV BUILD_JSON "build.json"
ENV USER_NAME ""
ENV USER_EMAIL ""
ENV BASE "master"
ENV DESCRIPTOR_URL ""

COPY --from=hub_builder /go/bin/hub /usr/bin
COPY --from=hub_builder /go/bin/getme /usr/bin
COPY --from=hub_builder /go/bin/dep /usr/bin

RUN mkdir /root/.ssh
COPY ./ssh-key /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

COPY run.sh .
CMD ["./run.sh"]
