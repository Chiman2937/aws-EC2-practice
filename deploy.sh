#!/bin/bash
cd /home/ubuntu/aws-EC2-practice
git pull origin main
sudo npm install
sudo npm run build
pm2 restart next_app
