# SambADocker

A simple samba-ad in ubuntu 22.04 docker for testing other tools LDAP support.

## Table of Contents
* [Usage](#usage)
* [Defaults](ad-content)
* [ldapsearch examples](#ldapsearch-examples)

## Usage <a name="usage"/>
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

## Certificates / PKI
If you just need a development/test-PKI, `make-ca-and-certs` can generate a self-signed CA and service certificates for you.
If you want to trust this CA on other host copy install the CA certificate in `files/private/ca/ca.crt`.
On Debian-based linux you would i.e. copy the ca-file to `/usr/local/share/ca-certificates/ldap-test-ca.crt` and then run `update-ca-certificates`.

## Defaults

Default AD users, groups and OUs

The base OU, realm and domain is determined by the values in `.env` as used by `samba-tool domain provision`

The default values will result in a base OU of `DC=corporation,DC=example`, a realm of `corporation.example` and a `administrator` user (`CN=Administrator,CN=Users,DC=corporation,DC=example`) with the passord `dette_ER_et%LANGTordSOMkanskjeERnok`

The script [ad-init.sh](ad-init.sh) will set up a number of OUs, users and groups for testing. The script currently have test data for English, Japanese, Chinese, Hindi, Arabic and Norwegian.

Some users (adminsanta, 浦島太郎) have no email, this is on purpose.

### OUs
* `OU=North Pole Administrators,DC=corporation,DC=example`
* `OU=Service Users,DC=corporation,DC=example`
* `OU=Access Groups,DC=corporation,DC=example`
* `OU=More Users,DC=corporation,DC=example`
* `OU=昔話,OU=More Users,DC=corporation,DC=example` ("fairy tale", JP)
* `OU=童话,OU=More Users,DC=corporation,DC=example` ("fairy tale", CH)
* `OU=MISP,OU=Access Groups,DC=corporation,DC=example`
* `OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example`


### Users

#### santa
* DN: `CN=Santa Claus,CN=Users,DC=corporation,DC=example`
* Password: `Niew9wie2eezah`
* Email: `santa@northpole.corporation.example`

#### adminsanta
* DN: `CN=Santa Claus,OU=North Pole Administrators,DC=corporation,DC=example`
* Password: `theiKahlee1pho`
* Email: No email

#### bunny
* DN: `CN=Easter Island Bunny,CN=Users,DC=corporation,DC=example`
* Password: `Meish8somaeshe`
* Email: `bunny@northpole.corporation.example`

#### fairy
* DN: `CN=Tooth Fairy,CN=Users,DC=corporation,DC=example`
* Password: `Ohsae7iuf9eoth`
* Email: `fairy@tooth-castle.corporation.example`

#### 浦島太郎 (Urashima Tarō)
* DN: `CN=太郎 浦島,OU=昔話,OU=More Users,DC=corporation,DC=example`
* Password: `phee0udai3Ae`
* Email: No email

#### 葉限 (Ye Xian)
* DN: `CN=限 葉,OU=童话,OU=More Users,DC=corporation,DC=example`
* Password: `EiDochou8ohf`
* Email: `葉限@xn--iuzn16a.corporation.example`

#### `srv_misp`
* DN: `CN=srv_misp,OU=Service Users,DC=corporation,DC=example`
* Password: `eew5Shiegheevua5iz9rohvi`
* Email: No email

### MISP Access and Organization groups
* `CN=R_MISP Access,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_North_Pole`, `O_TTC`, `O_グループ１`, `O_第一组`
  * Space in name on purpose
* `CN=R_MISP_Readonly,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_TTC`
* `CN=R_MISP User,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_North_Pole`, `O_グループ１`, `O_第一组`
  * Space in name on purpose
* `CN=R_MISP_Admin,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `adminsanta`
* `CN=R_MISP_Publisher,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
* `CN=R_MISP_Org_Admin,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
* `CN=R_MISP_Org_TTC,OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_TTC`
* `CN=R_MISP_Org_North_Pole,OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_North_Pole`
* `CN=R_MISP_Org_昔話,OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_グループ１`
* `CN=R_MISP_Org_童话,OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example`
  * Members: `O_第一组`

### Organization groups
* `CN=O_North_Pole,CN=Users,DC=corporation,DC=example`
  * Members: `santa`, `adminsanta`, `bunny` 
* `CN=O_TTC,CN=Users,DC=corporation,DC=example`
  * Members: `fairy`
* `CN=O_グループ１,CN=Users,DC=corporation,DC=example` (Group 1, JP)
  * `浦島太郎` (Urashima Tarō)
* `CN=O_第一组,CN=Users,DC=corporation,DC=example`  (Group 1, JP)
  * `葉限` (Ye Xian)

## ldapsearch examples <a name="ldapsearch-examples"/>
### Base command
`ldapsearch -ZZ -H 'ldap://ad.corporation.example' -LLL -D 'CN=Administrator,CN=Users,DC=corporation,DC=example' -w "$SMB_ADMIN_PASSWORD" -b 'DC=corporation,DC=example' '<search>' dn`

* `-ZZ`: Require StartTLS
* Replace `-w  "$SMB_ADMIN_PASSWORD"` with `-W` if you want to be asked for the passord and not have it on the command line.
* ldapsearch is bad at giving error messages. Add `-d 9` to the command for maximum debug output that will give much more info.
* If you have used `make-ca-and-certs` to make your PKI, you can use prefix `ldapsearch` command with `LDAPTLS_CACERT=./files/private/ca/ca.crt `
* If you have a invalid TLS setup, you can prefix the `ldapsearch` command with `LDAPTLS_REQCERT=allow `

### Example searches
* List single user
  * `(samaccountname=santa)`
  * `(distinguishedname=CN=Santa Claus,CN=Users,DC=corporation,DC=example)`
  * `(userprincipalname=santa@corporation.example)` (may look like, but not necessarily the same as the `mail` field)
  * `(mail=santa@northpole.corporation.example)`
* List _direct_ members of a group (__probably not what you want__)
  * `(memberOf=CN=R_MISP_Org_North_Pole,OU=Organizations,OU=MISP,OU=Access Groups,DC=corporation,DC=example)`
* List direct __and__ nested members of a group (__probably not what you want__)
  * `(memberOf:1.2.840.113556.1.4.1941:=CN=R_MISP Access,OU=MISP,OU=Access Groups,DC=corporation,DC=example)`
* List direct and nested _user_ members of a group (probably what you want)
  * `(&(objectCategory=user)(memberOf:1.2.840.113556.1.4.1941:=CN=R_MISP Access,OU=MISP,OU=Access Groups,DC=corporation,DC=example))`
