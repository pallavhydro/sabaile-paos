#! /bin/bash                                                                                                                                                                                                                                

# ==============================================                                                                                                                                                                                            
#                                                                                                                                                                                                                                           
# Script to merge ERA5 netcdf files - IN PARALEL!                                                                                                                                                                                           
#                                                                                                                                                                                                                                           
# date 16.10.2021                                                                                                                                                                                                                           
# Pallav Kumar Shrestha                                                                                                                                                                                                                     
#                                                                                                                                                                                                                                           
# ==============================================                                                                                                                                                                                            


set -e

source load_netcdf_0_3.sh # for cdo                                                                                                                                                                                                         


src_path1="/work/shresthp/glob_mhm_basins_mlm2021_era5_1950/" # 1950-1979 data                                                                                                                                                              
src_path2="/work/shresthp/glob_mhm_basins_mlm2021/" # 1980-2018 data                                                                                                                                                                        

vars=("pre" "tavg" "tmin" "tmax" "tdew" "windspeed")




# The function                                                                                                                                                                                                                              

do_merge(){

    domain=$1

    # Prepare folder to store output file                                                                                                                                                                                                   

    if [ -d $src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day" ]; then
        rm -rf $src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day"
    fi
    mkdir -p $src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day"


    # Copy header file                                                                                                                                                                                                                      
    \cp $src_path1"/"$domain"/meteo_era5/meteo_1950_1979_day/header.txt" $src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day"


    # Loop through all 6 variables                                                                                                                                                                                                          

    for ivar in ${vars[@]}; do

        # Generate the file paths to the two source files as well as the output file                                                                                                                                                        

        echo $ivar

        src_file1=$src_path1"/"$domain"/meteo_era5/meteo_1950_1979_day/"$ivar".nc"
        src_file2=$src_path2"/"$domain"/meteo_era5/meteo_1980_2018_day/"$ivar".nc"
        outfile_temp=$src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day/"$ivar"_temp.nc"
        outfile=$src_path1"/"$domain"/meteo_era5/meteo_1950_2018_day/"$ivar".nc"

        # Use cdo timemerge to merge the two files                                                                                                                                                                                          

        cdo -f nc4c -z zip_4 mergetime $src_file1 $src_file2 $outfile_temp

        # Adjust the time stamp to starting from 1950, daily

        cdo settaxis,1950-01-01,00:00:00,1day $outfile_temp $outfile

        # Remove the intermediate file

        rm $outfile_temp


    done # Close the variable loop                                                                                                                                                                                                          

}


# The call                                                                                                                                                                                                                                  

# Loop through all reservoir modeling domains                                                                                                                                                                                               
for idomain in ${src_path2}/*; do

    domain="$( basename -- $idomain )"
    echo $domain

    do_merge "$domain" & 		# This ampersand (&) at the end of the function call parallelizes the idomain loop! 

done # Close the domain loop                                                                                                                                                                                                                


echo "finished"
