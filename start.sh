#!/bin/bash
/usr/sbin/sshd
cd /usr/local/x-ui && ./x-ui &
# sing-box فقط وقتی اجرا می‌شه که config.json براش ساخته باشی
if [ -f /usr/local/sing-box/config.json ]; then
    cd /usr/local/sing-box && ./sing-box run -c config.json &
fi
wait -n
