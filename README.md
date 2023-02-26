# SambADocker

A simple samba-ad in ubuntu 22.04 docker for testing other tools LDAP support.

## Usage
* `cp example.env .env`
  * Edit .env to your liking
  * You probably want to point `$SMB_HOSTNAME` to `127.0.0.1` in `/etc/hosts`
* Generate and place certificates in `files/private`
  * Unless you want Samba to autogenerate self-signed sertificates
* `docker-compose build`
* `docker-compose up`
  * or `docker-compose up -d` to detach
* Run `./ad-init.sh` if you want a simple test dataset (designed around MISP testing)
* Run `docker-compose down` to stop samba
  * or `docker-compose down -v` to stop samda and delete data volumes
