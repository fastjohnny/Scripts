for i in 1 2 3 4 5 6 7
do scp -r 11.2.1.$i:DD_auto_test/RESULT/ ./vm$i; done
