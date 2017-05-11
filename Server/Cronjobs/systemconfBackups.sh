#! /bin/bash

# This script backs up server's:
# 	crontab
# 	bashrc
#   nginx config from VM, via python script


NOW=$(date +"%m-%d-%Y")
DIR='/home/aelchert/Git/Personal/Backups'
LOGFILE="/home/aelchert/Dropbox/Logs/cronLog.txt"
#EMAIL='7ac1a19215fbf24b575197605f2ae1f8f5fef8ea@api.prowlapp.com'

crontabBackupHash=$(md5sum $DIR/Cron/server_root_crontab | awk '{print $1;}')
crontabHash=$(crontab -u root -l | md5sum | awk '{print $1;}')

bashrcHash=$(md5sum /home/aelchert/.bashrc | awk '{print $1;}')
bashrcBackupHash=$(md5sum /home/aelchert/Git/Personal/Backups/Bash/server_bashrc | awk '{print $1;}')

counter=0

checkFileLength() {
	fileLength=$(cat $logFile | wc -l)
	if [ "$fileLength" -gt "50" ]; then
		echo "" > $logFile
		echo "#################" >> $logFile
		echo "Sys Conf Backups" >> $logfile
		echo "#################" >> $logFile
	fi
}

git_add() {
  cd /home/aelchert/Git/Personal/
  git add -A .
  git commit -m "updates $NOW"
  git push
}

#empties log file after 100 lines
checkFileLength

# run python script for nginx conf
python nginxBackup.py

#checks crontab
if [[ $crontabBackupHash != $crontabHash ]]; then
	crontab -u root -l > $DIR/Cron/server_root_crontab
	printf "++ [systemconfBackups] - Crontab Backup - $NOW" >> $LOGFILE
   counter+=1
fi

#checks if bashrc is backed up
if [[ $bashrcHash != $bashrcBackupHash ]]; then
	cp /home/aelchert/.bashrc $DIR/Bash/server_bashrc
	printf "++ [systemconfBackups] - Bashrc Backup - $NOW" >> $LOGFILE
   	counter+=1
fi

######
# If anything is updated, push it to GIT
#####

if [[ $counter -ge 1 ]]; then
	git_add
	printf "++ [systemconfBackups] - Sysconf Backup Complete w/ Git add- $NOW" >> $LOGFILE
else
	printf "++ [systemconfBackups] - No Updates- $NOW" >> $LOGFILE
	printf "++ [systemconfBackups] - Sysconf Backup Complete - $NOW" >> $LOGFILE
fi
