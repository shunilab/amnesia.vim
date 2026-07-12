" MDStrike: `~~` ラップ・トグル解除の回帰テスト
"
" '~' は magic 正規表現で「直前の :s 置換文字列」を指すメタ文字であり、
" s:toggle_wrapped_text 側でエスケープを忘れるとトグル解除が壊れる
" （フレッシュセッションでは空文字列に展開され、パターンが `.*` 相当に
"  なって選択テキストをそのまま「トグル解除済み」として返してしまう）。
" このテストはその回帰を検出するために存在するので、エスケープ集合の
" 単純化・削除をしないこと。

%delete _
xmap <buffer> gg <Plug>(amnesia-strike)

call setline(1, ['abc'])
exe "normal 0v$gg"
call assert_equal('~~abc~~', getline(1))

exe "normal 0v$gg"
call assert_equal('abc', getline(1))
