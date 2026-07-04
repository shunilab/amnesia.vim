" H3: blockwise（Ctrl-V）選択でインライン系コマンドを実行するとエラーになり、
" バッファが変更されないことの回帰テスト

xmap <buffer> gg <Plug>(amnesia-bold)
call setline(1, ['line1', 'line2'])
let v:errmsg = ''
try
    exe "normal gg0\<C-v>jlgg"
catch
    " echoerr は Vim script 内では例外として捕捉される
endtry
call assert_equal(['line1', 'line2'], getline(1, '$'))
