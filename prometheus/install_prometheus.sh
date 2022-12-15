#! /bin/bash

#refer - https://computingforgeeks.com/install-prometheus-server-on-debian-ubuntu-linux/

#creating prometheus system group
sudo groupadd --system prometheus

#creating prometheus user
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

#Creating data & configs directories for Prometheus
sudo mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done

#Downloading Prometheus on Ubuntu

#Install wget
sudo apt update
sudo apt -y install wget curl vim

#download latest binary archive for Prometheus
mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -

#Extract the file
tar xvf prometheus*.tar.gz
cd prometheus*/

#Move the binary files to /usr/local/bin/ directory
sudo mv prometheus promtool /usr/local/bin/

#Move Prometheus configuration template to /etc directory
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
sudo mv consoles/ console_libraries/ /etc/prometheus/
cd $HOME

#removing the temporary directory we created 
rm -rf /tmp/prometheus/

#Create a Prometheus systemd Service unit file
sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#Change the ownership of these directories to Prometheus user and group
for i in rules rules.d files_sd; do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; done
for i in rules rules.d files_sd; do sudo chmod -R 775 /etc/prometheus/${i}; done
sudo chown -R prometheus:prometheus /var/lib/prometheus/

#Reload systemd daemon and start the service
sudo systemctl daemon-reload
sudo systemctl start prometheus
