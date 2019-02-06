#!/bin/bash

set -x

if [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]] || [[ "${1}" == "help" ]] || [[ "${3}" == "" ]]; then
  echo "MSSQL Cluster Deployer. Usage: `basename $0` MASTER_HOSTNAME(NOT FQDN!!) SLAVE_HOSTNAME(NOT FQDN!!) MASTER_IP SLAVE_IP VIP BLOCKDEVICE"
  echo "All Hosts must be added in DNS/hosts file. Also Shared Storage should be attached before running this script"
  echo "Usage Example: ./mssql_cluster_install.sh s05v0c3 s05v0c4 10.254.64.60 10.254.64.61 10.254.64.59 /dev/sdb"
  exit 0
fi

read -p "WARNING! WARNING! If you have any mssql data here be aware - this script will eventually destroy existing mssql cluster. Are you sure?" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then


   MASTER=$1
   SLAVE=$2
   MASTER_IP=$3
   SLAVE_IP=$4
   VIP=$5
   DEVICE=$6
   CURRENT_IP=`ip -4 a | grep inet | grep -v 127.0.0.1 | cut -d"/" -f1 | cut -d" " -f6`
   CURRENT_MASK=`ip -4 a | grep inet | grep -v 127.0.0.1 | cut -d"/" -f2 | cut -d" " -f1`

   #REPOS AND PACKAGES
   export http_proxy=http://10.254.1.15:3128 ; export https_proxy=http://10.254.1.15:3128

cat << EOF > /etc/yum.repos.d/mssql-server-2017.repo
[mssql-server-2017]
gpgcheck=0
enabled=1
baseurl=https://art.3adigital.ru/mssql-server-2017/
name=MS SQL Server 2017 RHEL 7
EOF

   yum install -y mssql-server unixODBC-devel mssql-server-agent mssql-server-fts mssql-server-ha pacemaker corosync pcs

   useradd mssql
   mkdir -p /var/opt/mssql/data
   mkdir /var/opt/mssql/secrets
   chown -R mssql:mssql /var/opt/mssql
   chown mssql:mssql /opt/mssql/bin/sqlservr

   #CONFIGURE DAEMON
   if ! grep 'accept-eula' /usr/lib/systemd/system/mssql-server.service; then
     sed -i 's|ExecStart=/opt/mssql/bin/sqlservr|ExecStart=/opt/mssql/bin/sqlservr --accept-eula|g' /usr/lib/systemd/system/mssql-server.service
     systemctl daemon-reload
   fi


   #CONFIGURE STORAGE
   pvcreate $DEVICE
   vgcreate mssql-vg $DEVICE
   lvcreate -l 100%FREE -n mssql-lv mssql-vg
   mkfs.xfs /dev/mssql-vg/mssql-lv


   #CONFIGURE COROSYNC & PACEMAKER

   #We need this for our pcs FCI-mssql resource
   if ! grep FCI-mssql /etc/hosts; then
      sed -i 's/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 FCI-mssql/' /etc/hosts
   fi

cat << EOF > /etc/corosync/corosync.conf
totem {
    version: 2
    secauth: off
    cluster_name: mssql-cluster
    transport: udpu
    interface {
      member {
        memberaddr: $SLAVE_IP
      }
      member {
        memberaddr: $MASTER_IP
      }
      ringnumber:  0
      bindnetaddr: $CURRENT_IP
      mcastport:   5405
    }
}

quorum {
    provider: corosync_votequorum
    two_node: 1
}

nodelist {
    node {
        ring0_addr: $SLAVE_IP
        nodeid: 1
    }

    node {
        ring0_addr: $MASTER_IP
        nodeid: 2
    }
}

logging {
    to_logfile: yes
    logfile: /var/log/cluster/corosync.log
    to_syslog: yes
}
EOF

   echo 'hacluster:HA1qaz@WSX' | chpasswd

   systemctl enable corosync && systemctl start corosync
   systemctl enable pacemaker && systemctl start pacemaker

   pcs property set stonith-enabled=false
   pcs resource create mssql-share Filesystem device="/dev/mssql-vg/mssql-lv" directory="/var/opt/mssql/data" fstype="xfs" --group MSSQL
   pcs resource create mssql-vip ocf:heartbeat:IPaddr2 ip=$VIP nic=eth0 cidr_netmask=$CURRENT_MASK --group MSSQL
   pcs resource create FCI-mssql ocf:mssql:fci op monitor timeout=60s --group MSSQL


  #mssql-share waiting
  sleep 10
  pcs resource cleanup mssql-share
  sleep 4

  #determine if this node is a current master
  if mount | grep mssql; then

    #wiping old stuff
    rm -rf /var/opt/mssql/data/*

    #reinitializing of mssql-server, new password
    chown -R mssql:mssql /var/opt/mssql
    systemctl restart mssql-server
    systemctl stop mssql-server
    MSSQL_PID=Developer ACCEPT_EULA=Y MSSQL_SA_PASSWORD='5ibgjdfgn$@BF' /opt/mssql/bin/mssql-conf -n setup
  fi
  if ! grep SA /var/opt/mssql/secrets/passwd; then
    echo "SA" >> /var/opt/mssql/secrets/passwd
    echo '5ibgjdfgn$@BF' >> /var/opt/mssql/secrets/passwd
    systemctl reset-failed mssql-server
    systemctl restart mssql-server
  fi
  pcs resource cleanup FCI-mssql
fi
