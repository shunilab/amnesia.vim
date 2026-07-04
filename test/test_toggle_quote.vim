" MDQuote: トグルの回帰テスト

call setline(1, ['foo'])
1MDQuote
call assert_equal('> foo', getline(1))
1MDQuote
call assert_equal('foo', getline(1))
