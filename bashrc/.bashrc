# .bashrc
# LastUpdated 6/21/2015 (the Git history is more reliable)
# Copyright Clive Chan, 2014-present (http://clive.io)
# License: CC BY-SA 4.0(https://creativecommons.org/licenses/by-sa/4.0/)

# Written for Windows. I'm not sure if it works on any other platform.
# Description: Sets up a convenient Git Bash environment. Copy into ~ (C:/Users/You/), and run msysgit.

clear

####### CUSTOMIZABLES #######

# Paths
gitpath=~/github
gitbashrc=$gitpath/misc/bashrc
sshtmp=/tmp/sshagentthing.sh #yes, this is correct. It's a special Unix directory.
PATH=$PATH:/c/MinGW/bin
# perhaps I Should save $PATH here

# Aliases for various repos
alias tbb="cd ~/Desktop/github/2015-4029 && git status"
alias rd="cd ~/Desktop/github/r-d && git status"
alias lhsmath="cd ~/Desktop/github/lhsmath && git status"
# alias hackne="cd ~/Desktop/github/hackne && git status"
# alias scifair="cd ~/Desktop/github/scifair && git status"
# alias lib="cd ~/Desktop/github/lib && git status"
# alias cb="cd ~/Desktop/github/rtwf/calcbee && git status"

# Editor aliases
alias npp="\"C:\Program Files (x86)\Notepad++\notepad++.exe\""
# alias robotc="\"C:\Program Files (x86)\Robomatter Inc\ROBOTC Development Environment 4.X\RobotC.exe\""
# alias sublime="\"C:\Program Files\Sublime Text 3\sublime_text.exe\""


####### CODE #######

# COLORS!
# https://wiki.archlinux.org/index.php/Color_Bash_Prompt
# Regular Colors
export Black='\e[0;30m'        # Black
export Red='\e[0;31m'          # Red
export Green='\e[0;32m'        # Green
export Yellow='\e[0;33m'       # Yellow
export Blue='\e[0;34m'         # Blue
export Purple='\e[0;35m'       # Purple
export Cyan='\e[0;36m'         # Cyan
export White='\e[0;37m'        # White

# Bold
export BBlack='\e[1;30m'       # Black
export BRed='\e[1;31m'         # Red
export BGreen='\e[1;32m'       # Green
export BYellow='\e[1;33m'      # Yellow
export BBlue='\e[1;34m'        # Blue
export BPurple='\e[1;35m'      # Purple
export BCyan='\e[1;36m'        # Cyan
export BWhite='\e[1;37m'       # White

export ColorReset='\e[00m'     # Reset to default

# Title + Version
echo -e $BBlack"Git Bash"
git version
echo

# Gets to the right place
cd $gitpath

# Self-update.
cmp --silent $gitbashrc/.bashrc ~/.bashrc
if [ $? -eq 0 ]; then
	echo ".bashrc is up to date."
elif [ $? -eq 1 ]; then
	echo "Self-updating from $gitbashrc/.bashrc..."
	cp -v $gitbashrc/.bashrc ~/.bashrc
	echo "Done. Restarting Git Bash...";
	echo
	exec bash -l
else
	echo "Error looking for new version. Your \$gitbashrc path ($gitbashrc) may not be correct."
fi

# Makes me sign in with SSH key if necessary; tries to preserve sessions if possible.
# NOTE THAT this agent feature must be disabled to have security. Any application can ask the ssh-agent for stuff.
	# Actually, this may not be true. :/
# For a guide on how to use SSH with GitHub, try https://help.github.com/articles/generating-ssh-keys/
# If something messes up, just remove the starter file and restart the shell with ssh-reset.
# "ssh-agent" returns a bash script that sets global variables, so I store it into a tmp file auto-erased at each reboot.
if [ -f ~/.ssh/id_rsa.pub -a -f ~/.ssh/id_rsa ]; then # Only if we actually have some SSH stuff to do
	ssh-start () { ssh-agent > $sshtmp; . $sshtmp; ssh-add; } # -t 1200 may be added to ssh-agent.
	ssh-end () { rm $sshtmp; kill $SSH_AGENT_PID; }
	ssh-reset () { echo "Resetting SSH agent"; ssh-end; ssh-start; }
	if [ ! -f $sshtmp ]; then # Only do it if daemon doesn't already exist
		echo
		echo "New SSH agent"
		ssh-start
	else # Otherwise, everything is preserved until the ssh-agent process is stopped.
		echo "Reauthenticating SSH agent..."
		. $sshtmp
		if ! ps | grep $SSH_AGENT_PID > /dev/null; then
			echo "No agent with PID $SSH_AGENT_PID is running."
			ssh-reset
		fi
	fi
