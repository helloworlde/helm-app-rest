# Kubernetes 中使用 Helm 部署应用

## 创建应用

创建一个简单的应用，提供一个 REST 接口；使用 Golang 编写，然后将镜像 push 到 Docker Hub

- go.mod

```
module github.com/helloworlde/rest

go 1.12
```

- main.go 

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/ping", func(writer http.ResponseWriter, request *http.Request) {
		fmt.Println("Pong")
		_, _ = fmt.Fprint(writer, "Pong")
	})

	fmt.Println("Server Started")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

- Dockerfile 

```dockerfile
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
```

- 构建并 push 镜像

```bash
docker build -t hellowooeds/rest . 
docker push hellowooeds/rest
```

## 使用 Helm

### 添加 Helm

#### 初始化

```bash
helm create rest
```

然后会在项目目录下创建一个 rest 的文件夹，里面包含所需要的 Helm 配置文件

```
.
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

3 directories, 8 files
```

- Chart.yaml: 用于描述 Chart 的属性
- values.yaml: 存放项目的配置项，如镜像名称或者 tag 等，用于和模板组装
- charts: 用于存放依赖的 chart 的，当有依赖需要管理时，可以添加 requirements.yaml 文件，可用于管理项目内或者外部的依赖
- templates: 用于存放需要的配置模板


#### 修改配置文件

- Chart.yaml 

```yaml
apiVersion: v1
appVersion: "1.0"
description: Rest application with Helm
name: rest
version: 0.1.0
maintainers:
  - name: HelloWood
```

- 修改 values.yaml 

```yaml
backend:
  image: hellowoodes/rest
  tag: "latest"
  pullPolicy: IfNotPresent
  replicas: 1

namespace: rest

service:
  type: NodePort
```

- backend-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: backend
  name: backend
  namespace: {{ .Values.namespace }}
spec:
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  selector:
    app: backend
  type: {{ .Values.service.type }}
```

- backend-deployment.yaml

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: backend
  name: backend
  namespace: {{ .Values.namespace }}
spec:
  selector:
    matchLabels:
      app: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: {{ .Values.backend.image }}:{{ .Values.backend.tag }}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
```

### 安装应用

```bash
helm install ./rest --name rest
```

如果不指定名称，会随机生成一个

```                
NAME:   rest
LAST DEPLOYED: Sun Jul 14 18:50:16 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                      READY  STATUS             RESTARTS  AGE
backend-5bc9d6cb99-pfwn5  0/1    ContainerCreating  0         0s

==> v1/Service
NAME     TYPE      CLUSTER-IP     EXTERNAL-IP  PORT(S)         AGE
backend  NodePort  10.105.41.183  <none>       8080:31381/TCP  0s

==> v1beta1/Deployment
NAME     READY  UP-TO-DATE  AVAILABLE  AGE
backend  0/1    1           0          0s


NOTES:
1. Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get service -l app=backend --namespace default  -o jsonpath="{.items[0].spec.ports[0].nodePort}")
  export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
```

执行提示后获取到服务的节点地址和端口

#### 测试 

访问通过 NOTES 获取到的 IP 和端口

```bash
http get http://192.168.0.110:31381/ping
HTTP/1.1 200 OK
Content-Length: 4
Content-Type: text/plain; charset=utf-8
Date: Sun, 14 Jul 2019 10:53:18 GMT

Pong
```