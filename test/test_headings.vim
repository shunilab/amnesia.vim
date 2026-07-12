" MDH1〜H6: 同レベル再実行でトグル解除・別レベルは変換の回帰テスト

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

" H4/H5/H6 も同じ s:normalize_heading_line を level だけ変えて使うため、
" 代表としてトグル解除と別レベル変換のみ確認する
call setline(1, ['Title'])
call cursor(1, 1)
MDH4
MDH4
call assert_equal('Title', getline(1))

call setline(1, ['Title'])
call cursor(1, 1)
MDH5
MDH6
call assert_equal('###### Title', getline(1))
