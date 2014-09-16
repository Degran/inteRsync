# The cost function to decide what previous backup version should be overwritten.

# This value determines how many steps ahead the cost function must look to determine
# the backup to remove.
# In an ideal scenario, the backups are spaced exponentially.
# The cost of removing a backup is the difference of the resulting spacing
# with exponential spacing, plus the minimal cost of spacings after
# a STEPCOUNT number of next backups.
# This is similar to an AI determining the best move in a game
STEPCOUNT=1
# This global variable is used to pass the cost of the best backup to remove.
# It facilitates the iterative calculation of costs caused by the steps
MINCOST=0

function cost {
  local step=$1
  local src=("$@"); src=(${src[@]:1})
  
  # The ideal spread is with exponential intervals,
  # so if a backup was just made, 0 2 6 14
  local n=${#src[*]}
  local total=0
  local i
  for (( i=1; i<$n; i++ ))
  do
    local intr=$((${src[$i]}-${src[$i-1]}))
    local r=$((2**($i)))
    local diff=$(($intr-$r))
    total=$(($total+$diff*$diff))
  done
  
  # Calculate the cost after subsequent backups
  if [ "$step" -lt "$STEPCOUNT" ];
  then
    local i
    for (( i=0; i<$n; i++ )); do local next[$i+1]=$((src[$i]+1)); done
    local next[0]=0
    
    deleteForSpread $(($step + 1)) "${next[@]}"
    total=$(($total + $MINCOST))
  fi
  
  #echo "${src[@]}"
  #echo $total
  return $total
}

function deleteForSpread {
  local step=$1
  local src=("$@"); src=(${src[@]:1})
  local n=${#src[*]}
  
  local minCost=-1
  local bestIndex=-1
  local i
  for (( i=1; i<$n; i++ ))
  do
    local deleted=("${src[@]}")
    unset deleted[$i]
    
    cost $step "${deleted[@]}"
    local curCost=$?
    if [ "$bestIndex" -eq "-1" ] || [ "$curCost" -lt "$minCost" ];
    then
      minCost=$curCost
      bestIndex=$i
    fi
  done
  
  MINCOST=$minCost
  return $bestIndex
}
