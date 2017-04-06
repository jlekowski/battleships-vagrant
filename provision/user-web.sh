#!/bin/bash

gitName=$1
gitEmail=$2
symfonyVarDir=$3

echo "
:set hlsearch
:set number
" | tee ~/.vimrc

echo "
HISTSIZE=10000
HISTFILESIZE=20000
alias ll='ls -alh'
function parse_git_branch () {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1)/'
}
function parse_git_repo() {
    git remote -v 2> /dev/null | sed -e '/push/!d' -e 's/.*\/\(.*\).git .*/(\1: /'
}
PS1='\[\033[1;31m\][\[\033[1;32m\]\t\[\033[1;31m\]][\[\033[1;33m\]\u\[\033[1;31m\]@\[\033[1;33m\]\h\[\033[1;31m\]:\[\033[1;36m\]\W\[\033[1;31m\]]\$(parse_git_repo)\$(parse_git_branch) \[\033[00m\]$\[\033[00m\] '
" | tee -a ~/.bashrc

# for dev vm with shared files (CLI)
if [ $symfonyVarDir ]; then
    echo "SYMFONY__VAR_DIR=$symfonyVarDir" | tee -a ~/.bashrc
    export SYMFONY__VAR_DIR="$symfonyVarDir"
fi

git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
git config --global diff.tool vimdiff
git config --global color.diff auto
git config --global color.status auto
git config --global color.branch auto
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd)%Creset %C(bold blue)<%an>%Creset' --date=relative"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br "branch -vv"
git config --global core.editor vim
git config --global core.pager "less -x4"
git config --global core.autocrlf input
git config --global push.default current
git config --global rebase.autostash true

git config --global core.excludesfile "~/.gitignore"
echo ".idea" | tee -a ~/.gitignore
