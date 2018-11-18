#! /bin/bash
#APM tool writen by Avery Nutting-Hartman and Andrew Villella
#program starts 6 applications then monotors the system metrics until it is killed resulting in the termination of all applications started by this application.

systemlevel () {
	#monitor network recieve and transmit rates
	#only works on the lab machines change to local interface to work on your machine
	network=$(ifstat 2>/dev/null | egrep ens33 | awk '{ print $7 "," $9 }' | sed 's/K//')
	#hard disk writes   
	write=$(iostat | awk '/sda/' | awk '{print $4}')
	#monitor disk utilization
	disk=$(df -hm | egrep /dev/mapper/centos-root | awk '{ print $4}')
	systemprint $network $write $disk
}

processlevel () {
	#monitors cpu and memory output
	i=1
	while [ $i -lt 7 ]
	do 
		curr="id$i"			
		process=$( ps -q ${!curr} -o comm= )
		text=$( ps -q ${!curr} --no-headers -o %cpu,%mem | awk '{print $1 "," $2}' )
		processprint $process $text
		(( i++ ))
	done

}
#prints the process level metrics
processprint () {
	echo "$SECONDS,$2" >> $1_metrics.csv
}
#prints the system level metrics
systemprint () {
	echo "$SECONDS,$1,$2,$3" >> system_metrics.csv
}
#starts all the processes and stores their PID
start () {
	./APM1 $ip &
	export id1=$!
	./APM2 $ip &
	export id2=$!	
	./APM3 $ip &
	export id3=$!	
	./APM4 $ip &
	export id4=$!
	./APM5 $ip &
	export id5=$!
	./APM6 $ip &
	export id6=$!
	ifstat -d 1 
}
#kills all the processes and echos how long the AMP ran for  
finish () {
	kill -9 $id1
	kill -9 $id2
	kill -9 $id3
	kill -9 $id4
	kill -9 $id5
	kill -9 $id6
	pid=$( ps -u student | egrep 'ifstat' | awk '{print $1}' )
	kill -9 $pid
	echo " "
	echo "AMP monitor ran for $SECONDS seconds" 
}
trap finish EXIT
#checks to see if IP was entered as a parameter
if [ $# -ne 1 ]
then
	echo 'Usage: ./APM.sh IPAddress'
	exit 2>/dev/null
fi
ip=$1
start
#Infinate loop that takes system and process metrics every 5 seconds 
while true 
do 
	systemlevel
	processlevel
	echo $SECONDS
	sleep 5
done
