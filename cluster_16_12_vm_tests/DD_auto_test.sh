rm dd*
rm ./RESULT/*
varc=1
echo "LIMIT?"
read LIMIT
echo "ok, LIMIT=$LIMIT"
echo "Block size?"
read bs
echo "ok, BS=$bs"
bs2=1
let "bs2 = bs * 2"
echo "$bs2"
echo "Count?"
read cnt
echo "ok, Count=$cnt"
while [ "$varc" -le "$LIMIT" ]
do
dd if=/dev/zero of=./dd.zero bs=$bs count=$cnt &> dd_temp_log1
cat dd_temp_log1 | grep -w MB/s &> echo >>  dd_zero_log
let "varc = varc + 1"
done
cat dd_zero_log | cut -d ' ' -f9 &> echo >> RESULT/dd_zero_flog
echo "ok, we done with zero"
varc=1
while [ "$varc" -le "$LIMIT" ]
do
dd if=/dev/urandom of=./dd.urandom bs=$bs count=$cnt &> dd_temp_log2
cat dd_temp_log2 | grep -w MB/s &> echo >>  dd_urandom_log
varc=`expr $varc + 1`
done
cat dd_urandom_log | cut -d ' ' -f9 &> echo >> RESULT/dd_urandom_flog


echo "ok, done with urandom, please wait"
varc=1
while [ "$varc" -le "$LIMIT" ]
do
dd if=/dev/hda3 of=./dd.hda3 bs=$bs count=$cnt &> dd_temp_log3
cat dd_temp_log3 | grep -w MB/s &> echo >>  dd_hda3_log
varc=`expr $varc + 1`
done
cat dd_hda3_log | cut -d ' ' -f9 &> echo >> RESULT/dd_hda3_flog
echo "ok, done with hda3"

cat RESULT/dd_urandom_flog | grep '\<[0-9][0-9][0-9]\>' &> echo >> dd_urandom_round
cat RESULT/dd_urandom_flog | grep '\<[0-9][0-9]\>' | cut -c 1,2 &> echo >> dd_urandom_round
cat RESULT/dd_urandom_flog | grep -v '\<[0-9][0-9]\>' | grep '\<[0-9]\>' | cut -c 1 &> echo >> dd_urandom_round
cat RESULT/dd_hda3_flog | grep '\<[0-9][0-9][0-9]\>' &> echo >> dd_hda3_round
cat RESULT/dd_hda3_flog | grep '\<[0-9][0-9]\>' | cut -c 1,2 &> echo >> dd_hda3_round
cat RESULT/dd_hda3_flog | grep -v '\<[0-9][0-9]\>' | grep '\<[0-9]\>' | cut -c 1 &> echo >> dd_hda3_round
cat RESULT/dd_zero_flog | grep '\<[0-9][0-9][0-9]\>' &> echo >> dd_zero_round
cat RESULT/dd_zero_flog | grep '\<[0-9][0-9]\>' | cut -c 1,2 &> echo >> dd_zero_round
cat RESULT/dd_zero_flog | grep -v '\<[0-9][0-9]\>' | grep '\<[0-9]\>' | cut -c 1 &> echo >> dd_zero_round

N=0
M=0

file="dd_urandom_round"
while read line
do
let "N = N + line"
let "M= M + 1"
done < $file
let "N = N/M"
echo "Final speed=$N MB/s Iterations=$M BS=$bs count=$cnt" >> RESULT/dd_urandom_flog
date >> RESULT/dd_urandom_flog
N=0
M=0
file="dd_zero_round"
while read line
do
let "N = N + line"
let "M= M + 1"
done < $file
let "N = N/M"
echo "Final speed=$N MB/s Iterations=$M BS=$bs count=$cnt" >> RESULT/dd_zero_flo 
date >> RESULT/dd_zero_flog
N=0
M=0
file="dd_hda3_round"
while read line
do
let "N = N + line"
let "M= M + 1"
done < $file
let "N = N/M"
echo "Final speed=$N MB/s Iterations=$M BS=$bs count=$cnt" >> RESULT/dd_hda3_flog
date >> RESULT/dd_hda3_flog
exit 0
