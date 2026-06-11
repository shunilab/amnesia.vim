" amnesia.vim - Write Markdown without remembering Markdown
" NotionLike Markdownコマンド本体（autoload・初回コマンド実行時にロード）


function! s:is_url(text) abort
    let l:trimmed = trim(a:text)
    if empty(l:trimmed)
        return 0
    endif
    return l:trimmed =~# '^\a[A-Za-z0-9+.-]*://\S\+$'
        \ || l:trimmed =~# '^www\.\S\+$'
        \ || l:trimmed =~# '^mailto:\S\+$'
endfunction

function! s:has_visual_selection(opts) abort
    if get(a:opts, 'range', 0) == 0
        return 0
    endif

    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    if line_start == 0 || line_end == 0
        return 0
    endif

    if get(a:opts, 'line1', 0) != line_start || get(a:opts, 'line2', 0) != line_end
        return 0
    endif

    return line_start != line_end || column_start != column_end
endfunction

function! s:move_cursor_and_startinsert(line_num, col) abort
    call cursor(a:line_num, a:col + 1)
    startinsert
endfunction

function! s:move_cursor_to_delim(line_num, delim, ...) abort
    let l:line = getline(a:line_num)
    let l:start_col = a:0 > 0 ? a:1 : 0
    let l:col = match(l:line, '\V' . escape(a:delim, '\'), l:start_col)
    if l:col >= 0
        call s:move_cursor_and_startinsert(a:line_num, l:col + 1)
    endif
endfunction

function! s:move_cursor_to_link_text(line_num, ...) abort
    call call(function('s:move_cursor_to_delim'), [a:line_num, '['] + a:000)
endfunction

function! s:move_cursor_to_link_url(line_num, ...) abort
    call call(function('s:move_cursor_to_delim'), [a:line_num, '('] + a:000)
endfunction

function! s:move_cursor_to_image_alt(line_num, ...) abort
    call call(function('s:move_cursor_to_delim'), [a:line_num, '['] + a:000)
endfunction

function! s:move_cursor_to_image_url(line_num, ...) abort
    call call(function('s:move_cursor_to_link_url'), [a:line_num] + a:000)
endfunction

function! s:build_link_insert_spec(args) abort
    if len(a:args) > 2
        return {'error': 'MDLink accepts at most 2 arguments: [text] [url]'}
    endif

    if len(a:args) == 2
        return {'text': a:args[0], 'url': a:args[1]}
    endif

    if len(a:args) == 1
        if s:is_url(a:args[0])
            return {'text': '', 'url': a:args[0], 'focus': 'text'}
        endif
        return {'text': a:args[0], 'url': '', 'focus': 'url'}
    endif

    return {}
endfunction

function! s:build_code_block_spec(args) abort
    if len(a:args) > 1
        return {'error': 'MDCode accepts at most 1 argument: [language]'}
    endif

    return {'fence': '```' . get(a:args, 0, '')}
endfunction

function! s:build_image_insert_spec(args) abort
    if len(a:args) > 2
        return {'error': 'MDImage accepts at most 2 arguments: [alt] [url]'}
    endif

    if len(a:args) == 2
        return {'alt': a:args[0], 'url': a:args[1]}
    endif

    if len(a:args) == 1
        if s:is_url(a:args[0])
            return {'alt': '', 'url': a:args[0], 'focus': 'alt'}
        endif
        return {'alt': a:args[0], 'url': '', 'focus': 'url'}
    endif

    return {}
endfunction

function! s:parse_command_args(raw_args) abort
    let l:args = []
    let l:current = ''
    let l:quote = ''
    let l:escape = 0

    for l:ch in split(a:raw_args, '\zs')
        if l:escape
            let l:current .= l:ch
            let l:escape = 0
        elseif l:ch ==# '\'
            let l:escape = 1
        elseif !empty(l:quote)
            if l:ch ==# l:quote
                let l:quote = ''
            else
                let l:current .= l:ch
            endif
        elseif l:ch ==# '"' || l:ch ==# "'"
            let l:quote = l:ch
        elseif l:ch =~# '\s'
            if !empty(l:current)
                call add(l:args, l:current)
                let l:current = ''
            endif
        else
            let l:current .= l:ch
        endif
    endfor

    if l:escape
        let l:current .= '\'
    endif

    if !empty(l:quote)
        return {'error': 'MDLink has an unmatched quote in its arguments'}
    endif

    if !empty(l:current)
        call add(l:args, l:current)
    endif

    return {'args': l:args}
endfunction

function! s:split_by_visual_cols(line, from_col, to_col) abort
    let l:start_char = charidx(a:line, max([a:from_col - 1, 0]))
    let l:end_char = charidx(a:line, max([a:to_col - 1, 0])) + 1
    let l:selected_len = max([l:end_char - l:start_char, 0])
    return [
        \ strcharpart(a:line, 0, l:start_char),
        \ strcharpart(a:line, l:start_char, l:selected_len),
        \ strcharpart(a:line, l:end_char),
        \ ]
endfunction

" 選択範囲のテキストを取得するヘルパー関数
function! s:get_visual_selection() abort
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return [line_start, line_end, [], '', '']
    endif

    let prefix = ''
    let suffix = ''
    let visual_type = visualmode()

    if visual_type ==# 'V' || column_start == 0 || column_end == 0
        return [line_start, line_end, lines, prefix, suffix]
    endif

    " 選択範囲が1行の場合
    if line_start == line_end
        let [prefix, lines[0], suffix] = s:split_by_visual_cols(lines[0], column_start, column_end)
    else
        let [prefix, lines[0], _] = s:split_by_visual_cols(lines[0], column_start, strlen(lines[0]))
        let [_, lines[-1], suffix] = s:split_by_visual_cols(lines[-1], 1, column_end)
    endif

    return [line_start, line_end, lines, prefix, suffix]
endfunction

" カーソル位置にテキストを挿入するヘルパー関数
function! s:insert_at_cursor(text) abort
    let pos = getpos('.')
    let line = pos[1] - 1
    let col = pos[2] - 1

    let current_line = getline('.')
    let new_line = strpart(current_line, 0, col) . a:text . strpart(current_line, col)
    call setline('.', new_line)

    " カーソル位置を挿入したテキストの後ろに移動
    call cursor(pos[1], pos[2] + len(a:text))
endfunction

function! s:replace_lines(start_line, end_line, new_lines) abort
    if empty(a:new_lines)
        execute a:start_line . ',' . a:end_line . 'delete _'
        return
    endif

    call setline(a:start_line, a:new_lines)

    let l:new_end = a:start_line + len(a:new_lines) - 1
    if l:new_end < a:end_line
        execute (l:new_end + 1) . ',' . a:end_line . 'delete _'
    endif
endfunction

" 共通の選択範囲処理関数
function! s:process_visual_selection(process_fn, opts, ...) abort
    let l:PostProcess = a:0 > 0 ? a:1 : v:null
    if s:has_visual_selection(a:opts)
        let [start_line, end_line, lines, prefix, suffix] = s:get_visual_selection()
        if len(lines) > 0
            " 各行に処理を適用
            let new_lines = a:process_fn(lines)
            if len(new_lines) > 0
                let new_lines[0] = prefix . new_lines[0]
                let new_lines[-1] = new_lines[-1] . suffix
            endif
            call s:replace_lines(start_line, end_line, new_lines)
            if type(l:PostProcess) == type(function('tr'))
                call l:PostProcess(start_line)
            endif
            return 1
        endif
    endif
    return 0
endfunction

" 空行でない行にのみ処理を適用するラッパー関数
function! s:process_non_empty_lines(lines, prefix, ...) abort
    let suffix = a:0 > 0 ? a:1 : ''
    let new_lines = []
    for line in a:lines
        if line !~ '^\s*$'  " 完全な空行でない場合のみ処理
            call add(new_lines, a:prefix . line . suffix)
        else
            call add(new_lines, line)
        endif
    endfor
    return new_lines
endfunction

function! s:insert_template_and_focus(text, cursor_offset) abort
    call s:insert_at_cursor(a:text)
    let l:pos = getpos('.')
    call s:move_cursor_and_startinsert(l:pos[1], l:pos[2] - 1 + a:cursor_offset)
endfunction

function! s:transform_current_line(Fn) abort
    let l:line_num = line('.')
    call setline(l:line_num, a:Fn(getline(l:line_num)))
    call cursor(l:line_num, 1)
endfunction

function! s:get_selection_text(lines) abort
    let l:selection = []
    for l:line in a:lines
        if l:line !~ '^\s*$'
            call add(l:selection, trim(l:line))
        endif
    endfor
    return join(l:selection, ' ')
endfunction

function! s:parse_basic_link(text) abort
    return matchlist(a:text, '^\[\(.*\)\](\([^)]\+\))$')
endfunction

function! s:parse_basic_image(text) abort
    return matchlist(a:text, '^!\[\(.*\)\](\([^)]\+\))$')
endfunction

function! s:toggle_wrapped_text(text, prefix, suffix) abort
    let l:pattern = '^' . escape(a:prefix, '\*`[]') . '\(.*\)' . escape(a:suffix, '\*`[]') . '$'
    let l:match = matchlist(a:text, l:pattern)
    return len(l:match) > 0 ? l:match[1] : ''
endfunction

function! s:process_wrapping(lines, prefix, suffix) abort
    if len(a:lines) == 1
        let l:inner = s:toggle_wrapped_text(a:lines[0], a:prefix, a:suffix)
        if l:inner !=# ''
            return [l:inner]
        endif
    endif
    return s:process_non_empty_lines(a:lines, a:prefix, a:suffix)
endfunction

function! s:normalize_heading_line(line, level) abort
    if a:line =~ '^\s*$'
        return a:line
    endif
    let l:match = matchlist(a:line, '^\(\s*\)\(#\+\)\s\+\(.*\)$')
    if len(l:match) > 0
        if len(l:match[2]) == a:level
            return l:match[1] . l:match[3]
        endif
        return l:match[1] . repeat('#', a:level) . ' ' . l:match[3]
    endif
    let l:parts = matchlist(a:line, '^\(\s*\)\(.*\)$')
    return l:parts[1] . repeat('#', a:level) . ' ' . l:parts[2]
endfunction

function! s:toggle_bullet_line(line) abort
    if a:line =~ '^\s*$'
        return a:line
    endif
    let l:match = matchlist(a:line, '^\(\s*\)-\s\+\(.*\)$')
    if len(l:match) > 0
        return l:match[1] . l:match[2]
    endif
    let l:parts = matchlist(a:line, '^\(\s*\)\(.*\)$')
    return l:parts[1] . '- ' . l:parts[2]
endfunction

function! s:strip_number_prefix(line) abort
    let l:match = matchlist(a:line, '^\(\s*\)\([[:alnum:]]\+\)\.\s\+\(.*\)$')
    if len(l:match) > 0
        return [l:match[1], l:match[3]]
    endif
    let l:parts = matchlist(a:line, '^\(\s*\)\(.*\)$')
    return [l:parts[1], l:parts[2]]
endfunction

function! s:to_alpha(index) abort
    let l:index = a:index
    let l:chars = []
    while l:index > 0
        let l:rem = (l:index - 1) % 26
        call insert(l:chars, nr2char(char2nr('a') + l:rem), 0)
        let l:index = (l:index - 1) / 26
    endwhile
    return join(l:chars, '')
endfunction

function! s:to_roman(index) abort
    let l:rest = a:index
    let l:numerals = [
        \ [1000, 'm'],
        \ [900, 'cm'],
        \ [500, 'd'],
        \ [400, 'cd'],
        \ [100, 'c'],
        \ [90, 'xc'],
        \ [50, 'l'],
        \ [40, 'xl'],
        \ [10, 'x'],
        \ [9, 'ix'],
        \ [5, 'v'],
        \ [4, 'iv'],
        \ [1, 'i'],
        \ ]
    let l:parts = []
    for l:numeral in l:numerals
        while l:rest >= l:numeral[0]
            call add(l:parts, l:numeral[1])
            let l:rest -= l:numeral[0]
        endwhile
    endfor
    return join(l:parts, '')
endfunction

function! s:format_number_marker(depth, index) abort
    let l:mode = a:depth % 3
    if l:mode == 0
        return string(a:index)
    endif
    if l:mode == 1
        return s:to_alpha(a:index)
    endif
    return s:to_roman(a:index)
endfunction

function! s:build_numbered_lines(lines) abort
    let l:entries = []
    let l:min_indent = -1
    let l:relative_indents = []

    for l:line in a:lines
        if l:line =~ '^\s*$'
            call add(l:entries, {'blank': 1, 'text': l:line})
        else
            let l:indent_info = s:count_indent_width(l:line)
            if has_key(l:indent_info, 'error')
                return {'error': l:indent_info.error}
            endif
            let l:min_indent = l:min_indent == -1 ? l:indent_info.width : min([l:min_indent, l:indent_info.width])
            let [l:indent, l:body] = s:strip_number_prefix(l:line)
            call add(l:entries, {
                \ 'indent': strlen(l:indent),
                \ 'body': l:body,
                \ })
        endif
    endfor

    let l:numbered_lines = []
    let l:counters = {}
    let l:prev_depth = 0
    for l:entry in l:entries
        if !get(l:entry, 'blank', 0)
            let l:entry.relative_indent = l:entry.indent - l:min_indent
            call add(l:relative_indents, l:entry.relative_indent)
        endif
    endfor

    let l:unit = s:infer_indent_unit(l:relative_indents)
    for l:entry in l:entries
        if get(l:entry, 'blank', 0)
            call add(l:numbered_lines, l:entry.text)
            continue
        endif
        if l:entry.relative_indent % l:unit != 0
            return {'error': 'MDNumber found inconsistent indentation'}
        endif
        let l:depth = l:entry.relative_indent / l:unit
        if l:depth > l:prev_depth + 1
            return {'error': 'MDNumber does not allow skipping indentation levels'}
        endif
        let l:index = get(l:counters, l:depth, 0) + 1
        let l:counters[l:depth] = l:index
        for l:key in keys(l:counters)
            if str2nr(l:key) > l:depth
                call remove(l:counters, l:key)
            endif
        endfor
        let l:marker = s:format_number_marker(l:depth, l:index)
        let l:indent = repeat(' ', l:depth * l:unit)
        call add(l:numbered_lines, l:indent . l:marker . '. ' . l:entry.body)
        let l:prev_depth = l:depth
    endfor

    return {'lines': l:numbered_lines}
endfunction

function! s:normalize_checkbox_line(line, checked) abort
    if a:line =~ '^\s*$'
        return a:line
    endif
    let l:match = matchlist(a:line, '^\(\s*\)\%([-*+]\s*\)\?\[\([ xX]\)\]\s*\(.*\)$')
    let l:mark = a:checked ? 'x' : ' '
    if len(l:match) > 0
        " 同じ状態の再適用はトグル解除（bullet/quoteと一貫）
        if tolower(l:match[2]) ==# l:mark
            return l:match[1] . l:match[3]
        endif
        return l:match[1] . '- [' . l:mark . '] ' . l:match[3]
    endif
    let l:parts = matchlist(a:line, '^\(\s*\)\(.*\)$')
    return l:parts[1] . '- [' . l:mark . '] ' . l:parts[2]
endfunction

function! s:toggle_quote_line(line) abort
    if a:line =~ '^\s*$'
        return a:line
    endif
    let l:match = matchlist(a:line, '^\(\s*\)>\s*\(.*\)$')
    if len(l:match) > 0
        return l:match[1] . l:match[2]
    endif
    let l:parts = matchlist(a:line, '^\(\s*\)\(.*\)$')
    return l:parts[1] . '> ' . l:parts[2]
endfunction

function! s:split_csv_line(line) abort
    let l:cells = []
    let l:current = ''
    let l:in_quotes = 0
    let l:i = 0
    while l:i < len(a:line)
        let l:ch = a:line[l:i]
        if l:in_quotes
            if l:ch ==# '"'
                if l:i + 1 < len(a:line) && a:line[l:i + 1] ==# '"'
                    let l:current .= '"'
                    let l:i += 1
                else
                    let l:in_quotes = 0
                endif
            else
                let l:current .= l:ch
            endif
        else
            if l:ch ==# '"'
                let l:in_quotes = 1
            elseif l:ch ==# ','
                call add(l:cells, trim(l:current))
                let l:current = ''
            else
                let l:current .= l:ch
            endif
        endif
        let l:i += 1
    endwhile
    call add(l:cells, trim(l:current))
    return l:cells
endfunction

function! s:split_table_row(line) abort
    if stridx(a:line, "\t") >= 0
        return map(split(a:line, "\t", 1), 'trim(v:val)')
    endif
    return s:split_csv_line(a:line)
endfunction

function! s:build_table_lines(rows) abort
    let l:max_cols = 0
    for l:row in a:rows
        let l:max_cols = max([l:max_cols, len(l:row)])
    endfor
    if l:max_cols == 0
        return []
    endif
    for l:row in a:rows
        while len(l:row) < l:max_cols
            call add(l:row, '')
        endwhile
    endfor
    let l:separator = repeat(['---'], l:max_cols)
    let l:table_lines = [
        \ '| ' . join(a:rows[0], ' | ') . ' |',
        \ '| ' . join(l:separator, ' | ') . ' |'
        \ ]
    for l:i in range(1, len(a:rows) - 1)
        call add(l:table_lines, '| ' . join(a:rows[l:i], ' | ') . ' |')
    endfor
    return l:table_lines
endfunction

function! s:count_indent_width(line) abort
    let l:indent = matchstr(a:line, '^\s*')
    if stridx(l:indent, "\t") >= 0
        return {'error': 'IndentTree does not support tabs in indentation'}
    endif
    return {'width': strlen(l:indent)}
endfunction

function! s:infer_indent_unit(relative_indents) abort
    let l:unit = -1
    for l:indent in a:relative_indents
        if l:indent > 0
            let l:unit = l:unit == -1 ? l:indent : min([l:unit, l:indent])
        endif
    endfor
    return l:unit > 0 ? l:unit : 1
endfunction

function! s:build_tree_lines(lines) abort
    let l:entries = []
    let l:min_indent = -1
    let l:relative_indents = []

    for l:line in a:lines
        if l:line !~ '^\s*$'
            let l:indent_info = s:count_indent_width(l:line)
            if has_key(l:indent_info, 'error')
                return {'error': l:indent_info.error}
            endif
            let l:indent = l:indent_info.width
            let l:min_indent = l:min_indent == -1 ? l:indent : min([l:min_indent, l:indent])
            call add(l:entries, {
                \ 'indent': l:indent,
                \ 'text': trim(l:line),
                \ })
        endif
    endfor

    if empty(l:entries)
        return {'error': 'IndentTree requires at least one non-empty line'}
    endif

    for l:entry in l:entries
        let l:entry.relative_indent = l:entry.indent - l:min_indent
        call add(l:relative_indents, l:entry.relative_indent)
    endfor

    let l:unit = s:infer_indent_unit(l:relative_indents)
    for l:entry in l:entries
        if l:entry.relative_indent % l:unit != 0
            return {'error': 'IndentTree found inconsistent indentation'}
        endif
        let l:entry.depth = l:entry.relative_indent / l:unit
    endfor

    if l:entries[0].depth != 0
        return {'error': 'IndentTree requires the first item to start at the base indentation'}
    endif

    for l:i in range(1, len(l:entries) - 1)
        let l:prev_depth = l:entries[l:i - 1].depth
        let l:depth = l:entries[l:i].depth
        if l:depth > l:prev_depth + 1
            return {'error': 'IndentTree does not allow skipping indentation levels'}
        endif
    endfor

    let l:tree_lines = []
    let l:ancestor_last = {}
    for l:i in range(0, len(l:entries) - 1)
        let l:entry = l:entries[l:i]
        let l:is_last = 1
        for l:j in range(l:i + 1, len(l:entries) - 1)
            let l:next_depth = l:entries[l:j].depth
            if l:next_depth == l:entry.depth
                let l:is_last = 0
                break
            endif
            if l:next_depth < l:entry.depth
                break
            endif
        endfor

        let l:prefix_parts = []
        if l:entry.depth >= 2
            " 列cは深さc+1の祖先に対応（深さ0の根は罫線列を持たない）
            for l:depth in range(0, l:entry.depth - 2)
                call add(l:prefix_parts, get(l:ancestor_last, l:depth + 1, 0) ? '    ' : '│   ')
            endfor
        endif
        if l:entry.depth > 0
            call add(l:prefix_parts, l:is_last ? '└── ' : '├── ')
        endif

        call add(l:tree_lines, join(l:prefix_parts, '') . l:entry.text)
        let l:ancestor_last[l:entry.depth] = l:is_last
    endfor

    return {'lines': l:tree_lines}
endfunction

" コードブロックを挿入
function! amnesia#code_block(opts, ...) abort
    let l:raw_args = a:0 > 0 ? a:1 : ''
    let l:parsed = s:parse_command_args(l:raw_args)
    if has_key(l:parsed, 'error')
        echoerr substitute(l:parsed.error, '^MDLink', 'MDCode', '')
        return
    endif

    let l:code_spec = s:build_code_block_spec(get(l:parsed, 'args', []))
    if has_key(l:code_spec, 'error')
        echoerr l:code_spec.error
        return
    endif

    let processed = s:process_visual_selection(
        \ {lines -> s:process_code_block(lines, l:code_spec.fence)},
        \ a:opts,
        \ {start_line -> cursor(start_line + 1, 1)}
        \ )

    if !processed
        " 通常モードの場合は従来の動作
        let pos = getpos('.')
        let line = pos[1] - 1
        let col = pos[2] - 1

        let current_line = getline('.')
        let lines = [
            \ strpart(current_line, 0, col) . l:code_spec.fence,
            \ '',
            \ '```' . strpart(current_line, col)
            \ ]

        call setline('.', lines[0])
        call append(pos[1], lines[1:])
        call s:move_cursor_and_startinsert(pos[1] + 1, 0)
    endif
endfunction

function! s:process_code_block(lines, fence) abort
    call insert(a:lines, a:fence, 0)
    call add(a:lines, '```')
    return a:lines
endfunction

" 見出し1を挿入
function! amnesia#h1(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:normalize_heading_line(v:val, 1)')}, a:opts)
        call s:transform_current_line(function('s:normalize_h1_current_line'))
    endif
endfunction

" 見出し2を挿入
function! amnesia#h2(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:normalize_heading_line(v:val, 2)')}, a:opts)
        call s:transform_current_line(function('s:normalize_h2_current_line'))
    endif
endfunction

" 見出し3を挿入
function! amnesia#h3(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:normalize_heading_line(v:val, 3)')}, a:opts)
        call s:transform_current_line(function('s:normalize_h3_current_line'))
    endif
endfunction

" 箇条書きを挿入
function! amnesia#bullet(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:toggle_bullet_line(v:val)')}, a:opts)
        call s:transform_current_line(function('s:toggle_bullet_line'))
    endif
endfunction

" 番号付きリストを挿入
function! amnesia#numbered(opts) abort
    if get(a:opts, 'range', 0) > 0
        let l:start_line = a:opts.line1
        let l:end_line = a:opts.line2
        let l:numbered_result = s:build_numbered_lines(getline(l:start_line, l:end_line))
        if has_key(l:numbered_result, 'error')
            echoerr l:numbered_result.error
            return
        endif
        call s:replace_lines(l:start_line, l:end_line, l:numbered_result.lines)
        call cursor(l:start_line, 1)
    else
        call s:transform_current_line(function('s:normalize_current_numbered_line'))
    endif
endfunction

function! s:normalize_current_numbered_line(line) abort
    let [l:indent, l:body] = s:strip_number_prefix(a:line)
    return l:indent . '1. ' . l:body
endfunction

function! s:normalize_h1_current_line(line) abort
    return s:normalize_heading_line(a:line, 1)
endfunction

function! s:normalize_h2_current_line(line) abort
    return s:normalize_heading_line(a:line, 2)
endfunction

function! s:normalize_h3_current_line(line) abort
    return s:normalize_heading_line(a:line, 3)
endfunction

function! s:normalize_checkbox_unchecked_current_line(line) abort
    return s:normalize_checkbox_line(a:line, 0)
endfunction

function! s:normalize_checkbox_checked_current_line(line) abort
    return s:normalize_checkbox_line(a:line, 1)
endfunction

" チェックボックスを挿入
function! amnesia#checkbox(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:normalize_checkbox_line(v:val, 0)')}, a:opts)
        call s:transform_current_line(function('s:normalize_checkbox_unchecked_current_line'))
    endif
endfunction

" 完了済みチェックボックスを挿入
function! amnesia#checkbox_done(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:normalize_checkbox_line(v:val, 1)')}, a:opts)
        call s:transform_current_line(function('s:normalize_checkbox_checked_current_line'))
    endif
endfunction

" 引用を挿入
function! amnesia#quote(opts) abort
    if !s:process_visual_selection({lines -> map(copy(lines), 's:toggle_quote_line(v:val)')}, a:opts)
        call s:transform_current_line(function('s:toggle_quote_line'))
    endif
endfunction

" 太字を挿入
function! amnesia#bold(opts) abort
    if !s:process_visual_selection({lines -> s:process_wrapping(lines, '**', '**')}, a:opts)
        call s:insert_template_and_focus('****', -2)
    endif
endfunction

" 斜体を挿入
function! amnesia#italic(opts) abort
    if !s:process_visual_selection({lines -> s:process_wrapping(lines, '*', '*')}, a:opts)
        call s:insert_template_and_focus('**', -1)
    endif
endfunction

" インラインコードを挿入
function! amnesia#inline_code(opts) abort
    if !s:process_visual_selection({lines -> s:process_wrapping(lines, '`', '`')}, a:opts)
        call s:insert_template_and_focus('``', -1)
    endif
endfunction

" リンクを挿入
function! amnesia#link(opts, ...) abort
    let l:raw_args = a:0 > 0 ? a:1 : ''
    let l:parsed = s:parse_command_args(l:raw_args)
    if has_key(l:parsed, 'error')
        echoerr l:parsed.error
        return
    endif

    let l:link_spec = s:build_link_insert_spec(get(l:parsed, 'args', []))
    if has_key(l:link_spec, 'error')
        echoerr l:link_spec.error
        return
    endif
    if !empty(l:link_spec)
        let l:start_col = col('.') - 1
        call s:insert_at_cursor('[' . l:link_spec.text . '](' . l:link_spec.url . ')')
        if get(l:link_spec, 'focus', '') ==# 'text'
            call s:move_cursor_to_link_text(line('.'), l:start_col)
        elseif get(l:link_spec, 'focus', '') ==# 'url'
            call s:move_cursor_to_link_url(line('.'), l:start_col)
        endif
        return
    endif

    if s:has_visual_selection(a:opts)
        let [start_line, end_line, lines, prefix, suffix] = s:get_visual_selection()
        let s:link_post_action = ''
        let l:new_lines = s:process_link(lines)
        if len(l:new_lines) > 0
            let l:start_col = strlen(prefix)
            let l:new_lines[0] = prefix . l:new_lines[0]
            let l:new_lines[-1] .= suffix
            call s:replace_lines(start_line, end_line, l:new_lines)
            if get(s:, 'link_post_action', '') ==# 'text'
                call s:move_cursor_to_link_text(start_line, l:start_col)
            elseif get(s:, 'link_post_action', '') ==# 'url'
                call s:move_cursor_to_link_url(start_line, l:start_col)
            else
                call cursor(start_line, 1)
            endif
        endif
        return
    endif

    if !s:process_visual_selection(function('s:process_link'), a:opts)
        let l:start_col = col('.') - 1
        call s:insert_at_cursor('[]()')
        call s:move_cursor_to_link_text(line('.'), l:start_col)
    endif
endfunction

function! s:process_link(lines) abort
    if len(a:lines) == 1
        let l:match = s:parse_basic_link(a:lines[0])
        if len(l:match) > 0
            let s:link_post_action = 'toggle'
            return [l:match[1]]
        endif
    endif
    let l:selected = s:get_selection_text(a:lines)
    if empty(l:selected)
        return a:lines
    endif
    if s:is_url(l:selected)
        let s:link_post_action = 'text'
        return ['[](' . l:selected . ')']
    endif
    let s:link_post_action = 'url'
    return ['[' . l:selected . ']()']
endfunction

" 画像を挿入
function! amnesia#image(opts, ...) abort
    let l:raw_args = a:0 > 0 ? a:1 : ''
    let l:parsed = s:parse_command_args(l:raw_args)
    if has_key(l:parsed, 'error')
        echoerr substitute(l:parsed.error, '^MDLink', 'MDImage', '')
        return
    endif

    let l:image_spec = s:build_image_insert_spec(get(l:parsed, 'args', []))
    if has_key(l:image_spec, 'error')
        echoerr l:image_spec.error
        return
    endif
    if !empty(l:image_spec)
        let l:start_col = col('.') - 1
        call s:insert_at_cursor('![' . l:image_spec.alt . '](' . l:image_spec.url . ')')
        if get(l:image_spec, 'focus', '') ==# 'alt'
            call s:move_cursor_to_image_alt(line('.'), l:start_col)
        elseif get(l:image_spec, 'focus', '') ==# 'url'
            call s:move_cursor_to_image_url(line('.'), l:start_col)
        endif
        return
    endif

    if s:has_visual_selection(a:opts)
        let [start_line, end_line, lines, prefix, suffix] = s:get_visual_selection()
        let s:image_post_action = ''
        let l:new_lines = s:process_image(lines)
        if len(l:new_lines) > 0
            let l:start_col = strlen(prefix)
            let l:new_lines[0] = prefix . l:new_lines[0]
            let l:new_lines[-1] .= suffix
            call s:replace_lines(start_line, end_line, l:new_lines)
            if get(s:, 'image_post_action', '') ==# 'alt'
                call s:move_cursor_to_image_alt(start_line, l:start_col)
            elseif get(s:, 'image_post_action', '') ==# 'url'
                call s:move_cursor_to_image_url(start_line, l:start_col)
            else
                call cursor(start_line, 1)
            endif
        endif
        return
    endif

    if !s:process_visual_selection(function('s:process_image'), a:opts)
        let l:start_col = col('.') - 1
        call s:insert_at_cursor('![]()')
        call s:move_cursor_to_image_alt(line('.'), l:start_col)
    endif
endfunction

function! s:process_image(lines) abort
    if len(a:lines) == 1
        let l:match = s:parse_basic_image(a:lines[0])
        if len(l:match) > 0
            let s:image_post_action = 'toggle'
            return [l:match[2]]
        endif
    endif
    let l:selected = s:get_selection_text(a:lines)
    if empty(l:selected)
        return a:lines
    endif
    if s:is_url(l:selected)
        let s:image_post_action = 'alt'
        return ['![](' . l:selected . ')']
    endif
    let s:image_post_action = 'url'
    return ['![' . l:selected . ']()']
endfunction

" 水平線を挿入（行中に挿すとMDが壊れるためカーソル行の下に1行で挿入）
function! amnesia#hr(opts) abort
    call append(line('.'), '---')
    call cursor(line('.') + 1, 1)
endfunction

" MDCode の言語名補完
function! amnesia#complete_lang(arglead, cmdline, cursorpos) abort
    let l:langs = ['bash', 'c', 'cpp', 'csharp', 'css', 'dart', 'diff', 'dockerfile',
        \ 'go', 'html', 'java', 'javascript', 'json', 'kotlin', 'lua', 'makefile',
        \ 'markdown', 'mermaid', 'php', 'powershell', 'python', 'ruby', 'rust',
        \ 'scss', 'sh', 'sql', 'swift', 'toml', 'typescript', 'vim', 'xml', 'yaml', 'zsh']
    return filter(l:langs, 'v:val =~# "^" . a:arglead')
endfunction

" テーブルを挿入
function! amnesia#table(opts) abort
    if !s:process_visual_selection(function('s:process_table'), a:opts)
        let line = line('.') - 1
        let table_lines = [
            \ '| Header1 | Header2 |',
            \ '| ------- | ------- |',
            \ '| Cell1   | Cell2   |'
            \ ]
        call append(line, table_lines)
    endif
endfunction

function! s:process_table(lines) abort
    let l:rows = []
    for l:line in a:lines
        if l:line !~ '^\s*$'
            call add(l:rows, s:split_table_row(l:line))
        endif
    endfor
    return s:build_table_lines(l:rows)
endfunction

" 脚注を挿入
function! amnesia#footnote(opts) abort
    if !s:process_visual_selection(function('s:process_footnote'), a:opts)
        call s:insert_at_cursor('[^1]: Footnote text')
    endif
endfunction

function! s:process_footnote(lines) abort
    let l:text = join(a:lines, ' ')
    let ref = substitute(a:lines[0], '\s\+', '_', 'g')
    " 脚注テキストを文書末尾に追加
    let last_line = line('$')
    call append(last_line, ['', '[^' . ref . ']: ' . l:text])
    return ['[^' . ref . ']']
endfunction

function! amnesia#indent_tree(opts) abort
    if get(a:opts, 'range', 0) == 0
        echoerr 'IndentTree requires a selected line range'
        return
    endif

    let start_line = a:opts.line1
    let end_line = a:opts.line2
    let lines = getline(start_line, end_line)
    let l:tree_result = s:build_tree_lines(lines)
    if has_key(l:tree_result, 'error')
        echoerr l:tree_result.error
        return
    endif

    let l:tree_lines = l:tree_result.lines
    call s:replace_lines(start_line, end_line, l:tree_lines)
    call cursor(start_line, 1)
endfunction

