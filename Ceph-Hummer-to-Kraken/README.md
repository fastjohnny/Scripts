#Ceph upgrade instructions
---------
Instruction (bash commands) to deploy Kraken Ceph
over existing Hammer environment (Openstack via Fuel 9.2) with user information on it.

---------
Short desription of procedure:
1. Add ceph repos, gpg-keys, Remove mos repos
2. Remove ceph-deploy tool due to installation problems (LP bug #1475910 )
2. Install jewel packages, restart services
3. Set sortbitwise on all osds, set Kraken flag
4. Install Kraken Packages, restart services
5. Check status, versions
