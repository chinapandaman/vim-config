" Editable search fields occupy lines 1-5; results start after the help/status.
let s:search_header_lines = 8

function! SearchBuffer()
  if bufexists('search') || bufexists('search-preview')
    call CloseSearchBuffers()
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
  file search
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted nowrap
  let b:search_root = l:root
  let b:search_target_winid = l:target_winid
  let b:search_locations = []
  let b:search_result_lines = []

  " Search is line-oriented. Seed it with the first line of the clipboard.
  let l:clipboard = split(getreg('+'), "\n", 1)
  call setline(1, ['Search: ' . get(l:clipboard, 0, ''),
        \ 'Regex: off', 'Match case: off', 'Include: ', 'Exclude: ',
        \ 'Enter: search/toggle | <Leader>r: regex | <Leader>c: case | o: open',
        \ 'Root: ' . b:search_root, 'Status: edit fields above, then press Enter'])
  call cursor(1, strlen('Search: ') + 1)

  nnoremap <silent> <buffer> <CR> :call SearchEnter()<CR>
  inoremap <silent> <buffer> <CR> <Esc>:call ExecuteSearch()<CR>
  nnoremap <silent> <buffer> <Leader>r :call ToggleSearchOption(2)<CR>
  nnoremap <silent> <buffer> <Leader>c :call ToggleSearchOption(3)<CR>
  nnoremap <silent> <buffer> o :call OpenFileFromSearchResult()<CR>

  augroup SearchPreview
    autocmd! * <buffer>
    " Preview filetype detection must be able to trigger FileType and Syntax.
    autocmd CursorMoved <buffer> ++nested call PreviewSearchResult()
  augroup END
endfunction

function! CloseSearchBuffers()
  for l:buffer_name in ['search-preview', 'search']
    let l:bufnr = bufnr(l:buffer_name)
    if l:bufnr != -1
      execute 'bwipeout! ' . l:bufnr
    endif
  endfor
endfunction

function! SearchEnter()
  if line('.') == 2 || line('.') == 3
    call ToggleSearchOption(line('.'))
  else
    call ExecuteSearch()
  endif
endfunction

function! ToggleSearchOption(line_number)
  let l:label = a:line_number == 2 ? 'Regex: ' : 'Match case: '
  call setline(a:line_number, l:label . (getline(a:line_number) ==# l:label . 'on' ? 'off' : 'on'))
  call ExecuteSearch()
endfunction

function! s:SearchField(line_number, label)
  let l:line = getline(a:line_number)
  if stridx(l:line, a:label . ':') != 0
    throw 'Keep the ' . a:label . ': field on line ' . a:line_number
  endif
  " Remove the one separator space, preserving whitespace in the search term.
  return substitute(strpart(l:line, strlen(a:label) + 1), '^ ', '', '')
endfunction

function! s:SearchGlobs(value)
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
    if l:pattern =~# '/$' || isdirectory(b:search_root . '/' . l:pattern)
      let l:pattern = substitute(l:pattern, '/\+$', '', '') . '/**'
    endif
    call add(l:patterns, l:pattern)
  endfor
  return l:patterns
endfunction

function! s:SearchJsonText(value)
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

function! ExecuteSearch()
  let l:position = getpos('.')
  let b:search_locations = []
  let b:search_result_lines = []
  if line('$') > s:search_header_lines
    execute (s:search_header_lines + 1) . ',$delete _'
  endif
  " A new search must not leave an unrelated preview visible.
  if bufexists('search-preview')
    execute 'bwipeout! ' . bufnr('search-preview')
  endif

  let l:stderr = tempname()
  try
    if !executable('rg')
      throw 'ripgrep (rg) is required; install it and ensure it is on PATH'
    endif
    let l:term = s:SearchField(1, 'Search')
    let l:regex = trim(s:SearchField(2, 'Regex'))
    let l:case = trim(s:SearchField(3, 'Match case'))
    let l:include = s:SearchGlobs(s:SearchField(4, 'Include'))
    let l:exclude = s:SearchGlobs(s:SearchField(5, 'Exclude'))
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
    let l:command = 'cd ' . shellescape(b:search_root) . ' && '
          \ . join(map(copy(l:args), 'shellescape(v:val)'), ' ')
          \ . ' 2>' . shellescape(l:stderr)
    let l:output = systemlist(l:command)
    let l:exit_code = v:shell_error

    let l:matches = []
    let l:binary_paths = {}
    for l:line in l:output
      let l:event = json_decode(l:line)
      if get(l:event, 'type', '') ==# 'end' && get(l:event.data, 'binary_offset', v:null) isnot v:null
        let l:binary_paths[s:SearchJsonText(l:event.data.path)] = 1
      endif
      if get(l:event, 'type', '') !=# 'match'
        continue
      endif
      call add(l:matches, l:event.data)
    endfor
    for l:data in l:matches
      " A NUL found later in a file can invalidate earlier JSON matches.
      if has_key(l:binary_paths, s:SearchJsonText(l:data.path))
        continue
      endif
      let l:path = substitute(s:SearchJsonText(l:data.path), '^\./', '', '')
      let l:text = substitute(s:SearchJsonText(l:data.lines), '\r\?\n$', '', '')
      " Keep locations separate from display text, including paths with colons.
      call add(b:search_locations, [b:search_root . '/' . l:path, l:data.line_number])
      call add(b:search_result_lines, strtrans(l:path) . ':' . l:data.line_number . ':' . strtrans(l:text))
    endfor
    call append(s:search_header_lines, b:search_result_lines)
    if l:exit_code > 1
      let l:errors = filereadable(l:stderr) ? join(readfile(l:stderr), ' ') : ''
      throw 'ripgrep: ' . (empty(l:errors) ? 'exit code ' . l:exit_code : l:errors)
    endif
    call setline(8, empty(b:search_locations) ? 'Status: no matches' : 'Status: ' . len(b:search_locations) . ' matching lines')
  catch
    call setline(8, 'Status: error: ' . v:exception)
  finally
    call delete(l:stderr)
    call setpos('.', l:position)
    setlocal nomodified
  endtry
endfunction

function! SearchResultLocation()
  let l:index = line('.') - s:search_header_lines - 1
  if l:index < 0 || l:index >= len(get(b:, 'search_locations', []))
    return []
  endif
  " Do not navigate from an edited result line.
  if getline('.') !=# b:search_result_lines[l:index]
    return []
  endif
  return b:search_locations[l:index]
endfunction

function! OpenFileFromSearchResult()
  let l:location = SearchResultLocation()
  if empty(l:location)
    echo 'Please select a valid search result.'
    return
  endif

  " Reuse the window that opened search, independent of split layout or cwd.
  if !win_gotoid(b:search_target_winid)
    leftabove vnew
  endif
  execute 'edit ' . fnameescape(l:location[0])
  call cursor(l:location[1], 1)
  normal! zz
endfunction

function! PreviewSearchResult()
  let l:location = SearchResultLocation()
  if empty(l:location)
    return
  endif

  let l:search_winid = win_getid()
  let l:preview_bufnr = bufnr('search-preview')
  let l:preview_winid = l:preview_bufnr == -1 ? -1 : bufwinid(l:preview_bufnr)
  try
    if l:preview_winid == -1
      belowright split
      if l:preview_bufnr == -1
        enew
        file search-preview
        setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
      else
        execute 'buffer ' . l:preview_bufnr
      endif
    else
      call win_gotoid(l:preview_winid)
    endif
    call ShowSearchPreview(l:location[0], l:location[1])
  finally
    call win_gotoid(l:search_winid)
  endtry
endfunction

function! ShowSearchPreview(file_path, line_number)
  if get(b:, 'search_preview_file', '') ==# a:file_path
    call JumpToSearchPreviewLine(a:line_number)
    return
  endif

  " Filetype detection remembers that it already ran for this buffer while
  " inside an autocommand. A fresh scratch buffer resets that state and any
  " language-specific buffer settings when moving to a different file.
  if exists('b:search_preview_file')
    let l:old_bufnr = bufnr('%')
    noautocmd enew
    execute 'bwipeout! ' . l:old_bufnr
    file search-preview
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
  let b:search_preview_file = a:file_path

  " Detect from the source filename and contents. Do not clear 'filetype'
  " first: even assigning an empty value marks detection as already done.
  filetype on
  execute 'doautocmd <nomodeline> filetypedetect BufRead ' . fnameescape(a:file_path)
  let &l:syntax = &l:filetype
  setlocal nomodified nomodifiable readonly
  call JumpToSearchPreviewLine(a:line_number)
endfunction

function! JumpToSearchPreviewLine(line_number)
  call cursor(min([max([a:line_number, 1]), line('$')]), 1)
  normal! zz
endfunction

nnoremap <Leader>ag :call SearchBuffer()<CR>
