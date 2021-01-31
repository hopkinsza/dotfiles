# .kshrc

# loksh/mksh; enable histfile:
#export HISTFILE=~/.history_ksh
alias ls='ls --color=auto'
alias ll='ls -laF'
alias grep='grep --color=auto'
alias f='clear'
alias v=$VISUAL
alias cx='chmod u+x'
set -o vi
notes () {
	${VISUAL:-${EDITOR:-vi}} $HOME/.notes
}

# prompt
if [ "$ZSH_VERSION" -o "$KSH_VERSION" -o "$BASH_VERSION" ]; then
	if [ "$ZSH_VERSION" ]; then
		set -o prompt_subst
		PS1='%F{green}[%n %f%F{blue}%B%20<*<%~%<<%b%f%F{green}]%f'\
'%(0?.%F{green}$%f.%F{red}$%f) '
		RPS1='%F{yellow}$('
		RPS1+='[[ $PWD = $HOME/git/* ]] && echo '
		RPS1+='"[$(git branch --show-current)$([ -n "$(git status -s)" ] && echo "%F{red}!%F{yellow}")]"'
		RPS1+=')%f'
	elif [[ "$KSH_VERSION" = *MIRBSD* ]]; then
		# mksh
		PS1=$'\1\r\1\e[00;32m\1[frey \1\e[01;34m\1${|
			typeset e=$?
			if [[ "$SH_GIT" = y && $PWD = $HOME/git/* ]]; then
				REPLY+=${PWD##*/}:
				REPLY+="\1\e[00;33m\1"
				REPLY+=$(git branch --show-current)
				REPLY+=$([ -n "$(git status -s)" ] && print "\1\e[00;31m\1!!")
			else
				REPLY+=${PWD/\\/home\\/frey/\\~}
			fi
			REPLY+="\1\e[00;32m\1"
			return $e
		}]\1$([ $? = 0 ] && print "\033[32m" || print "\033[31m")\1$ \1\e[00m\1'
	elif [[ "$KSH_VERSION" = *PD\ KSH* || -n "$BASH_VERSION" ]]; then
		# OpenBSD ksh or bash
		gr='\[\033[32m\]'
		bl='\[\033[01;34m\]'
		rs='\[\033[00m\]'

		PS1="$gr[\u $bl\w$rs$gr]"'\[`[ $? = 0 ] && printf "\033[32m" || printf "\033[31m"`\]\$ '"$rs"
		unset gr bl rs
	fi
else
	# other: simpler prompt
	PS1="[`whoami` "'`case $? in 0) ;; *) echo "e:$? " ;; esac`$(basename $PWD)]$ '
fi
