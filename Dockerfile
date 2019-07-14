FROM golang AS build-env
WORKDIR /go/src/github.com/hellowrolde/rest
COPY . .

ENV GO111MODULE on
ENV GOPROXY=https://gocenter.io
ENV GOOS linux
ENV GOARCH 386

RUN go mod download
RUN go build -v -o /go/src/github.com/hellowrolde/rest/app

FROM alpine
COPY --from=build-env  /go/src/github.com/hellowrolde/rest/app /usr/local/bin/app
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
EXPOSE 8080
CMD ["app"]