" C1: s:replace_lines() が範囲外の後続行を破壊しないことの回帰テスト
" (MDCode はフェンス2行分・MDTable はセパレータ1行分、元範囲より結果が長くなる)

%delete _
call setline(1, ['code1', 'code2', 'AFTER1', 'AFTER2', 'AFTER3'])
1,2MDCode
call assert_equal(
    \ ['```', 'code1', 'code2', '```', 'AFTER1', 'AFTER2', 'AFTER3'],
    \ getline(1, '$'))

%delete _
call setline(1, ['a,b', 'c,d', 'AFTER'])
1,2MDTable
call assert_equal(
    \ ['| a | b |', '| --- | --- |', '| c | d |', 'AFTER'],
    \ getline(1, '$'))

" 逆に結果が短くなるケース（削除トグルで空行が減る）も後続行を保持すること
%delete _
call setline(1, ['- a', '- b', 'AFTER'])
1,2MDBullet
call assert_equal(['a', 'b', 'AFTER'], getline(1, '$'))
