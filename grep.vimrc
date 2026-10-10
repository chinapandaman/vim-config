" Editable search fields occupy lines 1-5; results start after the help/status.
let s:grep_header_lines = 8

function! GrepSearchBuffer()
  if bufexists('grep') || bufexists('grep-preview')
    call CloseGrepBuffers()
    return
  endif

  let l:target_winid = win_getid()
  let l:root = getcwd()
  if executable('git')
    let l:git_root = systemlist('git -C ' . shellescape(l:root) . ' rev-parse --show-toplevel 2>/dev/null')
    if v:shell_error == 0 && !empty(l:git_root)
      let l:root = l:git_root[0]
    endif
  endif

  vnew
  file grep
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted nowrap
  let b:grep_root = l:root
  let b:grep_target_winid = l:target_winid
  let b:grep_locations = []
  let b:grep_result_lines = []

  " Search is line-oriented. Seed it with the first line of the clipboard.
  let l:clipboard = split(getreg('+'), "\n", 1)
  call setline(1, ['Search: ' . get(l:clipboard, 0, ''),
        \ 'Regex: off', 'Match case: off', 'Include: ', 'Exclude: ',
        \ 'Enter: search/toggle | <Leader>r: regex | <Leader>c: case | o: open',
        \ 'Root: ' . b:grep_root, 'Status: edit fields above, then press Enter'])
  call cursor(1, strlen('Search: ') + 1)

  nnoremap <silent> <buffer> <CR> :call GrepSearchEnter()<CR>
  inoremap <silent> <buffer> <CR> <Esc>:call ExecuteGrepCommand()<CR>
  nnoremap <silent> <buffer> <Leader>r :call ToggleGrepOption(2)<CR>
  nnoremap <silent> <buffer> <Leader>c :call ToggleGrepOption(3)<CR>
  nnoremap <silent> <buffer> o :call OpenFileFromGrepResult()<CR>

  augroup GrepSearchPreview
    autocmd! * <buffer>
    " Preview filetype detection must be able to trigger FileType and Syntax.
    autocmd CursorMoved <buffer> ++nested call PreviewGrepResult()
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

function! GrepSearchEnter()
  if line('.') == 2 || line('.') == 3
    call ToggleGrepOption(line('.'))
  else
    call ExecuteGrepCommand()
  endif
endfunction

