#/bin/bash

inotifywait --exclude '.git/*' -mr -e close_write . | sed -ue 's/ CLOSE_WRITE,CLOSE //' | xargs -d$'\n' -I% scp  -P 22 -i /home/thunderrabbit/.ssh/perl.robnugen.com % dh_r2ixxd@perl.robnugen.com:/home/dh_r2ixxd/perl.robnugen.com/%

# inotifywait -mre close_write . | \      # m = monitor # r = resurse subdirs # e = these events
# sed -ue 's/ CLOSE_WRITE,CLOSE //' | \         # removing ' CLOSE_WRITE,CLOSE ' leaves us with exactly the file we need to save
# xargs -d$'\n' -I% \                # converts the stream into something scp can use
# scp -P 22 -i /home/thunderrabbit/.ssh/ABs_AB_webserver_2018.pem % ubuntu@52.195.7.199:/var/www/admint.andbeyond.co.jp/current/
