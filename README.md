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


## Defaults

Default AD users, groups and OUs

The base OU, realm and domain is determined by the values in `.env` as used by `samba-tool domain provision`

The default values will result in a base OU of `DC=example,DC=com`, a realm of `example.com` and a `administrator` user (`CN=Administrator,CN=Users,DC=example,DC=com`) with the passord `dette_ER_et%LANGTordSOMkanskjeERnok`

The script [ad-init.sh](ad-init.sh) will set up the following OUs, users and groups.

Some users (adminsanta, 浦島太郎) have no email, this is on purpose.

### OUs
* `OU=North Pole Administrators,DC=example,DC=com`
* `OU=Service Users,DC=example,DC=com`
* `OU=Access Groups,DC=example,DC=com`
* `OU=More Users,DC=example,DC=com`
* `OU=昔話,OU=More Users,DC=example,DC=com` ("fairy tale", JP)
* `OU=童话,OU=More Users,DC=example,DC=com` ("fairy tale", CH)
* `OU=MISP,OU=Access Groups,DC=example,DC=com`
* `OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com`


### Users

#### santa
* DN: `CN=Santa Claus,CN=Users,DC=example,DC=com`
* Password: `Niew9wie2eezah`
* Email: `santa@northpole.example.com`

#### adminsanta
* DN: `CN=Santa Claus,OU=North Pole Administrators,DC=example,DC=com`
* Password: `theiKahlee1pho`
* Email: No email

#### bunny
* DN: `CN=Easter Island Bunny,CN=Users,DC=example,DC=com`
* Password: `Meish8somaeshe`
* Email: `bunny@northpole.example.com`

#### fairy
* DN: `CN=Tooth Fairy,CN=Users,DC=example,DC=com`
* Password: `Ohsae7iuf9eoth`
* Email: `fairy@tooth-castle.example.com`

#### 浦島太郎 (Urashima Tarō)
* DN: `CN=太郎 浦島,OU=昔話,OU=More Users,DC=example,DC=com`
* Password: `phee0udai3Ae`
* Email: No email

#### 葉限 (Ye Xian)
* DN: `CN=限 葉,OU=童话,OU=More Users,DC=example,DC=com`
* Password: `EiDochou8ohf`
* Email: `葉限@xn--iuzn16a.example.com`

#### `srv_misp`
* DN: `CN=srv_misp,OU=Service Users,DC=example,DC=com`
* Password: `eew5Shiegheevua5iz9rohvi`
* Email: No email

### MISP Access and Organization groups
* `CN=R_MISP_Access,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_North_Pole`, `O_TTC`, `O_グループ１`, `O_第一组`
* `CN=R_MISP_Readonly,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_TTC` 
* `CN=R_MISP_User,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_North_Pole`, `O_グループ１`, `O_第一组`
* `CN=R_MISP_Admin,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `adminsanta`
* `CN=R_MISP_Publisher,OU=MISP,OU=Access Groups,DC=example,DC=com`
* `CN=R_MISP_Org_Admin,OU=MISP,OU=Access Groups,DC=example,DC=com`
* `CN=R_MISP_Org_TTC,OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_TTC` 
* `CN=R_MISP_Org_North_Pole,OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_North_Pole`
* `CN=R_MISP_Org_昔話,OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_グループ１`
* `CN=R_MISP_Org_童话,OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com`
  * Members: `O_第一组`

### Organization groups
* `CN=O_North_Pole,CN=Users,DC=example,DC=com`
  * Members: `santa`, `adminsanta`, `bunny` 
* `CN=O_TTC,CN=Users,DC=example,DC=com`
  * Members: `fairy`
* `CN=O_グループ１,CN=Users,DC=example,DC=com` (Group 1, JP)
  * `浦島太郎` (Urashima Tarō)
* `CN=O_第一组,CN=Users,DC=example,DC=com`  (Group 1, JP)
  * `葉限` (Ye Xian)

## ldapsearch examples <a name="ldapsearch-examples"/>
### Base command
`ldapsearch -ZZ -H 'ldap://ad.example.com' -LLL -D 'CN=Administrator,CN=Users,DC=example,DC=com' -w "$SMB_ADMIN_PASSWORD" -b 'DC=example,DC=com' '<search>' dn`

* `-ZZ`: Require StartTLS
* Replace `-w  "$SMB_ADMIN_PASSWORD"` with `-W` if you want to be asked for the passord and not have it on the command line. 
* ldapsearch is bad at giving error messages. Add `-d 9` to the command for maximum debug output that will give much more info.
* If you have a invalid TLS setup, you can prefix the `ldapsearch` command with `LDAPTLS_REQCERT=allow `

### Example searches
* List single user
  * `(samaccountname=santa)`
  * `(distinguishedname=CN=Santa Claus,CN=Users,DC=example,DC=com)`
  * `(userprincipalname=santa@example.com)` (may look like, but not necessarily the same as the `mail` field)
  * `(mail=santa@northpole.example.com)`
* List _direct_ members of a group (__probably not what you want__)
  * `(memberOf=CN=R_MISP_Org_North_Pole,OU=Organizations,OU=MISP,OU=Access Groups,DC=example,DC=com)`
* List direct __and__ nested members of a group (__probably not what you want__)
  * `(memberOf:1.2.840.113556.1.4.1941:=CN=R_MISP_Access,OU=MISP,OU=Access Groups,DC=example,DC=com)`
* List direct and nested _user_ members of a group (probably what you want)
  * `(&(objectCategory=user)(memberOf:1.2.840.113556.1.4.1941:=CN=R_MISP_Access,OU=MISP,OU=Access Groups,DC=example,DC=com))`
