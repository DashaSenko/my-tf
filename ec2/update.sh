#! /bin/bash

apt-get update -y
apt-get install nginx -y

RANDOM1=$(echo $RANDOM % 12 + 1 | bc)
RANDOM2=$(echo $RANDOM % 12 + 1 | bc)
MY_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

if [ "${RANDOM2}" -eq "${RANDOM1}" ]; then
    let "RANDOM2++"
fi

wget https://my-tf-gifs.s3.eu-central-1.amazonaws.com/index.html \
    -O /var/www/html/index.html

sed -i "s/IP/$MY_IP/g" /var/www/html/index.html
sed -i "s/R1/$RANDOM1/g" /var/www/html/index.html
sed -i "s/R2/$RANDOM2/g" /var/www/html/index.html

systemctl restart nginx.service