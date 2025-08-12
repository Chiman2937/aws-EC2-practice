#!/bin/bash
cd /home/ubuntu/nextjs-ec2-test 
git pull origin main
sudo npm install
sudo npm run build
pm2 describe next_app >/dev/null 2>&1 && pm2 restart next_app || pm2 start "npm start" --name next_app