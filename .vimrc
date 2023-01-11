" plugins
call plug#begin()
    Plug 'jiangmiao/auto-pairs'
    Plug 'airblade/vim-gitgutter'
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
call plug#end()

" general settings and theme related
syntax on
set number
set background=dark
set hlsearch
set termguicolors
colo gruvbox

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

" split navigations
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

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

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

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap [g <Plug>(coc-diagnostic-prev)
nmap ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap gd <Plug>(coc-definition)
nmap gy <Plug>(coc-type-definition)
nmap gi <Plug>(coc-implementation)
nmap gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')
autocmd VimEnter * highlight CocHighlightText ctermfg=White ctermbg=Blue

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)
