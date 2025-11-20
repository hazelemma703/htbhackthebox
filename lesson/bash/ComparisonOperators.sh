#!/bin/bash

var="8dm7KsjU28B7v621Jls"
value="ERmFRMVZ0U2paTlJYTkxDZz09Cg"

for i in {1..40}
do
        var=$(echo $var | base64)
	len=$(echo -n $var | wc -m)
	echo $len
		#<---- If condition here:
	if [[ "$var" == "$value" && "len" -gt 113450 ]]
	then
		echo $var | tail -c 20
		break
	else
		echo $var | tail -c 20
	fi
done
