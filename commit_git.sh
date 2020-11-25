#!/bin/bash

help_exit()
{
   echo ""
   echo "Usage: $0 -s [mode] -m [msg-require] -p [path] -l [link]"
   echo -e "\t-s  mode: [DEFAULT]: ignore \n\t\tall - all file, \n\t\tignore - ignore files in .gitignore, \n\t\tset - specific path"
   echo -e "\t-m msg: commit message"
   echo -e "\t-p path: file locations to be added [DEFALT]: [work_dir]"
   echo -e "\t-l link: github link [DEFAULT]: https://github.com/mtbui2010/kpick.git"
   echo -e "\t-r remove_git: [DEFAULT]: remove_git"
   exit 1 
}

while getopts "s:m:p:l:r:" opt
do
   case "$opt" in
      s ) mode="$OPTARG";;
      m ) msg="$OPTARG" ;;
      p ) path="$OPTARG" ;;
      l ) link="$OPTARG";;
      r)  remove_git="$OPTARG";;
      ? ) help_exit ;;
   esac
done

if [ -z "$msg" ]	# must input massage
then
   echo "Some or all of the parameters are empty";
   help_exit
fi
if [ -z "$mode" ]
then
   mode="ignore"
fi
if [ -z "$path" ]
then
   path="."
fi
if [ -z "$link" ]
then
   link="https://github.com/mtbui2010/kpick.git"
fi
if [ -z "$remove_git" ]
then
   remove_git="keep_git"
fi



echo $mode
echo $msg
echo $path
echo $link
echo $remove_git

if [ "$remove_git" == "remove_git" ]; then rm -rf .git
fi
git init

if [ "$mode" == "all" ]; then git add .
elif [ "$mode" == "set" ]; then git add "$path"
else git add . .gitignore
fi
git commit -m "$msg"
git remote add origin "$link"
git push --force origin master 
