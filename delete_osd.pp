#run under root dir on node with ceph
#removes osd from openstack node
class del_ceph_osd($osd, $dev) {
        Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/'] }
        exec {"mark down osd": command => "stop ceph-osd id=$osd"}
->
        exec {"auth osd del": command => "ceph auth del osd.$osd"}
->

        exec {"umount device": command => "umount -l /dev/$dev"}
->
        exec {"remove osd": command => "ceph osd rm osd.$osd"}
->
        exec {"out osd": command => "ceph osd out osd.$osd"}
->
        exec {"remove osd from crushmap": command => "ceph osd crush remove osd.$osd"}
->

notify {"DONE!":}
}
class {'del_ceph_osd':
       osd => 1,
       dev => sdc3,
}

