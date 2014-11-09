# First selects a previous backup version to overwrite, if applicable,
# and then has rsync perform the actual copying,
# with the latest backup as a reference for hard links.

my_dir="$(dirname "$0")"
source "$my_dir/src/backupCostFunction.sh"

function backup {
  local timeDiff=$1
  local cntLim=$2
  local target=$3
  local source=$4
  shift 4
  
  # Scan the target folder for old backup versions
  local refdir=""
  local verList=()
  local intrList=()
  local cnt=0
  for version in "$target"/Backup_????-??-??__??-??-??__*; do
    if [[ $version == *\?* ]]; then
      # No previous backup versions in the target folder
      break 1
    fi

    verList=("$version" "${verList[@]}")
    cnt=$(( cnt+1 ))

    # Retrieve the time interval since backup, based on the folder name 
    local start="${version/*Backup_/}"
    local day="${start/__??-??-??__*/}"
    local time="${start/????-??-??__/}"
    time="${time/__*/}"
    time="${time//-/:}"
    local sec=$(date -d"$day"T"$time" +%s)
    local now=$(date +%s)

    local roundedInterval=$(( $now-$sec ))
    if [ "$timeDiff" -ne "0" ]; then 
      # Add half of the denominator to the numerator to round to the nearest integer.
      # Since the denominator is not necessarily even, 
      # multiply both the original numerator and the original denominator by 2 and then add.
      roundedInterval=$(( (2*$roundedInterval+$timeDiff)/(2*$timeDiff) ))
    fi
    intrList=("$roundedInterval" "${intrList[@]}")
    refdir="$version"
  done

  # Also add the process id to the names to distinguish
  # between backups that finish the same second.
  local path="$target"/"Backup__""$$"
  # if there will be too many backup versions, select one to overwrite
  if [ "$cntLim" -le "$cnt" ]; then
    argList=(0 "${intrList[@]}")
    deleteForSpread 0 "${argList[@]}"
    local index=$?
    # Assuming the newest backup won't be selected for removal.
    index=$(( index-1 ))
    
    # For concurrency reasons, the version to overwrite is renamed.
    mv "${verList[$index]}" "$path"

    # Remove that entry from the lists
    verList=(${verList[@]:0:$index} ${verList[@]:$(( $index + 1 ))})
    intrList=(${intrList[@]:0:$index} ${intrList[@]:$(( $index + 1 ))})
  else
    mkdir "$path"
  fi

  # Run rsync
  local options="$@"
  if [ -d "$refdir" ]; then
    rsync $options --link-dest="$refdir" "$source" "$path"
  else
    rsync $options "$source" "$path"
  fi

  # Name the created directory according to the current time
  local newSubdir=$(date +%F__%H-%M-%S)
  newSubdir="Backup_""$newSubdir""__""$$"
  local newPath="$target"/"$newSubdir"
  mv "$path" "$newPath"

  # Remove more versions if there are still too many
  verList=("$newPath" "${verList[@]}")
  intrList=("0" "${intrList[@]}")
  local n="$cnt"
  while [ "$cntLim" -lt "$n" ]; do
    deleteForSpread 0 "${intrList[@]}"
    local index=$?
    
    rm -rf "${verList[$index]}"

    # Remove that entry from the lists
    verList=(${verList[@]:0:$index} ${verList[@]:$(( $index + 1 ))})
    intrList=(${intrList[@]:0:$index} ${intrList[@]:$(( $index + 1 ))})

    n=$(( n - 1 ))
  done

  return 0
}
