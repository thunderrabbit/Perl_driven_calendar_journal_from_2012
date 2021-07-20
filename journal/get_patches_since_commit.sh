#!/bin/bash

if [ -z "$1" ]
  then
      echo "Usage: $0 <hash of parent commit>"
      echo "here is what we have already:"
      git log --oneline --graph --decorate --all -15
      cd /home/barefoot_rob/barefoot_rob/content/journal
      echo "here is what we might not have yet:"
      git log --oneline --graph --decorate --all -15
    exit
fi

HASH=$1

echo "Getting commits since $HASH"

cd /home/barefoot_rob/temp.robnugen.com/journal

git --git-dir=../../barefoot_rob/content/journal/.git format-patch -n $HASH

cat *.patch | git am --directory journal

rm *.patch

echo "BE SURE TO git push"
