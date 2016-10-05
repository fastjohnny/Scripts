#just for pulling all docker images from kolla docker hub

sed -i 's/^kolla_base_distro.*/kolla_base_distro: "centos"/g'  /etc/kolla/globals.yml
sed -i 's/^openstack_release.*/openstack_release: "1.1.1"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "1.1.2"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "2.0.1"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "2.0.2"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull


sed -i 's/^kolla_base_distro.*/kolla_base_distro: "ubuntu"/g'  /etc/kolla/globals.yml
sed -i 's/^openstack_release.*/openstack_release: "2.0.2"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "2.0.1"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "1.1.2"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull
sed -i 's/^openstack_release.*/openstack_release: "1.1.1"/g'  /etc/kolla/globals.yml
/opt/kolla/tools/kolla-ansible pull

