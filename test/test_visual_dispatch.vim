" H1/H2/H3/M2: <Plug>マッピング経由のビジュアル選択ディスパッチの回帰テスト
" (amnesia#visual_dispatch が mode()/getpos('v')/getpos('.') から選択範囲を
"  取得し、その場でマークを設定するため、1文字選択や後続選択でも正しく動く)

%delete _
xmap <buffer> gg <Plug>(amnesia-bold)
call setline(1, ['abc'])
exe "normal 0vgg"
call assert_equal('**a**bc', getline(1))

" H2: 部分（charwise）選択でも行指向コマンドは行全体に適用される
%delete _
xmap <buffer> gg <Plug>(amnesia-bullet)
call setline(1, ['foo bar baz'])
exe "normal 0wviwgg"
call assert_equal('- foo bar baz', getline(1))

%delete _
xmap <buffer> gg <Plug>(amnesia-quote)
call setline(1, ['foo', 'bar', 'baz'])
exe "normal 0lvjllgg"
call assert_equal(['> foo', '> bar', 'baz'], getline(1, '$'))

" M2: 選択位置を変えて連続実行しても、常に最新の選択が使われる（マーク流用なし）
%delete _
xmap <buffer> gg <Plug>(amnesia-bold)
call setline(1, ['aaa bbb'])
exe "normal 0viwgg"
exe "normal $viwgg"
call assert_equal('**aaa** **bbb**', getline(1))
