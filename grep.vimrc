function! GrepSearchBuffer()
  " Check if a buffer named 'grep' already exists, close it if found
  let l:grep_bufnr = bufexists('grep') ? bufnr('grep') : -1
  if l:grep_bufnr != -1
    execute 'bd! ' . l:grep_bufnr
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

function! OpenFileFromGrepResult()
  " Get the line under the cursor containing the file name and line number
  let l:grep_result = getline('.')

  " Ensure we are not on the grep command or empty line (skip first two lines)
  if line('.') <= 2
    echo "Please select a valid grep result."
    return
  endif

  " Extract the file path from the grep result (match before the first colon)
  let l:file_path = matchstr(l:grep_result, '^\([^:]*\)')

  " Extract the line number from between the first and second colon
  let l:line_number = matchstr(l:grep_result, ':\zs\d\+')

  " Switch to the left split
  wincmd h

  " Open the file in the left split
  execute 'e ' . l:file_path

  " Jump to the extracted line number
  execute l:line_number

  " Center the line on the screen
  normal! zz
endfunction

" Map <Leader>ag to open the grep buffer
nnoremap <Leader>ag :call GrepSearchBuffer()<CR>

