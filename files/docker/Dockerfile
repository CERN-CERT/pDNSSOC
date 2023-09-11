FROM python:3.11-alpine

ARG GO_DNSCOLLECTOR_VERSION
ARG PDNSSOC_CLI_VERSION
ARG SUPERCRONIC_VERSION

ENV SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/supercronic-linux-amd64" \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=7a79496cf8ad899b99a719355d4db27422396735

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

# Install supercronic
RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

RUN pip install superfsmon

# Setup supervisord
RUN mkdir -p /var/log/supervisor

# Bake scripts for pdnssoc
COPY postrotate_query.sh /etc/dnscollector/postrotate_query.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY godnscollector.yml /etc/dnscollector/config.yml

CMD ["supervisord"]