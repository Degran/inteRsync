# Checks a timestamp file to see if another backup should be scheduled.
# If so, it also verifies that the target and source folders are accessible.
# This is to notify the user when external storage needs to be connected beforehand.

my_dir="$(dirname "$0")"
source "$my_dir/src/backupManager.sh"

function checkSchedule {
  local super=$1
  local timeDiff=$2
  local cntLim=$3
  local stampFile=$4
  local target=$5
  local source=$6
  shift 6

  # Get times
  local now=$(date +%s)
  local last=0
  if [ -f "$stampFile" ]; then
    last=$(date --reference="$stampFile" +%s)
  fi

  # Compare times
  if [ $timeDiff -lt $(($now - $last)) ]; then
    # Wait until the source directory exists	
    while [ ! -d "$source" ]; do
      echo "$source"
      echo 'source directory not found. Press any key to continue'
      read -n 1 -s -t 300
    done
	
    # Wait until the target directory exists	
    while [ ! -d "$target" ]; do
      echo "$target"
      echo 'destination directory not found. Press any key to continue'
      read -n 1 -s -t 300
    done
	
    # Create the backup
    echo "Backup is ready to begin."
    read -n 1 -s
    echo "Backup started at ""$(date)"
    echo "Backup is running ..."
	
    backup "$super" "$timeDiff" "$cntLim" "$target" "$source" "$@"
	
    # Update the timestamp
    touch "$stampFile"

    echo "Backup terminated on ""$(date)"
    read -n 1 -s

  fi
}
