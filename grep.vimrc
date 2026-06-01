function! GrepSearchBuffer()
  " Toggle off the grep workflow if either buffer already exists.
  if bufexists('grep') || bufexists('grep-preview')
    call CloseGrepBuffers()
    return
  endif

  " Open a vertical split with a new temporary buffer
  vnew

  " Set buffer name to "grep" and make it temporary
  file grep
  setlocal buftype=nofile bufhidden=hide noswapfile

  " Get the clipboard content
  let l:search_term = getreg('+') " Use the system clipboard register
  
  " Construct the grep command with the clipboard content as the search string
  let l:grep_cmd = 'git grep -in "' . l:search_term . '" -- "*"'

  " Insert the grep command into the buffer
  call setline(1, l:grep_cmd)
  call setline(2, '') " Insert an empty line after the command

  " Move cursor to the file extension filter ("*") at position 28
  call cursor(1, 28)

  " Map <Enter> to execute the command and insert results below it
  nnoremap <buffer> <CR> :call ExecuteGrepCommand()<CR>

  " Map "o" to open the file under the cursor in the existing left split
  nnoremap <buffer> o :call OpenFileFromGrepResult()<CR>

  " Preview grep results as the cursor moves over them
  augroup GrepSearchPreview
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call PreviewGrepResult()
  augroup END
endfunction

function! CloseGrepBuffers()
  for l:buffer_name in ['grep-preview', 'grep']
    let l:bufnr = bufnr(l:buffer_name)
    if l:bufnr != -1
      execute 'bwipeout! ' . l:bufnr
    endif
  endfor
endfunction

function! ExecuteGrepCommand()
  " Get the grep command from the first line of the buffer
  let l:cmd = getline(1)

  " Remove previous grep results (keep only the first two lines: command and empty line)
  silent! 3,$delete _

  " Execute the command and insert its output below the empty line
  call append(2, systemlist(l:cmd))

  " Move the cursor back to the position where the file extension filter was
  call cursor(1, 28)
endfunction

function! GrepResultLocation()
  " Ensure we are not on the grep command or empty line (skip first two lines)
  if line('.') <= 2
    return []
  endif

  " Extract the file path and line number from git grep output.
  let l:grep_result = getline('.')
  let l:matches = matchlist(l:grep_result, '^\(.\{-}\):\(\d\+\):')
  if empty(l:matches)
    return []
  endif

  return [l:matches[1], str2nr(l:matches[2])]
endfunction

function! OpenFileFromGrepResult()
  let l:location = GrepResultLocation()
  if empty(l:location)
    echo "Please select a valid grep result."
    return
  endif

  " Switch to the left split
  wincmd h

  " Open the file in the left split
  execute 'e ' . fnameescape(l:location[0])

  " Jump to the extracted line number
  execute l:location[1]

  " Center the line on the screen
  normal! zz
endfunction

function! PreviewGrepResult()
  let l:location = GrepResultLocation()
  if empty(l:location)
    return
  endif

  let l:grep_winid = win_getid()
  let l:preview_bufnr = bufnr('grep-preview')
  let l:preview_winid = l:preview_bufnr == -1 ? -1 : bufwinid(l:preview_bufnr)

  if l:preview_winid == -1
    belowright split
    if l:preview_bufnr == -1
      enew
      file grep-preview
      setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
    else
      execute 'buffer ' . l:preview_bufnr
    endif
  else
    call win_gotoid(l:preview_winid)
  endif

  call ShowGrepPreview(l:location[0], l:location[1])
  call win_gotoid(l:grep_winid)
endfunction

function! ShowGrepPreview(file_path, line_number)
  let l:preview_key = a:file_path . ':' . a:line_number
  if exists('b:grep_preview_key') && b:grep_preview_key ==# l:preview_key
    call JumpToGrepPreviewLine(a:line_number)
    return
  endif

  if exists('b:grep_preview_file') && b:grep_preview_file ==# a:file_path
    let b:grep_preview_key = l:preview_key
    call JumpToGrepPreviewLine(a:line_number)
    return
  endif

  try
    let l:lines = readfile(a:file_path)
  catch
    let l:lines = ['Unable to read ' . a:file_path, v:exception]
  endtry

  if empty(l:lines)
    let l:lines = ['']
  endif

  setlocal modifiable noreadonly
  silent! %delete _
  call setline(1, l:lines)
  let b:grep_preview_file = a:file_path
  let b:grep_preview_key = l:preview_key
  setlocal nomodified nomodifiable readonly

  call JumpToGrepPreviewLine(a:line_number)
endfunction

function! JumpToGrepPreviewLine(line_number)
  call cursor(min([max([a:line_number, 1]), line('$')]), 1)
  normal! zz
endfunction

" Map <Leader>ag to open the grep buffer
nnoremap <Leader>ag :call GrepSearchBuffer()<CR>

