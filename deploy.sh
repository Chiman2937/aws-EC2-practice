#!/bin/bash
cd /home/ubuntu/aws-EC2-practice
git pull origin main
sudo npm install
sudo npm run build
pm2 describe next_app >/dev/null 2>&1 \
  && pm2 restart next_app \
  || pm2 start npm --name next_app -- start --cwd /home/ubuntu/aws-EC2-practice -- -H 0.0.0.0 -p 3000
