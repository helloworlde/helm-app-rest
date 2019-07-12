FROM golang AS build-env
WORKDIR /go/src/github.com/hellowrolde/Rest
COPY . .

ENV GO111MODULE on
ENV GOPROXY=https://gocenter.io
ENV GOOS linux
ENV GOARCH 386

RUN go mod download
RUN go build -v -o /go/src/github.com/hellowrolde/Rest/rest

FROM alpine
COPY --from=build-env  /go/src/github.com/hellowrolde/Rest/rest /usr/local/bin/rest
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
EXPOSE 8080
CMD ["rest"]