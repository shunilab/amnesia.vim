" M7: link/image 統合実装の回帰テスト（挿入・URL判別・トグル解除）

%delete _
call setline(1, [''])
call cursor(1, 1)
call amnesia#link({'line1': 1, 'line2': 1, 'range': 0}, 'https://example.com')
call assert_equal('[](https://example.com)', getline(1))

%delete _
call setline(1, [''])
call cursor(1, 1)
call amnesia#image({'line1': 1, 'line2': 1, 'range': 0}, 'https://example.com/x.png')
call assert_equal('![](https://example.com/x.png)', getline(1))

" ビジュアル選択がURLならリンク/画像化、既にリンク/画像化された選択はトグル解除
%delete _
xmap <buffer> gg <Plug>(amnesia-link)
call setline(1, ['https://example.com'])
exe "normal 0v$gg"
call assert_equal('[](https://example.com)', getline(1))

%delete _
xmap <buffer> gg <Plug>(amnesia-link)
call setline(1, ['[foo](https://example.com)'])
exe "normal 0v$gg"
call assert_equal('foo', getline(1))

%delete _
xmap <buffer> gg <Plug>(amnesia-image)
call setline(1, ['![alt text](https://example.com/x.png)'])
exe "normal 0v$gg"
call assert_equal('https://example.com/x.png', getline(1))
