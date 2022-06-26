#!/bin/bash

a="accessible to function"

task(){
   sleep 0.1; echo "$1-$2";
}


core(){
   
   k=$1
   batchpop=10
   for thing in {1..100}; do 
	((i=i%batchpop)); ((i++==0)) && wait
	task "$thing" "$k" &
   done
   wait
}


# main call

for j in {1..10}; do

   core "$j" &   

done
wait

echo "finished"
 
