main code: radar_monitor.sh
it does routine check for SZMB Radar image check for rain
it does:
1. download_SZMB_radarpng.sh (download the SZMB png everyday)
2. radar_detect.py (using SZMB Radar png to detect whether today i is rain in SZ area)
3. if today there are more than 12 pngs have been detected as rainny (1 png every 6 minutes, one day total 240 pngs), think it is a really rain, send email to me
Note: the criterion for rain is very very simple & preliminary, even not empirical because I have no knowledge about the relation between precipitation & Radar Reflectivity.

other files:
1. datelib.sh: a lib of functions to manipulate dates (in format: YYYYMMDD, YYYYMMDDHH, YYYYMMDDHHmm etc)
2. save_archive.sh: a smart tool to archive date files (move "old" files/dirs to archive dir so that a long list of date files are avoided in one single directory)
3. crontab.add: a crontab script for radar_monitor.sh

