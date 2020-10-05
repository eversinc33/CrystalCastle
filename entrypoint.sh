#!/bin/bash
echo "[ ] Waiting for database to come online"
until ping -c1 db >/dev/null 2>&1; do :; done
sleep 5
# ruby /app/worker/main.rb --reset-db
ruby /app/worker/main.rb --setup-db
echo "[ ] Starting webserver"
rackup --host 0.0.0.0 -p 9292 &
echo "[+] DB set up. You can now log in"
service cron start
crontab /cronjob
# ruby /app/worker/main.rb
tail -f /dev/null
