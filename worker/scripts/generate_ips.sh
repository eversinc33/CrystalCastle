#!/bin/bash
# generate ips for the config
rm ../ips.txt
for i in {3..254}; # htb starts at 10.10.10.3
do
cat<<EOF >> ../ips.txt
    - 10.10.10.$i
EOF
done