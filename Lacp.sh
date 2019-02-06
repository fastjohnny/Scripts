echo "commands for conf-t cisco interface portchannel (lacp) 1:1. Current interface(and portchannel and vpc) Start:$1 Stop: $2"
str=$1
end=$2
for i in $(seq $str $end); do
echo "
interface port-channel $i
negotiate auto
vpc $i
switchport mode trunk
exit
interface eth1/$i
no sh
switchport mode trunk
channel-group $i mode active
exit
"
done
echo "wr"
