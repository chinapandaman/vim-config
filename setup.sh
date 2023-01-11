rm -rf ~/.vim/
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
cp .vimrc ~/.vimrc
cp coc-settings.json ~/.vim/coc-settings.json
vim +PlugInstall +qa
vim +CocInstall coc-jedi +qa
