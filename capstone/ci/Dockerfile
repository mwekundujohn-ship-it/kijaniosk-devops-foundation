FROM docker:27-cli

RUN apk add --no-cache bash curl git nodejs npm python3 openssh-client

RUN curl -fsSL https://dl.k8s.io/release/v1.37.2/bin/linux/amd64/kubectl \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl
