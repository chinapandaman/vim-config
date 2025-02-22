" git related
function! GitUnstagedVdiff()
  " Close all existing buffers
  bufdo bdelete

  " Get a list of unstaged files
  let l:files = systemlist('git diff --name-only')

  " If there are no unstaged files, return
  if empty(l:files)
    echo "No unstaged files."
    return
  endif

  " Open each unstaged file in a new buffer
  for l:file in l:files
    execute 'edit ' . l:file
  endfor

  " Run :Gvdiff
  Gvdiff
endfunction

function! CloseLeftSplitNextBufferVdiff()
  " Move to the left split
  wincmd h
  if &buftype == ''
    close
  endif

  " Move to the next buffer
  bnext

  " Run :Gvdiff
  Gvdiff
endfunction

" Map function to <Leader><Tab>
nnoremap <Leader><Tab> :call CloseLeftSplitNextBufferVdiff()<CR>
nnoremap <Leader>gd :!vim -M -n -c 'call GitUnstagedVdiff()'<CR>
nnoremap <Leader>gs :Git status<CR>
nnoremap <Leader>gb :Git branch<CR>

