" MDHighlight: `==` ラップ・トグル解除の回帰テスト

%delete _
xmap <buffer> gg <Plug>(amnesia-highlight)

call setline(1, ['abc'])
exe "normal 0v$gg"
call assert_equal('==abc==', getline(1))

exe "normal 0v$gg"
call assert_equal('abc', getline(1))
