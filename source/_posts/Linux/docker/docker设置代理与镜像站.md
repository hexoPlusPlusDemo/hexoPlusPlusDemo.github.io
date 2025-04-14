title: docker 设置代理与镜像站
edited_seconds: 60
abbrlink: d7880d8f2f2e
updated_at: 2025-02-23 12:39:30
date: 2025-03-24 10:24:51
---
```bash
curl https://zhywyt.github.io/assets/bash/docker_proxy.sh | sudo bash <your proxy>

curl https://zhywyt.github.io/assets/bash/docker_proxy.sh | sudo bash http://10.10.10.100:7890
```

[脚本下载](../../assets/bash/docker_proxy.sh)

这里也给出脚本：
```bash
proxy=$1
mkdir -p /etc/systemd/system/docker.service.d
echo "Create and set the file /etc/systemd/system/docker.service.d/http-proxy.conf"

echo "Proxy is $proxy"
echo "[Service]" > /etc/systemd/system/docker.service.d/http-proxy.conf
echo "Environment=\"HTTP_PROXY=$proxy\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
echo "Environment=\"HTTPS_PROXY=$proxy\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
echo "Environment=\"NO_PROXY=localhost,127.0.0.1\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
echo "Set the proxy for docker"

systemctl daemon-reload
echo "Restart the docker service"
systemctl restart docker
echo "Done"

```