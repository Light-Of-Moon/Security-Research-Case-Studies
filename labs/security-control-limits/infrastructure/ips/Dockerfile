FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    suricata suricata-update iptables iproute2 dnsutils ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && suricata-update --no-test --no-reload
COPY start.sh /usr/local/bin/scl-ips-start
RUN chmod 0755 /usr/local/bin/scl-ips-start
ENTRYPOINT ["/usr/local/bin/scl-ips-start"]

