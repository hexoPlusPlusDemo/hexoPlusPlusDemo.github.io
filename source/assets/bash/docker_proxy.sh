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
