#!/usr/bin/env bash

host=${1:-google.com}
port=${2:-443}
test=${3:false}

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "Lets go! Running for ${BLUE}$host${NC} on port ${BLUE}$port${NC}"

if [ $test == true ]; then
  echo "this is only a test"
  openssl s_client -showcerts -servername $host -connect $host:$port </dev/null
  openssl s_client -showcerts -servername $host -connect $host:$port 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
  exit
fi

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

certfile=$host".pem"
openssl s_client -showcerts -servername $host -connect $host:$port 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $certfile

if [ ! -f $certfile ]; then
  echo -e "${RED}Failed to get cert${NC}"
  exit
fi

if [[ "$ID" == "ubuntu" ]]; then
  echo "Running for ubuntu"
  # changing file to crt to work in ubuntu
  sudo cp $certfile /usr/local/share/ca-certificates/$host.crt
  sudo update-ca-certificates
elif [[ "$ID" == "fedora" ]]; then
  echo "Running for fedora"
  sudo cp $certfile /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust
else
  echo -e "${RED}Distro was neither ubuntu nor fedora and I am sorry${NC}"
fi

# Cleanup file
if [ -f "$certfile" ] ; then
    rm "$certfile"
fi

echo -e "${GREEN}rest asured it seems like it worked${NC}"