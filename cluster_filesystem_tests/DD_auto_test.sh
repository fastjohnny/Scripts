rm dd*
rm RESULT/*
varc=1
echo "LIMIT?"
read LIMIT
echo "ok, LIMIT=$LIMIT"
echo "Block size?"
read bs
echo "ok, BS=$bs"
echo "Count?"
read cnt
let "cnt2 = cnt *3"
echo "ok, Count=$cnt"
while [ "$varc" -le "$LIMIT" ]
do
dd if=/dev/mapper/vgcluster-lv_gluster of=/var/glusterfs/write.dd bs=$bs count=$cnt &> dd_temp_log1
cat dd_temp_log1 | grep -w MB/c &> echo >>  dd_write_log
let "varc = varc + 1"
done
cat dd_write_log | cut -d ' ' -f9 &> echo >> RESULT/dd_write_flog
echo "ok, we done with write"

varc=1
while [ "$varc" -le "$LIMIT" ]
do
dd if=/var/glusterfs/write.dd of=/dev/mapper/vgcluster-lv_gluster bs=$bs count=$cnt2 &> dd_temp_log2
cat dd_temp_log2 | grep -w MB/c &> echo >>  dd_read_log
varc=`expr $varc + 1`
done
cat dd_read_log | cut -d ' ' -f9 &> echo >> RESULT/dd_read_flog
echo "ok, done with read, please wait"

cat RESULT/dd_write_flog | grep '\<[0-9][0-9][0-9]\>' &> echo >> dd_write_round
cat RESULT/dd_write_flog | grep '\<[0-9][0-9]\>' | cut -c 1,2 &> echo >> dd_write_round
cat RESULT/dd_write_flog | grep -v '\<[0-9][0-9]\>' | grep '\<[0-9]\>' | cut -c 1 &> echo >> dd_write_round
cat RESULT/dd_read_flog | grep '\<[0-9][0-9][0-9]\>' &> echo >> dd_read_round
cat RESULT/dd_read_flog | grep '\<[0-9][0-9]\>' | cut -c 1,2 &> echo >> dd_read_round
cat RESULT/dd_read_flog | grep -v '\<[0-9][0-9]\>' | grep '\<[0-9]\>' | cut -c 1 &> echo >> dd_read_round

N=0
M=0

file="dd_write_round"
while read line
do
let "N = N + line"
let "M= M + 1"
done < $file
let "N = N/M"
echo "Final write speed=$N MB/s Iterations=$M BS=$bs count=$cnt" >> RESULT/dd_write_flog
date >> RESULT/dd_write_flog
N=0
M=0
file="dd_read_round"
while read line
do
let "N = N + line"
let "M= M + 1"
done < $file
let "N = N/M"
echo "Final read speed=$N MB/s Iterations=$M BS=$bs count=$cnt" >> RESULT/dd_read_flog
date >> RESULT/dd_read_flog
rm dd*
rm echo
exit 0
