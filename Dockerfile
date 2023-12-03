FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get -y install \
    samba \
    krb5-config \
    winbind \
    smbclient \
    iproute2 \
    openssl \
    supervisor \
    vim \
    xattr

RUN rm /etc/krb5.conf

COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install certificates in docker
COPY files/private /etc/ssl/private

RUN mkdir -p /opt/sambadocker
WORKDIR /opt/sambadocker

COPY files/samba-ad-run.sh /opt/sambadocker/
COPY files/samba-ad-setup.sh /opt/sambadocker/
COPY files/ad-init.sh /opt/sambadocker/

EXPOSE 80
# Hardcode config so supervisord
# complains less
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
