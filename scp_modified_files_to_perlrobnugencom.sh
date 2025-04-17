#/bin/bash


DEST_USER="dh_r2ixxd"
DEST_HOST="perl.robnugen.com"
DEST_PATH="/home/$DEST_USER/perl.robnugen.com/"
SSH_KEY="/home/thunderrabbit/.ssh/perl.robnugen.com"

# This will watch for changes in the source directory and scp them to the destination
inotifywait --exclude '.git/*' -mr -e close_write . | sed -ue 's/ CLOSE_WRITE,CLOSE //' | xargs -d$'\n' -I% scp  -P 22 -i $SSH_KEY % $DEST_USER@$DEST_HOST:$DEST_PATH%
