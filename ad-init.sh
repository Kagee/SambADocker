#! /bin/bash

# Set up OUs, users and groups in AD
# based on fairytale characters

source <(grep -v '^#' .env | sed 's/^/export /')

ST="docker exec -it sambad samba-tool"
BO="$SMB_OU"

{

  # OU for admins
  $ST ou add "OU=North Pole Administrators,${BO}"

  # OU for service users
  $ST ou add "OU=Service Users,${BO}"

  # Sort access groups in this OU
  $ST ou add "OU=Access Groups,${BO}"

  # We are not allowed create OUs under CN=Users by AD
  # Put some users in other OUs
  $ST ou add "OU=More Users,${BO}"
  $ST ou add "OU=昔話,OU=More Users,${BO}" --description "Fairy Tale (JP)"

  $ST ou add "OU=童话,OU=More Users,${BO}" --description "Fairy Tale (CH)"

  # Access groups for MISP
  $ST ou add "OU=MISP,OU=Access Groups,${BO}"
  $ST ou add "OU=Organizations,OU=MISP,OU=Access Groups,${BO}"

  # Santa, normal user and admin account
  $ST user add santa Niew9wie2eezah \
    --given-name "Santa" --surname "Claus" \
    --mail-address="santa@northpole.example.com" \
    --company="North Pole" --description="Wears a red hat"
  # Admin user has no mail, this is on purpose for a test case
  $ST user add adminsanta theiKahlee1pho \
    --given-name "AdminSanta" --surname "Claus" \
    --company="North Pole" --description="Wears two red hats" \
    --userou='OU=North Pole Administrators'

  # The easter bunny works for Santa most of the year
  $ST user add bunny Meish8somaeshe \
    --given-name "Easter Island" --surname "Bunny" \
    --mail-address="bunny@northpole.example.com" \
    --company="North Pole" \
    --description="Brown fur, obsession with eggs"

  # The tooth fairy has an AD account, but
  # works for The Tooth Castle (TTC)
  $ST user add fairy Ohsae7iuf9eoth \
    --given-name "Tooth" --surname "Fairy" \
    --mail-address="fairy@tooth-castle.example.com" \
    --company="The Tooth Castle" \
    --description='Will pay $1 for anythin white, small and sharp'

  # https://en.wikipedia.org/wiki/Urashima_Tar%C5%8D
  $ST user add 浦島太郎 phee0udai3Ae \
    --given-name "太郎" --surname "浦島" \
    --company="昔話" \
    --description='Urashima Tarō. Not so good at reading the calendar.' \
    --userou='OU=昔話,OU=More Users'

  # https://en.wikipedia.org/wiki/Ye_Xian
  $ST user add 葉限 EiDochou8ohf \
    --given-name "限" --surname "葉" \
    --mail-address="葉限@xn--iuzn16a.example.com" \
    --company="童话" \
    --description='Ye Xian. Got a pair of really nice slippers.' \
    --userou='OU=童话,OU=More Users'

  # Service user for i.e. apache/misp
  $ST user add srv_misp eew5Shiegheevua5iz9rohvi \
    --userou='OU=Service Users'

  # MISP Access groups
  $ST group add R_MISP_Access --description='MISP Access control' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_User --description='MISP Role User' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Admin --description='MISP Role Admin' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Readonly --description='MISP Role Readonly' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Publisher --description='MISP Role Publisher' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_Admin --description='MISP Role Org Admin' --groupou='OU=MISP,OU=Access Groups'

  # Organization groups for MISP
  $ST group add R_MISP_Org_TTC --description='MISP Org The Tooth Castle' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_North_Pole --description='MISP Org North Pole' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_昔話 --description='MISP Org 昔話 (JP)' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_童话 --description='MISP Org 童话 (CH)' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'


  $ST group add O_North_Pole --description='Group for users emplyed by North Pole'
  $ST group add O_TTC --description='Group for users emplyed by The Tooth Castle'
  $ST group add O_グループ１ --description='Group 1 (JP)'
  $ST group add O_第一组 --description='Group 1 (CH)'

  # Make adminsanta a proper admin
  $ST group addmembers Administrators adminsanta

  # Organizational groups
  for USER in santa adminsanta bunny; do
    # addmembers supports a list, but will fail
    # if any member already exists
    $ST group addmembers O_North_Pole $USER
  done

  $ST group addmembers O_TTC fairy
  $ST group addmembers O_グループ１ 浦島太郎
  $ST group addmembers O_第一组 葉限

  # Nested groups
  # Everyone employed by North Pole or TTC has MISP access
  for ORG in O_North_Pole O_TTC O_グループ１ O_第一组; do
    # addmembers supports a list, but will fail
    # if any member already exists
    $ST group addmembers R_MISP_Access $ORG
  done

  # TTC Employees only have RO access
  $ST group addmembers R_MISP_Readonly O_TTC

  # All North Pole employees, and user in group 1 have user access
  for ORG in O_North_Pole O_グループ１ O_第一组; do
    # addmembers supports a list, but will fail
    # if any member already exists
    $ST group addmembers R_MISP_User $ORG
  done

  # Santa gets admin access if he uses his admin account
  $ST group addmembers R_MISP_Admin adminsanta

  $ST group addmembers R_MISP_Org_North_Pole O_North_Pole
  $ST group addmembers R_MISP_Org_TTC O_TTC
  $ST group addmembers R_MISP_Org_昔話 O_グループ１
  $ST group addmembers R_MISP_Org_童话 O_第一组
} | grep -v 'already exists'

echo "Init complete. If there was no output there were no errors and all values already existed."
