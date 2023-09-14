FROM python:3.11-alpine

ARG GO_DNSCOLLECTOR_VERSION
ARG PDNSSOC_CLI_VERSION

RUN apk add --no-cache --update \
    bash  \
    py3-pip \
    curl \
    tar \
    supervisor \
    coreutils \
    jq \
    gzip

# Install pdnssoc-cli
#RUN pip install "pdnssoc-cli==$PDNSSOC_CLI_VERSION"

RUN pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple pdnssoc-cli==$PDNSSOC_CLI_VERSION

RUN mkdir /build

WORKDIR /build


# Install go-dnscollector
RUN echo "https://github.com/dmachard/go-dnscollector/releases/download/${GO_DNSCOLLECTOR_VERSION}/go-dnscollector_${GO_DNSCOLLECTOR_VERSION}_linux_amd64.tar.gz"
RUN curl -LO  "https://github.com/dmachard/go-dnscollector/releases/download/v${GO_DNSCOLLECTOR_VERSION}/go-dnscollector_${GO_DNSCOLLECTOR_VERSION}_linux_amd64.tar.gz" && \
        tar xvf "go-dnscollector_${GO_DNSCOLLECTOR_VERSION}_linux_amd64.tar.gz" && \
        mv go-dnscollector /usr/bin/

RUN mkdir /etc/dnscollector

RUN pip install superfsmon

# Setup supervisord
RUN mkdir -p /var/log/supervisor

# Bake scripts for pdnssoc
COPY postrotate_query.sh /etc/dnscollector/postrotate_query.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY godnscollector.yml /etc/dnscollector/config.yml

CMD ["supervisord"]