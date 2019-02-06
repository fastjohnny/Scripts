#!/bin/bash

#set -x

if [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]] || [[ "${1}" == "help" ]] || [[ "${3}" == "" ]]; then
  echo "Rabbitmq Cluster Deployer. Usage: `basename $0` MASTER_HOSTNAME(NOT FQDN!!) SLAVE1_HOSTNAME(NOT FQDN!!) SLAVE2_HOSTNAME(NOT FQDN!!) [erlang cookie]"
  echo "All Hosts must be added in DNS/hosts file"
  echo "Usage Example: ./rabbit_cluster_install.sh s05v0c3 s05v0c4 s05v0c5 GCYWENRQHSWVTAAMATZP"
  exit 0
fi

MASTER=$1
SLAVE1=$2
SLAVE2=$3
COOKIE=$4

#REPOS AND PACKAGES
export http_proxy=http://10.254.1.15:3128 ; export https_proxy=http://10.254.1.15:3128

cat << EOF > /etc/yum.repos.d/rabbitmq.repo
[rabbitmq]
gpgcheck=0
enabled=1
baseurl=https://YOUR_REPO/rabbitmq-server-rpm/
name=RabbitMQ RHEL 7
EOF


cat << EOF > /etc/yum.repos.d/rabbitmq-erlang.repo
[rabbitmq-erlang]
gpgcheck=0
enabled=1
baseurl=https://YOUR_REPO/rabbitmq-erlang/
name=RabbitMQ-Erlang RHEL 7
EOF

yum -y install erlang rabbitmq-server-3.7.2-1.el7 unzip keepalived

#KEEPALIVED
cat << EOF > /etc/keepalived/keepalived.conf
vrrp_instance rabbit_vip {
    state BACKUP
    interface eth0
    virtual_router_id 66
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass JnfrVEh%$3
    }
    virtual_ipaddress {
        10.254.64.69
    }
    track_script {
      chk_rabbit
    }
}
vrrp_script chk_rabbit {
  script       "/usr/local/bin/chk_rabbit.sh"
  interval 2   # check every 2 seconds
  fall 2       # require 2 failures for KO
  rise 2       # require 2 successes for OK
}
EOF

if [[ "${MASTER}" == `hostname -s` ]]; then
   sed -i 's/BACKUP/MASTER/g' /etc/keepalived/keepalived.conf
fi

systemctl restart keepalived

#PLUGINS
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/accept-0.3.3.ez -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/accept-0.3.3.ez
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/prometheus-3.4.5.ez  -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/prometheus-3.4.5.ez
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/prometheus_cowboy-0.1.4.ez -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/prometheus_cowboy-0.1.4.ez
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/prometheus_httpd-2.1.8.ez -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/prometheus_httpd-2.1.8.ez
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/prometheus_process_collector-1.3.1.ez -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/prometheus_process_collector-1.3.1.ez
wget https://github.com/deadtrickster/prometheus_rabbitmq_exporter/releases/download/v3.7.2.1/prometheus_rabbitmq_exporter-v3.7.2.1.ez -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/prometheus_rabbitmq_exporter-v3.7.1.1.ez
wget https://dl.bintray.com/rabbitmq/community-plugins/3.7.x/rabbitmq_delayed_message_exchange/rabbitmq_delayed_message_exchange-20171201-3.7.x.zip -O /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/rabbitmq_delayed_message_exchange-20171201-3.7.x.zip
unzip -o /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/rabbitmq_delayed_message_exchange-20171201-3.7.x.zip -d /usr/lib/rabbitmq/lib/rabbitmq_server-3.7.2/plugins/
rabbitmq-plugins enable prometheus_rabbitmq_exporter
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_management_agent
rabbitmq-plugins enable rabbitmq_web_dispatch


echo "${COOKIE}" > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
systemctl start rabbitmq-server

#JOIN CLUSTER
if [[ "${SLAVE1}" == `hostname -s` ]] || [[  "${SLAVE2}" == `hostname -s` ]]; then
  rabbitmqctl stop_app
  rabbitmqctl join_cluster --disc rabbit@${MASTER}
  rabbitmqctl start_app
fi

#UPDATE OPEN FILE LIMIT
mkdir /etc/systemd/system/rabbitmq-server.service.d/

cat << EOF > /etc/systemd/system/rabbitmq-server.service.d/limits.conf
[Service]
LimitNOFILE=65536
EOF

#Restart service
systemctl daemon-reload
systemctl restart rabbitmq-server

#Creating vhosts
rabbitmqctl add_vhost dev
rabbitmqctl add_vhost yellow
rabbitmqctl add_vhost release

#Adding User
rabbitmqctl add_user user 'R2f9ytfGYbTK'
rabbitmqctl set_user_tags user administrator
rabbitmqctl set_permissions -p / user ".*" ".*" ".*"
rabbitmqctl set_permissions -p dev user ".*" ".*" ".*"
rabbitmqctl set_permissions -p release user ".*" ".*" ".*"
rabbitmqctl set_permissions -p yellow user ".*" ".*" ".*"

#Mirrored queues
rabbitmqctl set_policy ha-all "" '{"ha-mode":"all"}'

