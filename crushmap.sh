action=$1
if [ $action == "download" ]; then
   ceph osd getcrushmap -o /tmp/ma-crush-map
   crushtool -d /tmp/ma-crush-map -o /tmp/ma-crush-map.txt
elif [ $action == "upload" ]; then
   crushtool -c /tmp/ma-crush-map.txt -o /tmp/ma-crush-new-map
   ceph osd setcrushmap -i /tmp/ma-crush-new-map
else
   echo "Usage: ./crushmap.sh [download | upload ]"
fi
