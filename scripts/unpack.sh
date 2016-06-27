#! /bin/bash

MODULE=$(readlink -e "$1")
FILE=$(readlink -f "$0")
SCRIPTS_DIR=$(dirname $FILE)
BASE_DIR=$(dirname $SCRIPTS_DIR)
TMP="$BASE_DIR"/tmp
UNPACKED="$BASE_DIR"/unpacked

extract() {
  clean
  echo "Extracting module to $TMP"
  pushd "$TMP"
  nwn-erf -x -f "$MODULE"
  $MODTOXML $MODULE $TMP
  exit 0;
  
  echo "Moving sources into $UNPACKED/ ..."
  pushd $TMP >> /dev/null
  for f in *; do
    if [ -f $f ]; then
      # prune .xml extension
      f=${f%.xml}
      # get remaining file extension
      EXT=${f##*.}
      # create dir for extension
      mkdir -p $UNPACKED/$EXT
      # move files to designated dir
      if [ -f $f.xml ]; then
        mv *.$EXT.xml $UNPACKED/$EXT/
      else
        mv *.$EXT $UNPACKED/$EXT/
      fi
    fi
  done
  popd >> /dev/null
  
  echo "Deleting temporary storage..."
  rmdir $TMP
  
  echo "Done."
}

clean() {
  [ -d $TMP ] && { echo "Cleaning $TMP"; rm -r $TMP; }
  mkdir $TMP
  [ -d $UNPACKED ] && { echo "Cleaning $UNPACKED"; rm -r $UNPACKED; }
  mkdir $UNPACKED
}

# Exit early if executables or module file are missing
verifyEnvironment() {
  testExecutableExists nwn-erf
  testExecutableExists nwn-gff
  testModuleExists
}

# Tests if the executable is in PATH.
# Arguments:
#   $1 - the executable to test for
testExecutableExists() {
  hash $1 2>/dev/null || { echo -e >&2 "I require $1 but I cannot find it. Please install and check that the executable is in PATH. \nAborting."; exit 1; }
}

testModuleExists() {
  [ -f $MODULE ] || { echo -e "Cannot find $MODULE.\nAborting."; }
}

verifyEnvironment
extract
