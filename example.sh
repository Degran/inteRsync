#!/bin/bash
#

# This script is run at startup

gnome-terminal -t 'Rsync scheduled backup - Monthly Toshiba' -e "nice -10 /home/Scripts/BackupScript/inteRsync/inteRsync.sh -t $((60*60*24*30)) --shutdown ask -n 4 -f '/home/Scripts/BackupScript/MonthlyToshibaStamp' -d '/media/TOSHIBA EXT/BACKUP' -s / --options -g -o -p -t -R -u -v --inplace --delete-excluded -r -l --exclude=/media --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/dev"
