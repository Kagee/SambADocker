#! /bin/bash

# Set up OUs, users and groups in AD
# based on fairytale characters

source <(grep -v '^#' .env | sed 's/^/export /')

ST="docker exec -it sambad samba-tool"
BO="$SMB_OU"

{

  # OU for admins
  $ST ou add "OU=North Pole Administrators,${BO}"
  
  # Sort acces groups in this OU
  $ST ou add "OU=Access Groups,${BO}"
  
  # Access groups for MISP
  $ST ou add "OU=MISP,OU=Access Groups,${BO}"
  $ST ou add "OU=Organizations,OU=MISP,OU=Access Groups,${BO}"
  
  # Santa, normal user and admin account
  $ST user add santa Niew9wie2eezah \
  	--given-name "Santa" --surname "Claus"  
  $ST user add adminsanta theiKahlee1pho \
  	--given-name "AdminSanta" --surname "Claus" \
  	--userou='OU=North Pole Administrators'
  
  # The easter bunny works for Santa most of the year
  $ST user add bunny Meish8somaeshe \
  	--given-name "Easter Island" --surname "Bunny"
  
  # The tooth fairy has an AD account, but 
  # works for The Tooth Castle (TTC)
  $ST user add fairy Ohsae7iuf9eoth \
  	--given-name "Tooth" --surname "Fairy"
  #	--given-name "Tooth" --surname "Fairy (external, TTC)"
  
  # MISP Access groups
  $ST group add R_MISP_Access --description='MISP Access control' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_User --description='MISP Role User' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Admin --description='MISP Role Admin' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Readonly --description='MISP Role Readonly' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Publisher --description='MISP Role Publisher' --groupou='OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_Admin --description='MISP Role Org Admin' --groupou='OU=MISP,OU=Access Groups'
  
  # Organization groups for MISP - not useful in current LDAP code
  $ST group add R_MISP_Org_TTC --description='MISP Org The Tooth Castle' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'
  $ST group add R_MISP_Org_North_Pole --description='MISP Org North Pole' --groupou='OU=Organizations,OU=MISP,OU=Access Groups'
  
  
  $ST group add O_North_Pole --description='Group for users emplyed by North Pole'
  $ST group add O_TTC --description='Group for users emplyed by The Tooth Castle'
  
  # Organizational groups
  for USER in santa adminsanta bunny; do
    # addmembers supports a list, but will fail
    # if any member already exists
    $ST group addmembers O_North_Pole $USER
  done
  $ST group addmembers O_TTC fairy
  
  # Nested groups
  # Everyone employed by North Pole or TTC has MISP access
  for ORG in O_North_Pole O_TTC; do
    # addmembers supports a list, but will fail
    # if any member already exists
    $ST group addmembers R_MISP_Access $ORG
  done
  # TTC Employees only have RO access
  $ST group addmembers R_MISP_Readonly O_TTC
  # All North Pole employees have user access
  $ST group addmembers R_MISP_User O_North_Pole
  # Santa gets admin access if he uses his admin account
  $ST group addmembers R_MISP_Admin adminsanta
} | grep -v 'already exists'

echo "Init complete. If there was no output there were no errors and all values already existed."