else
	echo SSH is not currently set up. You might want to do that.
fi

# Git shortforms.
alias ga="git add --all :/"
alias gs="git status" # Laziness.
alias gc="git add --all :/ && git commit" # Stages everything and commits it. You can add -m "asdf" if you want, and it'll apply to "git commit".
gu () { gc "$@"; git push; } # commits things and pushes them. You can use gu -m "asdf", since all arguments to gu are passed to gc.
alias gam="gc --amend --no-edit && git push --force" # Shortform for when you mess up and don't want an extra commit in the history
grp () { br=`git branch | grep "*" | cut -c 3-`; git remote add $1 "git@github.com:$2"; git fetch $1; git push -u $1 $br; }

# Shortform SSH cloning from GitHub and BitBucket
# Use like this: clone-gh cchan/misc
clone-gh () { git clone "git@github.com:$1"; cd `basename $1`; }
gh-clone () { clone-gh $1; }
clone-bb () { git clone "git@bitbucket.org:$1"; cd `basename $1`; }
bb-clone () { clone-bb $1; }

# The amazing git-status-all script, which reports on the status of every repo in the current folder.
gsa () {
	export -f gsa_repodetails
	find -type d -name .git -prune -exec bash -c 'gsa_repodetails "$0"' {} \;
}
gsa_repodetails () {
	cd "$1/..";
	echo "
--------$1--------";
	git remote update >/dev/null &>/dev/null
	git -c color.status=always rev-parse --abbrev-ref HEAD --
	git -c color.status=always status -s
	
	for branch in $(git for-each-ref --sort="-authordate:iso8601" --format="%(refname)" refs/heads/); do
		SHORT=$(basename "$branch")
		
		echo -e -n $BCyan"$SHORT: "$ColorReset
		if [[ -n $(git config --get branch.$SHORT.remote) ]]; then
			LOCAL=$(git rev-parse "$SHORT")
			REMOTE=$(git rev-parse "$SHORT"@{upstream})
			BASE=$(git merge-base "$SHORT" "$SHORT"@{upstream})
			
			if [ $LOCAL = $REMOTE ]; then
				echo -e $BGreen"Up-to-date."$ColorReset
				git log -1 --pretty=format:"LATEST: %ar	%<(50,trunc)%s" $LOCAL --
			elif [ $LOCAL = $BASE ]; then
				echo -e $BRed"Need to pull!"$ColorReset
				git log -1 --pretty=format:"LOCAL: %ar	%<(50,trunc)%s" $LOCAL --
				git log -1 --pretty=format:"REMOTE: %ar	%<(50,trunc)%s" $REMOTE --
			elif [ $REMOTE = $BASE ]; then
				echo -e $BRed"Need to push!"$ColorReset
				git log -1 --pretty=format:"LOCAL: %ar	%<(50,trunc)%s" $LOCAL --
				git log -1 --pretty=format:"REMOTE: %ar	%<(50,trunc)%s" $REMOTE --
			else
				echo -e $BRed"Diverged!!"$ColorReset
				git log -1 --pretty=format:"LOCAL: %ar	%<(50,trunc)%s" $LOCAL --
				git log -1 --pretty=format:"REMOTE: %ar	%<(50,trunc)%s" $REMOTE --
				git log -1 --pretty=format:"MERGE-BASE: %ar	%<(50,trunc)%s" $BASE --
			fi
		else
			echo -e $BYellow"No upstream configured."$ColorReset
			git log -1 --pretty=format:"LATEST: %ar	%<(50,trunc)%s" $SHORT --
		fi
	done

}


# Welcome!
echo
echo Welcome! This is the super-awesome .bashrc file installed in your \~ directory.
echo Sample commands: gs gc gu gsa npp. Try \"notepad ~/.bashrc\" to look at all your aliases and functions.
echo


# https://wiki.archlinux.org/index.php/Color_Bash_Prompt
set_bash_prompt_colors () {
    PS1="\[$Yellow\][\$?] " # Exit status for the last command
    PS1+="\[$Green\]\\u@\\h " # User@Host
    PS1+="\[$Purple\]\w\[\e[m\] " # Path
	PS1+="\[$Cyan\]\$(__git_ps1 '[%s] ')" # Git branch if applicable
	PS1+="\[$Cyan\]\$\[\e[m\] " # Prompt
	PS1+="\[$BWhite\]" # User input color
}
export PROMPT_COMMAND='set_bash_prompt_colors;history -a;history -c;history -r' # https://superuser.com/questions/555310/bash-save-history-without-exit