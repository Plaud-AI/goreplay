# Dockerfile - 用于从源码构建 GoReplay，包含 libpcap 依赖

# 使用方法: docker build -t goreplay:latest .

FROM ubuntu:20.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    flex \
    bison \
    wget \
    curl \
    tar \
    ca-certificates \
    git \
    libpcap-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 Go (获取最新稳定版本，如果环境中已有 Go 则跳过)
RUN if ! command -v go >/dev/null 2>&1; then \
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1) && \
        wget https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
        tar -C /usr/local -xzf /tmp/go.tar.gz && \
        rm /tmp/go.tar.gz && \
        echo "Go installed: ${GO_VERSION}"; \
    else \
        echo "Go already installed: $(go version)"; \
    fi

ENV PATH=$PATH:/usr/local/go/bin
ENV CGO_ENABLED=1

# 复制源代码
WORKDIR /build
COPY . .

# 编译 GoReplay（静态链接）
RUN go build -ldflags "-extldflags \"-static\"" -o gor ./cmd/gor/

# 验证编译结果
RUN file gor && \
    ldd gor 2>&1 | grep -q "not a dynamic executable" && echo "静态链接成功" || echo "警告：不是静态链接"

# 最终镜像
FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 复制编译好的二进制文件
COPY --from=builder /build/gor /gor

ENTRYPOINT ["/gor"]
