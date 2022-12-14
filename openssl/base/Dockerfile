FROM alpine/openssl:latest

RUN mkdir /workspace

COPY ./conf/ca.conf /workspace/ca.conf
COPY ./conf/certificate.conf /workspace/certificate.conf
COPY ./conf/certificate-ext.conf /workspace/certificate-ext.conf

COPY --chmod=0755 ./scripts/generate-ca.sh /workspace/generate-ca.sh
COPY --chmod=0755 ./scripts/generate-cert.sh /workspace/generate-cert.sh
COPY --chmod=0755 ./scripts/generate-cert-p12.sh /workspace/generate-cert-p12.sh

VOLUME [ "/workspace" ]

WORKDIR /workspace


