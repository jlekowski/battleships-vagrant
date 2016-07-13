#!/bin/bash

echo "
:set hlsearch
:set number
" | tee ~/.vimrc

echo "
HISTSIZE=10000
HISTFILESIZE=20000
alias ll='ls -alh'
PS1='\[\033[1;31m\][\[\033[1;32m\]\t\[\033[1;31m\]][\[\033[1;33m\]\u\[\033[1;31m\]@\[\033[1;33m\]\h\[\033[1;31m\]:\[\033[1;36m\]\W\[\033[1;31m\]] \[\033[00m\]$\[\033[00m\] '
" | tee -a ~/.bashrc
