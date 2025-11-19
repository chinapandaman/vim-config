" general settings and theme related
syntax on
set number
set relativenumber
set background=dark
set hlsearch
set termguicolors
set backspace=indent,eol,start
let g:sonokai_style = 'andromeda'
colorscheme sonokai
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

" ale
let g:ale_linters={
\   'python': ['pyright'],
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

function! DiffYankAndClipboard()
    " Get the syntax highlighting of the current file
    let l:syntax = &syntax

    " Check if the scratch buffers already exist
    let s:left_buf = bufexists('Yank') ? bufnr('Yank') : -1
    let s:right_buf = bufexists('Clipboard') ? bufnr('Clipboard') : -1

    " If both buffers exist, close them and return (toggle behavior)
    if s:left_buf > 0 && s:right_buf > 0
        execute 'bd! ' . s:left_buf
        execute 'bd! ' . s:right_buf
        return
    endif

    " Open left scratch buffer for yanked text
    vnew Yank
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    call setline(1, split(getreg('"'), "\n"))
    execute 'setlocal syntax=' . l:syntax
    diffthis

    " Open right scratch buffer for clipboard text
    vnew Clipboard
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    call setline(1, split(getreg('+'), "\n"))
    execute 'setlocal syntax=' . l:syntax
    diffthis

    " Move back to the left buffer
    wincmd h
endfunction

function! OpenGithubFile()
  let l:remote_url = system('git config --get remote.origin.url')
  let l:remote_url = substitute(l:remote_url, '\n', '', 'g')

  " Convert SSH GitHub URLs to HTTPS format
  if l:remote_url =~? '^git@github.com:'
    let l:remote_url = substitute(l:remote_url, '^git@github.com:', 'https://github.com/', '')
  endif
  let l:remote_url = substitute(l:remote_url, '.git$', '', '')

  " Get the current Git branch
  let l:branch = system('git rev-parse --abbrev-ref HEAD')
  let l:branch = substitute(l:branch, '\n', '', 'g')

  " Get the relative file path in the repository
  let l:file = expand('%')

  " Construct the GitHub URL for the current file
  let l:url = l:remote_url . '/blob/' . l:branch . '/' . l:file

  " Open the URL in the default web browser
  if has('mac')
    call system('open ' . shellescape(l:url) . ' &')  " macOS
  elseif has('unix')
    call system('xdg-open ' . shellescape(l:url) . ' &')  " Linux
  elseif has('win32') || has('win64')
    call system('start ' . shellescape(l:url))  " Windows
  endif
endfunction

autocmd CursorMoved * call YAMLTree()
set foldlevelstart=20

" hotkeys
vnoremap <Leader>cp "+y
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
nnoremap <Leader>ra :%s//
nnoremap <Leader>d :call DiffYankAndClipboard()<CR>
nnoremap <Leader>gf :call OpenGithubFile()<CR>

