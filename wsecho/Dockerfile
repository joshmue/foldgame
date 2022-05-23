FROM golang:1.18-bullseye

WORKDIR /opt
COPY wsecho.patch .

RUN apt-get update && apt-get install -y patch && \
    git clone https://github.com/gorilla/websocket.git -b v1.5.0 && \
    patch -n websocket/examples/chat/client.go < wsecho.patch && \
    cd websocket && \
    go install -v ./examples/chat

FROM debian:bullseye

COPY --from=0 /go/bin/chat /usr/local/bin/wsecho
CMD ["/usr/local/bin/wsecho"]
