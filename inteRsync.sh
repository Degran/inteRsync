#!/bin/bash

description="inteRsync schedules and manages backups made by rsync.
It is meant to be run at start-up (or periodically) so to remind the user when a new backup should be made. As a secondary task, it also manages the memory occupied by backups. Hard links are used for files that don't change and inteRsync decides what backups to remove when the desired number of versions is exceeded. The retained backups are approximately exponentially spaced, to keep both very recent and very old versions."

my_dir="$(dirname "$0")"
source "$my_dir/src/backupScheduler.sh"


usage="$description""

Usage: $(basename "$0") [-h] [-s n] 

Options
    -h, --help		show this help text
    -s, --source	The folder that will be backed up
    -d, --destination	The folder in which the Backup will be created.
    -f, --stamp		The time stamp file used to date the last backup
    -t, --time		The time interval in seconds.
    -n, --versions	Max number of backup versions to keep.
    -q, --shutdown	Attempt shutdown after completion.
    -o, --options	All options past this identifier are used as rsync options."

# DEFAULTS
shutdown="0"
target="$my_dir"
cntLim="1"
timeDiff="60"
stampFile=""
source=""
options=()

while [[ $# > 0 ]]; do
  key="$1"
  shift

  case $key in
    -h|--help)
    echo "$usage"
    exit 0
    ;;
    -d|--destination)
    target="$1"
    shift
    ;;
    -s|--source)
    source="$1"
    shift
    ;;
    -n|--versions)
    cntLim="$1"
    shift
    ;;
    -t|--time)
    timeDiff="$1"
    shift
    ;;
    -f|--stamp)
    stampFile="$1"
    shift
    ;;
    -q|--shutdown)
    shutdown="1"
    ;;
    -o|--options)
    options="$@"
    break 1
    ;;
    *)
    # unknown option
    echo "$usage"
    exit 0
    ;;
  esac
done

checkSchedule "$shutdown" "$timeDiff" "$cntLim" "$stampFile" "$target" "$source" $options
