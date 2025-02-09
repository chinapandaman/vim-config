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
    Plug 'morhetz/gruvbox'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'dense-analysis/ale'
    Plug '907th/vim-auto-save'
    Plug 'pedrohdz/vim-yaml-folds'
    Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }
call plug#end()

" general settings and theme related
syntax on
set number
set relativenumber
set background=dark
set hlsearch
set termguicolors
set backspace=indent,eol,start
colo gruvbox
let g:airline_powerline_fonts = 1
let g:auto_save = 1
set directory^=$HOME/.vim/tmp//
autocmd FileType markdown setlocal spell
autocmd VimEnter * highlight SpellBad ctermfg=black ctermbg=green

" indent guides
let g:indent_guides_enable_on_vim_startup = 1

" rainbow brackets
let g:rainbow_active = 1

" fzf related
nnoremap <S-f> :Ag<CR>
nnoremap <Leader>f :Files<CR>
nnoremap <Leader>ag :Ag <C-R><C-W><CR>
let g:fzf_layout = { 'down':  '35%'}
set timeoutlen=1000 ttimeoutlen=0

" tabs
let g:airline#extensions#tabline#enabled = 1
nnoremap <Tab> :bn<CR>
nnoremap <S-Tab> :bp<CR>

" split and navigations
set splitright
nnoremap <Leader>s :vsp %<CR>
nnoremap <Up> :wincmd k<CR>
nnoremap <Down> :wincmd j<CR>
nnoremap <Left> :wincmd h<CR>
nnoremap <Right> :wincmd l<CR>

" buffer bye
nnoremap <Leader>q :Bdelete<CR>

" nerdtree and tagbar
nnoremap <Leader>m :TagbarToggle<CR> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let g:tagbar_sort=0

" git related
nnoremap <Leader>gd :Gvdiff<CR>
nnoremap <Leader>gs :Git status<CR>
nnoremap <Leader>gb :Git branch<CR>

" ale
let g:ale_linters={
\   'python': ['pylint'],
\}
highlight ALEError cterm=underline
highlight ALEWarning cterm=underline

" YAML related
function! YAMLTree()
    if (&filetype != 'yaml')
        return
    endif
    let l:list = []
    let l:cur = getcurpos()[1]
    " Retrieve the current line indentation
    let l:indent = indent(l:cur) + 1
    " Loop from the cursor position to the top of the file
    for l:n in reverse(range(1, l:cur))
        let l:i = indent(l:n)
        let l:line = getline(l:n)
        let l:key = substitute(l:line, '^\s*-\?\s*\(["'']\?\([a-zA-Z0-9_.-]\+\)["'']\?\)\s*:\s*.*', "\\1", '')
        " If the indentation decreased and the pattern matched
        if (l:i < l:indent && l:key !=# l:line)
            let l:list = add(l:list, l:key)
            let l:indent = l:i
        endif
    endfor
    let l:list = reverse(l:list)
    echo join(l:list, ' -> ')
endfunction

autocmd CursorMoved * call YAMLTree()
set foldlevelstart=20

" hotkeys
vnoremap <Leader>cp "+y
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
nnoremap <Leader>ra :%s//

" coc
"
" May need for Vim (not Neovim) since coc.nvim calculates byte offset by count
" utf-8 byte sequence
set encoding=utf-8
" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
" delays and poor user experience
set updatetime=300

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
inoremap <silent><expr> <TAB>
    \ coc#pum#visible() ? coc#pum#next(1) :
    \ CheckBackspace() ? "\<Tab>" :
    \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" GoTo code navigation
nmap gd <Plug>(coc-definition)
nmap gy <Plug>(coc-type-definition)
nmap gi <Plug>(coc-implementation)
nmap gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')
autocmd VimEnter * highlight CocHighlightText ctermfg=White ctermbg=Blue

" Errors highlighting
highlight CocErrorHighlight cterm=underline
highlight CocWarningHighlight cterm=underline

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Remap keys for applying refactor code actions
nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
