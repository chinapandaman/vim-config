mkdir -p ~/.vim/spell/
mv ~/.vim/spell/ ./spell/
rm -rf ~/.vim/
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
cp coc-settings.json ~/.vim/coc-settings.json
cp plugins.vimrc ~/.vimrc
vim -c ":PlugInstall" -c "qa"
mkdir ~/.vim/tmp/
cat plugins.vimrc .vimrc git.vimrc grep.vimrc coc.vimrc > temp
cp temp ~/.vimrc
rm temp
mv ./spell/ ~/.vim/spell/
