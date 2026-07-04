" MDBullet: トグル・インデント保持・Ex範囲指定の回帰テスト

call setline(1, ['foo', '  bar'])
2MDBullet
call assert_equal('  - bar', getline(2))

call setline(1, ['  - bar'])
1MDBullet
call assert_equal('  bar', getline(1))

call setline(1, ['a', 'b', 'c'])
1,3MDBullet
call assert_equal(['- a', '- b', '- c'], getline(1, '$'))
