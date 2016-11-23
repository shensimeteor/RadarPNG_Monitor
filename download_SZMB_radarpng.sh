#!/bin/bash
# ./download_SZMB_radarpng.sh <begin_date, YYYYMMDDhhmm> <end_date, YYYYMMDDhhmm> <output_dir>
narg=$#
if [ $narg -eq 3 ]; then
    begin_datetime=$1
    end_datetime=$2
    dir_output=$3
else
    echo "<Usage>: $0 <begin_date, YYYYMMDDhhmm> <end_date, YYYYMMDDhhmm> <output_dir>"
    exit 2
fi    

date_begin=$(echo $begin_datetime | cut -c 1-8)
time_begin=$(echo $begin_datetime | cut -c 9-12)
date_end=$(echo $end_datetime | cut -c 1-8)
time_end=$(echo $end_datetime | cut -c 9-12)

#outputdir
test -d $dir_output || mkdir -p $dir_output

interval_minutes=6

function get_datetime_str(){
    local xdate=$1
    local xtime=$2
    local str=$xdate" "$(echo $xtime | cut -c 1-2)":"$(echo $xtime | cut -c 3-4)
    echo $str
}

function get_datetime_diffminutes(){
    local str_dt1=$1
    local str_dt2=$2
    local sec1=$(date +%s -d "$str_dt1")
    local sec2=$(date +%s -d "$str_dt2")
    local diff_secs=$(($sec1-$sec2))
    local diff_minutes=$(($diff_secs / 60))
    echo $diff_minutes
}

datetime_begin=$(get_datetime_str $date_begin $time_begin)
datetime_end=$(get_datetime_str $date_end $time_end)
#echo "begin_date = $datetime_begin"
#echo "end_date = $datetime_end"
diff_minutes=$(get_datetime_diffminutes "$datetime_end" "$datetime_begin")
#echo "total_hours = $(($diff_minutes / 60))"
n_time=$(($diff_minutes / $interval_minutes))
#echo "n_figures = $(($n_time + 1))"

#echo "begin download"
dt=$datetime_begin
cd $dir_output
for ((i=0;i<=$n_time;i++)); do
    yyyymm=$(echo "$dt" | cut -c 1-6)
    yyyymmdd=$(echo "$dt" | cut -c 1-8)
    hhmm=$(echo "$dt" | cut -d ' ' -f 2 | cut -d ':' -f 1)$(echo "$dt" | cut -d ' ' -f 2 | cut -d ':' -f 2)
    yyyymmddhhmm=$yyyymmdd$hhmm
    url="http://www.szmb.gov.cn/data_cache/pictures/radarForSzmb/gd/$yyyymm/$yyyymmdd/$yyyymmddhhmm.png"
    wget $url &>> log.wget
    dt=$(date -d "$dt $interval_minutes minutes" +"%Y%m%d %H:%M")
done
touch flag.finish
