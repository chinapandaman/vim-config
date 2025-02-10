rm -rf ~/.vim/
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
cp coc-settings.json ~/.vim/coc-settings.json
cp plugins.vimrc ~/.vimrc
vim -c ":PlugInstall" -c "qa"
mkdir ~/.vim/tmp/
cat plugins.vimrc .vimrc > temp
cp temp ~/.vimrc
rm temp
