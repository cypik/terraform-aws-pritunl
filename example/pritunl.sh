#!/bin/bash

sudo sudo apt-get update -y
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7AE645C0CF8E292A
sudo echo "deb http://repo.pritunl.com/stable/apt $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/pritunl.list
sudo apt --assume-yes install pritunl mongodb-org
sudo apt-get update -y
sudo apt-get install pritunl -y
sudo systemctl start pritunl
sudo systemctl enable pritunl

curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc%7Csudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-6.gpg
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update -y
sudo apt install mongodb-org -y
sudo systemctl start mongod.service
sudo systemctl enable mongo