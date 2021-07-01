#!/usr/bin/env bash

usage() {

cat <<-EOF
	get-sar.sh cluster-node-basename number-of-nodes working-node [ssh user]

	working-node refers to the node where the work is being performed, with a value of 0-9
	(RAC nodes are usually numbered)
	It is assumed that this node is part of the cluster
	Should the working node be a server not in the cluster, indicate it with 'na' for this argument

	It is also assumed the first node is '1'

	Given the following:
	
	- 4 node cluster
	- you are working on node #2
	- nodes are ora192rac01 - ora192rac04

	get-sar.sh ora192rac0 4 2

	directories created:
	  ora192rac01/sa
	  ora192rac02/sa
	  ora192rac03/sa
	  ora192rac04/sa

	The SAR files will be copied from the local machine via 'cp' to the appropriate directory
	The remaining directories will be populated via ssh and tar

	If the machine where you are collecting the data is not part of the cluster:

	get-sar.sh ora192rac0 4 na

	In this case, all directories are copied via ssh and tar.

	Important:  If the asp.sh script is to be used with the '-p' option to match disk device names 
	to their logical names, this MUST performed on the server where the sar files originated.
	Otherwise, the logical names may be incorrect, as they can be mapped differently per server.

	The ssh user is assumed to be 'oracle' unless the 4th parameter is included

EOF

}


[[ "$#" -lt 3 ]] && {
	usage
	exit 1
}

IFS=' ' read -r nodeBase nodes workingNode sshUser <<< "$1 $2 $3 $4"

workingNode=${workingNode,,} # lowercase
sshUser=${sshUser:='oracle'}

set -u

cat <<-EOF

     nodeBase: $nodeBase
        nodes: $nodes
  workingNode: $workingNode
      sshUser: $sshUser

EOF

for i in $(seq 1  $nodes)
do
	echo creating ${nodeBase}${i}/sa
	mkdir -p ${nodeBase}${i}/sa
done


declare -a nodeList
for i in $(seq 1 $nodes)
do 
	# arrays are zero based - ignoring first element
	# so that node# matches element#
	nodeList[$i]=$i
done

if [[ ! "$workingNode" == 'na' ]]; then
	echo copying local sar
	unset nodeList[$workingNode]
	cp -Hpr /var/log/sa/sa?? ${nodeBase}${workingNode}/sa
fi

for i in ${nodeList[@]}
do
	server="${nodeBase}${i}"

	echo "#####################################"
	echo "## working on $server"
	echo "#####################################"
	ssh "$sshUser@$server" "cd /var/log/sa; tar cfh - sa??" | ( cd "$server"/sa; tar xfv - )

done

