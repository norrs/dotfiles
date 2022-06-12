# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=400000000
HISTFILESIZE=$(( HISTSIZE * 2 ))

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

[ -f /usr/lib/git-core/git-sh-prompt ] && {
 source /usr/lib/git-core/git-sh-prompt
 GIT_PS1_SHOWDIRTYSTATE=1
 GIT_PS1_SHOWUPSTREAM="auto"
 GIT_PS1_SHOWCOLORHINTS=1
 # Prompt is enabled in PROMPT_COMMAND below.
}

set_window_title() {
    echo -ne "\033]0;"$@"\007"
}

function source_directory_files {
	for filename in "$1"/*; do
		#environment_variable_exists SHELL_STARTUP_DEBUG && echo "Sourcing $filename"
                source "$filename"
	done
}

source_directory_files "$HOME/.lib/shellenv"
source_directory_files "$HOME/.lib/shellrc"


#KUBE_PS1_BG_COLOR=cyan
#KUBE_PS1_NS_COLOR=black
source ~/.opt/kube-ps1/kube-ps1.sh
source ~/.bash.d/colors
source ~/.bash.d/gcloud


if [ "$color_prompt" = yes ]; then
  MY_PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
else
  MY_PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w'
fi

unset color_prompt force_color_prompt

pwd_short() {
    # How many characters of the $PWD should be kept
    local pwdmaxlen=25
    # Indicate that there has been dir truncation
    local trunc_symbol=".."
    local dir=${PWD##*/}
    pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi
    echo "$NEW_PWD"
}

virtualenv_ps1() {
   #local V_PS1="$(basename \"$(VIRTUAL_ENV)\")"
   [ -n "${VIRTUAL_ENV_DISABLE_PROMPT-}" ] && return
   local V_PS1="${VIRTUAL_ENV##*/}"
   if [ -n "$V_PS1" ]; then
     #local pyglyph=\\uf820 # py
     local pyglyph=\\ue235 # python-logo
     echo -ne "(${pyglyph}${V_PS1})"
   fi
}

# Research status bar later...
#CSI=$'\e'"["
#MY_STATUS="\[${CSI}s${CSI}1;$((LINES-1))r${CSI}$LINES;1f\u:YourOutputGoesHere:\w${CSI}K${CSI}u\]>"


PROMPT_COMMAND='history -a;_kube_ps1_update_cache;:;VPS1=$(virtualenv_ps1; printf x);KPS1=$(kube_ps1; printf x);__git_ps1 "$(__gcloud_ps1)${KPS1%x}${VPS1%x}${MY_PS1}" "\\\$ "; set_window_title "$USER@$HOSTNAME:" $(pwd_short)'


# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias colortest='( x=`tput op` y=`printf %$((${COLUMNS}-6))s`;for i in {0..256};do o=00$i;echo -e ${o:${#o}-3:3} `tput setaf $i;tput setab $i`${y// /=}$x;done; )'

if [[ $HOSTNAME == "luna" ]]
then
	xmodmap -e "keycode 36 = KP_Enter"
	xmodmap -e "keycode 104 = Return"
fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash.d/aliases ]; then
    . ~/.bash.d/aliases
fi
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

for complete_file in $HOME/.bash.d/autocomplete/*; do
  source "$complete_file"
done

[[ -e "$HOME/.pathrc" ]] && source $HOME/.pathrc

eval "$(rbenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

