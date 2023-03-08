#!/bin/bash
set -e
HC='\033[1;32m'
NC='\033[0m'

MYDOMAIN=

chkdomain() {

    echo -e "\n$HC+$NC Checking IP <=> Domain..."
    RESIP=$(dig +short "$1" | grep '^[.0-9]*$' || echo 'NONE')
    SRVIP=$(curl -qs http://checkip.amazonaws.com  | grep '^[.0-9]*$' || echo 'NONE')

    if [ "$RESIP" = "$SRVIP" ]; then
        echo -e "\n$HC+$NC $RESIP => $1 is valid."
    else
        echo -e "\033[1;31m -- Error: \033[0m Server IP is $HC$SRVIP$NC but '$1' resolves to \033[1;31m$RESIP$NC\n"
        echo -e "If you have just updated the DNS record, wait a few minutes and then try again. \n"
        exit;
    fi
}

install(){
    echo "Installing xui, certbot, and ssl certificates..."

    read -p "Please enter your domain or subdomain: " MYDOMAIN
    chkdomain $MYDOMAIN

    # install certbot
    echo "\n$HC+$NC Installing certbot..."
    apt update 
    apt install snapd -y 
    snap install core 
    snap refresh core 
    snap install --classic certbot 
    ln -s /snap/bin/certbot /usr/bin/certbot 

    echo "\n$HC+$NC Issueing certificate for $MYDOMAIN"
    certbot certonly --standalone -d $MYDOMAIN --register-unsafely-without-email --non-interactive --agree-tos 2>> 2.log 1>> 1.log

    echo "\n$HC+$NC installing x-ui..."

    read -p "Username: " USERNAME

    read -p "Password: " PASSWORD

    read -p "Port: " PORT

    echo -e "\n$HC+$NC Installing xray and x-ui..."
    wget https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install_en.sh --no-check-certificate  2>> 2.log 1>> 1.log
    chmod +x install_en.sh 2>> 2.log 1>> 1.log

    echo "y
    $USERNAME
    $PASSWORD
    $PORT
    " | ./install_en.sh 2>> 2.log 1>> 1.log


    echo "\n\n"
    echo "x-ui installed successfully."
    echo "Panel's URL: https://$MYDOMAIN:$PORT" > panel.txt
    echo "Panel's username: $USERNAME" >> panel.txt
    echo "Panel's password: $PASSWORD" >> panel.txt
    echo "cert path: /etc/letsencrypt/live/$MYDOMAIN/fullchain.pem" >> panel.txt
    echo "cert path: /etc/letsencrypt/live/$MYDOMAIN/privkey.pem" >> panel.txt

    cat panel.txt
}

install
