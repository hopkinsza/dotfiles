#!/bin/sh
# .profile

# path
PATH=$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/games
PATH=$PATH:/usr/pkg/bin:/usr/pkg/sbin
PATH=$PATH:/usr/local/bin:/usr/local/sbin
export PATH

# editor, pager
export VISUAL=vim
export EDITOR=$VISUAL
export FCEDIT=$VISUAL

export PAGER=less
export LESSHISTFILE='-'

# lang
export LANG=C.UTF-8

# file executed for every new sh(1) or ksh(1)
export ENV=$HOME/.shrc
