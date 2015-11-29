#! /bin/bash

FILE=$(readlink -f $0)
SCRIPTS_DIR=$(dirname $FILE)
BASE_DIR=$(dirname $SCRIPTS_DIR)
NWNTOOLS="$BASE_DIR"/nwntools
MODUNPACKER="$NWNTOOLS"/ModUnpacker
TMP="$BASE_DIR"/tmp
PACKED="$BASE_DIR"/packed
UNPACKED="$BASE_DIR"/unpacked
MODULE="$PACKED"/testserver.mod


# Setup nwntools if necessary
if [ -d $NWNTOOLS ]; then
  if [ ! -x $MODUNPACKER ]; then
    echo "Setting up nwntools..."
    cd $NWNTOOLS && ./setup.sh
    # Exit early if setup failed
    if [ ! -x $MODUNPACKER ]; then
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

# Exit early if there is no module to unpack
if [ ! -d $UNPACKED ]; then
  echo "Cannot find module to unpack. Check $PACKED."
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

echo "Extracting module to temporary storage..."
$MODUNPACKER $MODULE $TMP

if [ -d $UNPACKED ]; then
  echo "Cleaning old sourcefiles..."
  rm -r $UNPACKED/*
else
  mkdir $UNPACKED
fi

echo "Moving sources into $UNPACKED/ ..."
pushd $TMP >> /dev/null
for f in *; do
  if [ -f $f ]; then
    # create dir for extension in $UNPACKED
    mkdir -p $UNPACKED/${f##*.}
    # move all files with extension into $UNPACKED
    mv *.${f##*.} $UNPACKED/${f##*.}/
  fi
done
popd >> /dev/null

echo "Deleting temporary storage..."
rmdir $TMP

echo "Done."
