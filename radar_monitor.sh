#!/bin/bash
# monitor every period
# usage: ./radar_monitor.sh <n_day> <end_date>; or ./radar_monitor.sh <n_day> -o <offset_hour>

#$1: pwd, $2: $0 of this script
function mydir(){
    local is_begin_slash mydir
    is_begin_slash=$(echo $2 | grep "^/")
    if [ -n "$is_begin_slash" ]; then
        mydir=$(dirname $2)
    else
        mydir="$1"/$(dirname $2)
    fi
    echo $mydir
}
#read args
narg=$#
if [ $narg -eq 2 ]; then
    end_date=$2
    n_day=$1
elif [ $narg -eq 3 ] && [ $2 == "-o" ]; then
    offset_hr=$3
    now=$(date)
    end_date=$(date -d "$offset_hr hour ago" +%Y%m%d)
    n_day=$1
else
    echo "usage 1. $0 <n_day_to_check> <YYYYMMDD>"
    echo "usage 2. $0 <n_day_to_check> -o <offset_hour>"
    exit 2
fi    

source datelib.sh
off_day=$(($n_day - 1))
bgn_date=$(date_add $end_date -$off_day "day")

echo "$(date)-------------------"
echo "to check $bgn_date -- $end_date"

this_dir=$(mydir $(pwd) $0)
pngdir=$this_dir/RADAR_PNGS/
logdir=$this_dir/logs/
test -d $pngdir || mkdir $pngdir
test -d $logdir || mkdir $logdir
test -e $this_dir/content && rm -rf $this_dir/content
echo "Hi: " > $this_dir/content
echo >> $this_dir/content

max_download_try=2
rain_days=""
#only save 30 days (to archive then to delete)
nday_remove=30
date1=$(date_add $end_date -30 "day")
$this_dir/save_archive.sh $pngdir  $date1  archive 1
test -d $pngdir/archive && rm -rf $pngdir/archive

for ((i=0;i<$n_day;i++)); do
    datex=$(date_add $bgn_date $i "day")
    echo "$i $datex ------"
    #download 
    cnt=0
    npng=0
    while [ 1 -eq 1 ]; do
        npng=$(ls $pngdir/$datex/*.png 2>>/dev/null | wc -l)
        lastpng=$(ls $pngdir/$datex/*.png 2>>/dev/null | tail -n 1)
        if [ -e $pngdir/$datex/flag.finish ] || [ $npng -ge 240 ]; then
            echo " Finish downloading, npng=$npng, lastpng=$(basename $lastpng)"
            break
        fi
        if [ $cnt -ge $max_download_try ]; then
            echo " Warn: downloading seems unfinished but max_download_try limitation exceeds"
            break
        fi
        echo " start download ++ "
        $this_dir/download_SZMB_radarpng.sh $datex"0000" $datex"2354" $pngdir/$datex
        cnt=$(($cnt+1))
    done
    echo " $(date) "
    #python check
    echo " start detect (log in $logdir/detect_$datex.txt)"
    logfile=$logdir/detect_$datex.txt
    test -e $logfile && rm -rf $logfile
    for png in $pngdir/$datex/*.png; do
        python $this_dir/radar_detect.py $png &>> $logfile
    done
    echo " $(date) "
    #if one day have RAIN >= 12 png (~2hour), then alert
    n_rain=$(cat $logfile | grep RAIN | grep -v NO | wc -l)
    if [ $n_rain -ge 12 ]; then
        rain_days=$rain_days"$datex "
        echo " $datex has $n_rain times detected as rainny"
        echo " $datex has $n_rain times detected as rainny" >> $this_dir/content
    fi
done
echo >> $this_dir/content
echo  "Robot of sishen(yellowstone)" >> $this_dir/content
#set email
if [ -n "$rain_days" ]; then
    echo "send alert email"
    recipient="shensilasg@gmail.com"
    mailx -s "SZMB Radar Detect Rain" "$recipient" < $this_dir/content
fi
