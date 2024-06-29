#!/bin/bash
#checking the arguments
oldsettings=$(stty -g)
case $# in
   0) dir=. ;;
   1) dir=$1 ;;
   *) echo "Usage: showDir [ dir-name ]" >&2
      exit 1 ;;
esac
#check if the directory is a valid directory
if [ ! -d $dir ]
   then echo "showDir: $1 is not a valid directory name" >&2
        exit 1
fi
#print the headers
tput reset
printf "%-8s%-8s%-8s%-11s\n" "Owner" "Group" "Other" "Filename"
printf "%-8s%-8s%-8s%-11s\n" "-----" "-----" "-----" "--------"
#find the absolute path
cd $dir
printf %s "/" > /tmp/showDir.temp.$$
echo $PWD | tr '/' ' ' >> /tmp/showDir.temp.$$
exec 4< /tmp/showDir.temp.$$
read path <&4
exec 4<&-
#loop through each level in the absolute path, starting at root
currlvl=0
filecol=24
key=
while [ "$key" != 'q' ]
do
  if [[ $currlvl = 0 ]]
  then
    for subdir in $path
    do
      cd $subdir
      result=$(ls -ald $PWD | cut -d' ' -f1)
      first=$(echo $result | cut -c2-4 | sed 's/./& /g')
      second=$(echo $result | cut -c5-7 | sed 's/./& /g ')
      third=$(echo $result | cut -c8-10 | sed 's/./& /g ')
      echo $first"  "$second"  "$third"  "$subdir
      #increase the level after every line printed
      currlvl=$((currlvl+2))
      printf "\n"
    done
    #print details for the last directory
    dir_links=$(ls -ald $PWD | cut -d' ' -f2)
    dir_owner=$(ls -ald $PWD | cut -d' ' -f3)
    dir_group=$(ls -ald $PWD | cut -d' ' -f4)
    dir_size=$(ls -ald $PWD | cut -d' ' -f5)
    dir_modified=$(ls -ald $PWD | cut -d' ' -f6,7,8)
    echo "  Links: $dir_links  Owner: $dir_owner  Group: $dir_group"
    echo "Size: $dir_size Modified: $dir_modified"
    filetotal=$currlvl #total number of lines
    #print the bottom
    tput cup 44 0
    echo "Valid keys: k (up), j (down) : move between Dir_Names"
    echo "            h (left), l (right) : move between permissions"
    echo "            r, w, x, -: change permission;"
    echo "q : quit"
  fi
  tput cup $currlvl $filecol
  #get user input
  stty -icanon min 1 -icrnl -echo
  key=$(dd bs=3 count=1 2> /dev/null)
  if [ "$key" = 'k' ] ; then #going up
    if [[ $currlvl > 1 ]]; then
      currlvl=$((currlvl - 2))
      tput kcuu1
    fi
  fi
  if [ "$key" = 'j' ] ; then #going down
    if [[ $currlvl < $filetotal ]] ; then
      currlvl=$((currlvl + 2))
      tput kcud1
    fi
  fi
  if [ "$key" = 'h' ] ; then #going left
    if [[ $filecol > 1 ]] ; then
      filecol=$((filecol - 2))
      tput kcub1
    fi
  fi
  if [ "$key" = 'l' ] ; then #going right
    if [[ $filecol < 35 ]] ; then
      filecol=$((filecol + 2))
      tput kcuf1
    fi
  fi
done
clear
stty $oldsettings
rm /tmp/showDir.temp.$$