function! ToggleGrepOption(line_number)
  let l:label = a:line_number == 2 ? 'Regex: ' : 'Match case: '
  call setline(a:line_number, l:label . (getline(a:line_number) ==# l:label . 'on' ? 'off' : 'on'))
  call ExecuteGrepCommand()
endfunction

function! s:GrepField(line_number, label)
  let l:line = getline(a:line_number)
  if stridx(l:line, a:label . ':') != 0
    throw 'Keep the ' . a:label . ': field on line ' . a:line_number
  endif
  " Remove the one separator space, preserving whitespace in the search term.
  return substitute(strpart(l:line, strlen(a:label) + 1), '^ ', '', '')
endfunction

function! s:GrepGlobs(value)
  let l:patterns = []
  for l:part in split(a:value, ',')
    let l:pattern = trim(l:part)
    if empty(l:pattern)
      continue
    endif
    if l:pattern[0] ==# '!'
      throw 'Use the Exclude field instead of a leading ! in a glob'
    endif
    let l:pattern = substitute(l:pattern, '^\./', '', '')
    " A directory name is shorthand for its entire subtree.
    if l:pattern =~# '/$' || isdirectory(b:grep_root . '/' . l:pattern)
      let l:pattern = substitute(l:pattern, '/\+$', '', '') . '/**'
    endif
    call add(l:patterns, l:pattern)
  endfor
  return l:patterns
endfunction

function! s:GrepJsonText(value)
  if has_key(a:value, 'text')
    return a:value.text
  endif
  " ripgrep encodes non-UTF-8 paths and lines as base64. Decode to raw bytes.
  let l:alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  let l:bits = 0
  let l:count = 0
  let l:escaped = ''
  for l:char in split(a:value.bytes, '\zs')
    if l:char ==# '='
      break
    endif
    let l:bits = l:bits * 64 + stridx(l:alphabet, l:char)
    let l:count += 6
    if l:count >= 8
      let l:count -= 8
      let l:divisor = float2nr(pow(2, l:count))
      let l:escaped .= printf('\x%02x', l:bits / l:divisor)
      let l:bits = l:bits % l:divisor
    endif
  endfor
  return eval('"' . l:escaped . '"')
endfunction

function! ExecuteGrepCommand()
  let l:position = getpos('.')
  let b:grep_locations = []
  let b:grep_result_lines = []
  if line('$') > s:grep_header_lines
    execute (s:grep_header_lines + 1) . ',$delete _'
  endif
  " A new search must not leave an unrelated preview visible.
  if bufexists('grep-preview')
    execute 'bwipeout! ' . bufnr('grep-preview')
  endif

  let l:stderr = tempname()
  try
    if !executable('rg')
      throw 'ripgrep (rg) is required; install it and ensure it is on PATH'
    endif
    let l:term = s:GrepField(1, 'Search')
    let l:regex = trim(s:GrepField(2, 'Regex'))
    let l:case = trim(s:GrepField(3, 'Match case'))
    let l:include = s:GrepGlobs(s:GrepField(4, 'Include'))
    let l:exclude = s:GrepGlobs(s:GrepField(5, 'Exclude'))
    if index(['on', 'off'], l:regex) < 0 || index(['on', 'off'], l:case) < 0
      throw 'Regex and Match case must be on or off (Enter toggles them)'
    endif
    if empty(l:term)
      call setline(8, 'Status: enter a search term')
      return
    endif

    let l:args = ['rg', '--no-config', '--json', '--hidden', '--no-require-git', '--color=never']
    call add(l:args, l:case ==# 'on' ? '--case-sensitive' : '--ignore-case')
    if l:regex ==# 'off'
      call add(l:args, '--fixed-strings')
    endif
    if !empty(l:include)
      " Overrides alone cannot traverse ignored directories. Limit an
      " unrestricted traversal to explicitly included globs instead.
      call add(l:args, '--no-ignore')
    endif
    for l:pattern in l:include
      call extend(l:args, ['--glob', l:pattern])
    endfor
    for l:pattern in l:exclude
      call extend(l:args, ['--glob', '!' . l:pattern])
    endfor
    " Exclusions win, and Git metadata is never part of a workspace search.
    call extend(l:args, ['--glob', '!.git', '--', l:term, '.'])
    let l:command = 'cd ' . shellescape(b:grep_root) . ' && '
          \ . join(map(copy(l:args), 'shellescape(v:val)'), ' ')
          \ . ' 2>' . shellescape(l:stderr)
    let l:output = systemlist(l:command)
    let l:exit_code = v:shell_error

    let l:matches = []
    let l:binary_paths = {}
    for l:line in l:output
      let l:event = json_decode(l:line)
      if get(l:event, 'type', '') ==# 'end' && get(l:event.data, 'binary_offset', v:null) isnot v:null
        let l:binary_paths[s:GrepJsonText(l:event.data.path)] = 1
      endif
      if get(l:event, 'type', '') !=# 'match'
        continue
      endif
      call add(l:matches, l:event.data)
    endfor
    for l:data in l:matches
      " A NUL found later in a file can invalidate earlier JSON matches.
      if has_key(l:binary_paths, s:GrepJsonText(l:data.path))
        continue
      endif
      let l:path = substitute(s:GrepJsonText(l:data.path), '^\./', '', '')
      let l:text = substitute(s:GrepJsonText(l:data.lines), '\r\?\n$', '', '')
      " Keep locations separate from display text, including paths with colons.
      call add(b:grep_locations, [b:grep_root . '/' . l:path, l:data.line_number])
      call add(b:grep_result_lines, strtrans(l:path) . ':' . l:data.line_number . ':' . strtrans(l:text))
    endfor
    call append(s:grep_header_lines, b:grep_result_lines)
    if l:exit_code > 1
      let l:errors = filereadable(l:stderr) ? join(readfile(l:stderr), ' ') : ''
      throw 'ripgrep: ' . (empty(l:errors) ? 'exit code ' . l:exit_code : l:errors)
    endif
    call setline(8, empty(b:grep_locations) ? 'Status: no matches' : 'Status: ' . len(b:grep_locations) . ' matching lines')
  catch
    call setline(8, 'Status: error: ' . v:exception)
  finally
    call delete(l:stderr)
    call setpos('.', l:position)
    setlocal nomodified
  endtry
endfunction

function! GrepResultLocation()
  let l:index = line('.') - s:grep_header_lines - 1
  if l:index < 0 || l:index >= len(get(b:, 'grep_locations', []))
    return []
  endif
  " Do not navigate from an edited result line.
  if getline('.') !=# b:grep_result_lines[l:index]
    return []
  endif
  return b:grep_locations[l:index]
endfunction

function! OpenFileFromGrepResult()
  let l:location = GrepResultLocation()
  if empty(l:location)
    echo 'Please select a valid grep result.'
    return
  endif

  " Reuse the window that opened search, independent of split layout or cwd.
  if !win_gotoid(b:grep_target_winid)
    leftabove vnew
  endif
  execute 'edit ' . fnameescape(l:location[0])
  call cursor(l:location[1], 1)
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
  try
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
  finally
    call win_gotoid(l:grep_winid)
  endtry
endfunction

function! ShowGrepPreview(file_path, line_number)
  if get(b:, 'grep_preview_file', '') ==# a:file_path
    call JumpToGrepPreviewLine(a:line_number)
    return
  endif

  " Filetype detection remembers that it already ran for this buffer while
  " inside an autocommand. A fresh scratch buffer resets that state and any
  " language-specific buffer settings when moving to a different file.
  if exists('b:grep_preview_file')
    let l:old_bufnr = bufnr('%')
    noautocmd enew
    execute 'bwipeout! ' . l:old_bufnr
    file grep-preview
    setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
  endif

  try
    let l:lines = readfile(a:file_path)
  catch
    let l:lines = ['Unable to read ' . a:file_path, v:exception]
  endtry

  setlocal modifiable noreadonly
  silent! %delete _
  call setline(1, empty(l:lines) ? [''] : l:lines)
  let b:grep_preview_file = a:file_path

  " Detect from the source filename and contents. Do not clear 'filetype'
  " first: even assigning an empty value marks detection as already done.
  filetype on
  execute 'doautocmd <nomodeline> filetypedetect BufRead ' . fnameescape(a:file_path)
  let &l:syntax = &l:filetype
  setlocal nomodified nomodifiable readonly
  call JumpToGrepPreviewLine(a:line_number)
endfunction

function! JumpToGrepPreviewLine(line_number)
  call cursor(min([max([a:line_number, 1]), line('$')]), 1)
  normal! zz
endfunction

nnoremap <Leader>ag :call GrepSearchBuffer()<CR>
