#! /bin/bash
# script is used for compiling this small project

DIST_DIR_NAME=torerlo_bin
DIST_DIR=../$DIST_DIR_NAME
CURRENT_DIR=`pwd`


if [ ! -d $DIST_DIR ]
then
  mkdir $DIST_DIR
fi

scan() {
  for filename in "$1"/*; do
     if [ -d "$filename" -a ! -L "$filename" ]
     then
       scan "$filename"
     else
       if [ `echo $filename | grep -c "\.erl"` -eq 1 ]
       then
         erlc $filename
         filename_bin=`echo $filename | sed "s|/torerlo/|/$DIST_DIR_NAME/|"`
         mv ${filename%.erl}.beam ${filename_bin%.erl}.beam
       fi
     fi
  done
}

scan "$CURRENT_DIR"