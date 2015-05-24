# Checks a timestamp file to see if another backup should be scheduled.
# If so, it also verifies that the target and source folders are accessible.
# This is to notify the user when external storage needs to be connected beforehand.

my_dir="$(dirname "$0")"
source "$my_dir/src/backupManager.sh"

function checkSchedule {
  local super=$1
  local shutdown=$2
  local timeDiff=$3
  local cntLim=$4
  local stampFile=$5
  local target=$6
  local source=$7
  shift 7

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
    
    # Prevents sudo from forgetting the password.
    # Necessary for shutting down after a really long backup.
    # https://gist.github.com/cowboy/3118588
    if [ "$shutdown" -eq "1" ]; then
      # Might as well ask for password up-front, right?
      sudo -v
 
      # Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
      while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
    
    echo "Backup started at ""$(date)"
    echo "Backup is running ..."
	
    backup "$super" "$timeDiff" "$cntLim" "$target" "$source" "$@"
	
    # Update the timestamp
    touch "$stampFile"

    echo "Backup terminated on ""$(date)"
    
    if [ "$shutdown" -eq "1" ]; then
      if [ "$super" -eq "1" ]; then
        sudo shutdown -h now
      else
        shutdown -h now
      fi
    else
      read -n 1 -s
    fi

  fi
}
