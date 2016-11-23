#!/bin/bash
# ./save_archive <dir to archive> <date, equal to or before which is to archive> <archive dir> <archive depth, 1 or 2>
# archive automatically in forms : <archive dir>/{yyyymm,yyyymm/dd}/<original_files>
# note: 1. only files/dirs whose names containing 2YYYMMDD, 2YYYMMDDHH, 2YYYMMDDHHmm are recognized, and only one of the forms exist
#       2. can not run on Mac OS, only Linux (due to date command difference between Mac & Linux)

declare -a datefiles 
declare -a filedates
ans_ls_datefiles="" #will be modified in ls_datefiles
#get datefiles (array) & filedates (array): global vars
function ls_datefiles(){
    local cnt files12 files10 files08 file
    cnt=0
    files12=$(ls | egrep 2[[:digit:]]\{11,11\}) #2YYYMMDDHHmm
    if [ -n "$files12" ]; then
        for file in $files12; do
            datefiles[$cnt]=$file
            filedates[$cnt]=$(echo $file | sed 's/.*\(2[0-9]\{11,11\}\).*/\1/g')
            cnt=$(($cnt+1))
        done
        return
    fi
    files10=$(ls | egrep 2[[:digit:]]\{9,9\} )  #2YYYMMDDHH
    if [ -n "$files10" ]; then
        for file in $files10; do
            datefiles[$cnt]=$file
            filedates[$cnt]=$(echo $file | sed 's/.*\(2[0-9]\{9,9\}\).*/\1/g')
            cnt=$(($cnt+1))
        done
        return
    fi
    files08=$(ls | egrep 2[[:digit:]]\{7,7\})  #2YYYMMDD
    if [ -n "$files08" ]; then
        for file in $files08; do
            datefiles[$cnt]=$file
            filedates[$cnt]=$(echo $file | sed 's/.*\(2[0-9]\{7,7\}\).*/\1/g')
            cnt=$(($cnt+1))
        done
        return
    fi
    ans_ls_datefiles="Fail"
}

#date as YYYYMMDD / YYYYMMDDHH / YYYYMMDDHHmm
function date_to_second() {
    local xdate sec yr mo dy hr mn
    xdate=$1
    yr=$(echo $xdate | cut -c 1-4)
    mo=$(echo $xdate | cut -c 5-6)
    dy=$(echo $xdate | cut -c 7-8)
    hr=$(echo $xdate | cut -c 9-10)
    mn=$(echo $xdate | cut -c 11-12)
    if [ ${#xdate} -eq 8 ]; then
        sec=$(date -d "$yr$mo$dy 00:00:00" +%s) 
    elif [ ${#xdate} -eq 10 ]; then
        sec=$(date -d "$yr$mo$dy $hr:00:00" +%s)
    elif [ ${#xdate} -eq 12 ]; then
        sec=$(date -d "$yr$mo$dy $hr:$mn:00" +%s)
    else 
        echo "Fail"
        return
    fi
    if [ $? -ne 0 ]; then
        echo "Fail"
    fi
    echo $sec
}
        


# read args
narg=$#
if [ $narg -ne 4 ]; then
    echo "$0  <dir to archive>  <date: before which to archive> <archive dir name> <archive depth, 1/2>"
    exit 2
fi
dir=$1
maxdate=$2
if [ ${#maxdate} -ne 8 ] && [ ${#maxdate} -ne 10 ] && [ ${#maxdate} -ne 12 ]; then
    echo "2nd parameter: date should be one of the forms: YYYYMMDD, YYYYMMDDHH, YYYYMMDDHHmm"
    exit 2
fi    
output_dir=$3
depth=$4
if [ $depth -ne 1 ] && [ $depth -ne 2 ]; then
    echo "depth should be either 1 (yyyymm) or 2 (yyyymm/dd)"
    exit 2
fi

#
sec_max_date=$(date_to_second $maxdate)
if [ "$sec_max_date" == "Fail" ]; then
    echo "Fail to recogize 2nd parameter: max_date"
    exit 2
fi

cd $dir
ls_datefiles
res=$ans_ls_datefiles
if [ "$res" == "Fail" ]; then
    echo "Warn: No 2YYYMMDDHH or 2YYYMMDDHHmm or 2YYYHHDD file/dir is found!"
    exit 2
fi
nfile=${#datefiles[@]}
if [ "$nfile" -le 0 ]; then
    echo "Warn: nfile == 0"
    exit 2
fi
for ((i=0;i<$nfile;i++)); do
    xsec=$(date_to_second ${filedates[$i]})
    if [ "$xsec" == "Fail" ]; then
        echo "Fail to recognized: ${filedates[$i]} from ${datefiles[$i]}"
        exit 2
    fi
    if [ $xsec -le $sec_max_date ]; then
        yrmo=$(echo ${filedates[$i]} | cut -c 1-6)
        dy=$(echo ${filedates[$i]} | cut -c 7-8)
        if [ $depth -eq 1 ]; then
            test -d $output_dir/$yrmo || mkdir -p $output_dir/$yrmo
            mv ${datefiles[$i]} $output_dir/$yrmo/
        elif [ $depth -eq 2 ]; then
            test -d $output_dir/$yrmo/$dy || mkdir -p $output_dir/$yrmo/$dy
            mv ${datefiles[$i]} $output_dir/$yrmo/$dy/
        fi
    fi
done    
