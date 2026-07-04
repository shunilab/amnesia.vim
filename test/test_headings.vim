" MDH1/H2/H3: 同レベル再実行でトグル解除・別レベルは変換の回帰テスト

" 明示的な Ex 範囲指定は非対応のため、カーソル位置での実行のみをテストする
call setline(1, ['Title'])
call cursor(1, 1)
MDH1
MDH1
call assert_equal('Title', getline(1))

call setline(1, ['Title'])
call cursor(1, 1)
MDH1
MDH2
call assert_equal('## Title', getline(1))
