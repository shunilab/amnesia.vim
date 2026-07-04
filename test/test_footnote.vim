" M6: MDFootnote の連番採番の回帰テスト

" 選択あり: 選択テキストを参照に置換し、定義を文書末尾へ追加
%delete _
xmap <buffer> gg <Plug>(amnesia-footnote)
call setline(1, ['some important text here'])
exe "normal 0wviwgg"
call assert_equal(
    \ ['some [^1] text here', '', '[^1]: important'],
    \ getline(1, '$'))

" 既存の脚注（数字）があれば、次の番号を採番する
%delete _
call setline(1, ['body[^1]', '', '[^1]: first note'])
call cursor(1, 1)
call amnesia#footnote({'range': 0})
call assert_equal(
    \ ['[^2]body[^1]', '', '[^1]: first note', '', '[^2]: '],
    \ getline(1, '$'))

" 名前付き脚注（[^note]）は数字ではないため採番対象から除外される
%delete _
call setline(1, ['body[^note]', '', '[^note]: named'])
call cursor(1, 1)
call amnesia#footnote({'range': 0})
call assert_equal(
    \ ['[^1]body[^note]', '', '[^note]: named', '', '[^1]: '],
    \ getline(1, '$'))
