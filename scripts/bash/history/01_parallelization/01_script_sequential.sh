#!/bin/bash

a="accessible to function"



# The function

task(){
   sleep 0.1; echo "$1 a";
}




# The call

for thing in {1..100}; do 
   
   task "$thing"

done


echo "finished"
 
