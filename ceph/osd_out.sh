#!/bin/bash
set -x
PGS_COUNT='4544'
LOG='/var/log/ceph_out.log'
WORK_HOUR='2' #2 AM UTC + 2h for osd out + 3h UTC = MSK UTC+3:00
WORK_DAY=`date +%u -d '+1 day'` #NEXT DAY
while read osd; do
CURRENT_STATE=`ceph -s | grep degraded`
HOUR=`date +%H` #In 24h format
DAY=`date +%u` #In 1-7 format

#If something is degraded then do nothing
  if [[ $CURRENT_STATE != '' ]]; then
   echo "Cluster is not healthy, exit" >> $LOG
   ceph -s >> $LOG
   exit 1;
  fi

#If we are near working hours (5 AM, for example), exit
  if [[ $DAY == $WORK_DAY ]]; then
    if [[ $HOUR -ge $WORK_HOUR ]]; then
      echo "Dont starting osd out process due to date"  >> $LOG
      exit;
    fi
  fi
  echo "removing osd $osd" >> $LOG
  date >> $LOG
  ceph -s >> $LOG 
  ceph osd out $osd
  ceph osd tree >> $LOG
  echo '--------------' >> $LOG
  while true
    do sleep 15
    ceph -s >> $LOG
    clean=`ceph -s |grep 'active+clean' | awk '{print $1}'`
    echo "Clean PG $clean vs all PG $PGS_COUNT" >> $LOG
    if [[ $clean == $PGS_COUNT ]]; then 
      echo 'done' >> $LOG;
      stop ceph-osd id=$osd 
      ceph osd crush rm osd.$osd
      ceph auth del osd.$osd
      ceph osd rm osd.$osd
      umount /var/lib/ceph/osd/ceph-$osd
      break; 
    fi
  done
done < osds

ceph osd unset noscrub;
ceph osd unset nodeep-scrub;
echo "Final resource overview" >> $LOG
ceph -s >> $LOG
ceph osd tree >> $LOG
echo '--------------' >> $LOG
