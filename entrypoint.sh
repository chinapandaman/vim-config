#!/bin/sh
set -e

vim_commands='
  :CocInstall coc-highlight
  :CocInstall coc-jedi
  :CocInstall coc-go
  :qa
'

vim -c "$vim_commands"
exec vim "$@"
