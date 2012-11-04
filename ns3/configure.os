#!/usr/bin/env bash
# Configure NS3

OS=`uname -s`
CFLAGS=${CFLAGS:--Wall -O3}

# try to find the ns3 header files.
# TODO this is just a random collection of dirs atm
NS3_DIRS="/usr/local/include/ns3-dev /usr/local/include/ns3.15"

NS3_DIR="notfound"

for loc in ${NS3_DIRS}; do
  if [ -d "${loc}" ]; then
    echo NS3 found in: ${loc}
    NS3_DIR="${loc}"
  else
    echo NS3 not found in: ${loc}
  fi
done

if [ "${NS3_DIR}" = "notfound" ]; then
  echo NS3 installation directory not found.
  echo Install it and add the directory to NS_DIRS in $0
  exit 1
else
  echo Using NS3 installation at: $NS3_DIR
fi

CFLAGS="${CFLAGS} -I${NS3_DIR}"
case `uname -m` in
x86_64)
  CFLAGS="${CFLAGS} -fPIC"
  ;;
esac

case "$OS" in
Darwin)
  ;;
Linux)
  ;;
*)
  echo Unknown arch $OS
  exit 1
esac


