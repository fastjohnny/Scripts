#mount | grep ceph | awk '{print $3}' | cut -d'/' -f 6| cut -d'-' -f 2
#ids=(1, 13, 18, 23, 34, 43, 53, 62, 69, 72, 86, 95, 99, 107, 127, 130, 139, 143, 151, 161, 165, 175, 182)
ids=(1 13 18 23 34 43 53 62 69 72 86 95 99 107 127 130 139 143 151 161 165 175 182)
#for i in "${ids[@]}"; do stop ceph-osd id=$i; done
#for i in "${ids[@]}"; do ceph osd down $i; done
#for i in "${ids[@]}"; do umount /var/lib/ceph/osd/ceph-$i;done
for i in "${ids[@]}"; do ceph osd crush remove osd.$i; done
for i in "${ids[@]}"; do ceph auth del osd.$i; done

