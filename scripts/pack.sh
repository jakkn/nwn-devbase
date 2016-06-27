#! /bin/bash

FILE=$(readlink -f $0)
SCRIPTS_DIR=$(dirname $FILE)
BASE_DIR=$(dirname $SCRIPTS_DIR)
NWNTOOLS="$BASE_DIR"/nwntools
MODPACKER="$NWNTOOLS"/ModPacker
XMLTOGFF="$NWNTOOLS"/XmlToGff
TMP="$BASE_DIR"/tmp
PACKED="$BASE_DIR"/packed
UNPACKED="$BASE_DIR"/unpacked
MODULE="$PACKED"/testserver.mod

# Setup nwntools if necessary
if [ -d $NWNTOOLS ]; then
  if [ ! -x $MODPACKER -o ! -x $XMLTOGFF ]; then
    echo "Setting up nwntools..."
    cd $NWNTOOLS && ./setup.sh
    # Exit early if setup failed
    if [ ! -x $MODPACKER -o ! -x $XMLTOGFF ]; then
      echo -e "Failed to setup nwntools.\nExiting."
      exit
    fi
  fi
else
  echo -e "Cannot find nwntools.\nExiting."
  exit
fi

# Exit early if there are no sources to pack
if [ ! -d $UNPACKED ]; then
  echo -e "Cannot find module sources to pack. Check $UNPACKED.\nExiting."
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
