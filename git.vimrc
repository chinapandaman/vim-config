" git related
function! GitUnstagedAndUntrackedVdiff()
  " Close all existing buffers
  bufdo bdelete

  " Get a list of unstaged and untracked files
  let l:unstaged_files = systemlist('git diff --name-only')
  let l:untracked_files = systemlist('git ls-files --others --exclude-standard')
  let l:files = l:unstaged_files + l:untracked_files

  " If there are no unstaged or untracked files, return
  if empty(l:files)
    echo "No unstaged or untracked files."
    return
  endif

  " Open each file in a new buffer
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
nnoremap <Leader>gd :!vim -M -n -c 'let g:ale_enabled = 0' -c 'call GitUnstagedAndUntrackedVdiff()'<CR>
nnoremap <Leader>gs :Git status<CR>
nnoremap <Leader>gb :Git branch<CR>

