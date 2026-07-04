" MDTable: CSV -> テーブル変換の回帰テスト

call setline(1, ['a,b', 'c,d'])
1,2MDTable
call assert_equal(['| a | b |', '| --- | --- |', '| c | d |'], getline(1, '$'))
