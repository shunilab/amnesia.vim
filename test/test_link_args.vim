" MDLink 引数パーサ: クォート・スペースを含む引数の回帰テスト

call setline(1, [''])
call cursor(1, 1)
call amnesia#link({'line1': 1, 'line2': 1, 'range': 0}, '"foo bar" https://example.com')
call assert_equal('[foo bar](https://example.com)', getline(1))
