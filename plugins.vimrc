" plugins
call plug#begin()
    Plug 'jiangmiao/auto-pairs'
    Plug 'vim-airline/vim-airline'
    Plug 'nathanaelkane/vim-indent-guides'
    Plug 'luochen1990/rainbow'
    Plug 'tpope/vim-fugitive'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-sleuth'
    Plug 'scrooloose/nerdtree'
    Plug 'majutsushi/tagbar'
    Plug 'moll/vim-bbye'
    Plug 'danilo-augusto/vim-afterglow'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'dense-analysis/ale'
    Plug '907th/vim-auto-save'
    Plug 'pedrohdz/vim-yaml-folds'
    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }
call plug#end()

