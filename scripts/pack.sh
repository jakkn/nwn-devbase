#! /bin/bash

FILE=$(readlink -f $0)
SCRIPTS_DIR=$(dirname $FILE)
BASE_DIR=$(dirname $SCRIPTS_DIR)
NWNTOOLS="$BASE_DIR"/nwntools
MODPACKER="$NWNTOOLS"/ModPacker
TMP="$BASE_DIR"/tmp
PACKED="$BASE_DIR"/packed
UNPACKED="$BASE_DIR"/unpacked
MODULE="$PACKED"/testserver.mod
#echo -e "file:\t\t$FILE"
#echo -e "scriptdir:\t$SCRIPTS_DIR"
#echo -e "basedir:\t$BASE_DIR"
#echo -e "nwntools:\t$NWNTOOLS"


# Setup nwntools if necessary
if [ -d $NWNTOOLS ]; then
  if [ ! -x $MODPACKER ]; then
    echo "Setting up nwntools..."
    cd $NWNTOOLS && ./setup.sh
    # Exit early if setup failed
    if [ ! -x $MODPACKER ]; then
      echo "Failed to setup nwntools."
      echo "Exiting."
      exit
    fi
  fi
else
  echo "Cannot find nwntools."
  echo "Exiting."
  exit
fi

# Exit early if there are no sources to pack
if [ ! -d $UNPACKED ]; then
  echo "Cannot find module sources to pack. Check $UNPACKED."
  echo "Exiting."
  exit
fi

echo "Setting nwntools environment variables..."
cd $NWNTOOLS && ./setpath.sh

if [ -d $TMP ]; then
  echo "Cleaning temporary storage..."
  rm -r $TMP/*
else
  mkdir $TMP
fi

echo "Copying resources to temporary storage..."
pushd $UNPACKED >> /dev/null
for d in *; do
  if [ -d $d ]; then
    cp $d/* $TMP
  else cp $d $TMP
  fi
done
popd >> /dev/null

if [ ! -d $PACKED ]; then
  mkdir $PACKED
fi

$MODPACKER $TMP $MODULE

echo "Deleting temporary storage..."
rm -r $TMP

echo "Done."
