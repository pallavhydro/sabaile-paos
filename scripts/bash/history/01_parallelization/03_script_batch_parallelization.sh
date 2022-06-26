#!/bin/bash

a="accessible to function"


# the function

task(){
   sleep 0.1; echo "$1 a";
}



# The call   

batchpop=10
for thing in {1..100}; do 
   ((i=i%batchpop)); ((i++==0)) && wait
   task "$thing"  &
done
wait


echo "finished"
 
