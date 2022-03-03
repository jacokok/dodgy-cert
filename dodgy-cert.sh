#!/usr/bin/env bash

host=${1:-google.com}
port=${2:-443}
test=${3:false}

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Supported Distros
DISTROS=("ubuntu" "fedora" "alpine")

# Get Current Distro
if [ -f /etc/os-release ]
then
  . /etc/os-release
else
  echo -e "${RED}ERROR:Could not determine distribution${NC}"
  exit
fi

if [[ "$host" == *"https"* ]]
then
  echo -e "${RED}Do not include https only base domain${NC}"
  exit
fi

echo -e "Lets go! Running for ${BLUE}$host${NC} on port ${BLUE}$port${NC} for dist ${BLUE}$ID{NC}"

if [[ ! "${DISTROS[*]}" =~ "${ID}" ]]; then
    echo "Not supported distro"
    exit
fi

if ! openssl version
then
    echo "Please install openssl"
    exit
fi

if [[ $test == true ]]; then
  echo "this is only a test"
  openssl s_client -showcerts -servername $host -connect $host:$port </dev/null
  exit
fi

# Get all certs for site
certificates=()
openssl s_client -showcerts -verify 5 -connect $host:$port < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".pem"; print >out}'
for cert in *.pem; 
do 
  newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g;p' | tr '[:upper:]' '[:lower:]').pem; 
  mv $cert $newname;
  certificates+=($newname);
done

echo "${#certificates[@]}"

if [ ${#certificates[@]} -le 0 ]; then
  echo -e "${RED}Failed to get certs${NC}"
  exit
fi


echo -e "Running for ${BLUE}${ID}${NC}"
if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "alpine" ]]; then
  for certfile in "${certificates[@]}"
  do
      # changing file to crt to work in ubuntu
      sudo cp $certfile /usr/local/share/ca-certificates/$certfile.crt
  done
  sudo update-ca-certificates
elif [[ "$ID" == "fedora" ]]; then
  for certfile in "${certificates[@]}"
  do
      sudo cp $certfile /etc/pki/ca-trust/source/anchors/
  done
  sudo update-ca-trust
else
  echo -e "${RED}Distro not supported and I am sorry${NC}"
fi

# Cleanup files
for certfile in "${certificates[@]}"
do
  if [ -f "$certfile" ] ; then
    rm "$certfile"
  fi
done

echo -e "${GREEN}rest asured it seems like it worked${NC}"