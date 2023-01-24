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
    vim

RUN rm /etc/krb5.conf

COPY files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /opt/sambadocker
WORKDIR /opt/sambadocker

COPY files/samba-ad-run.sh /opt/sambadocker/
COPY files/samba-ad-setup.sh /opt/sambadocker/
 
EXPOSE 80
CMD ["/usr/bin/supervisord"]
