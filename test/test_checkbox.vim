" MDCheck / MDCheckDone: トグル・相互変換の回帰テスト

call setline(1, ['task'])
1MDCheck
call assert_equal('- [ ] task', getline(1))
1MDCheck
call assert_equal('task', getline(1))

call setline(1, ['- [ ] task'])
1MDCheckDone
call assert_equal('- [x] task', getline(1))
1MDCheckDone
call assert_equal('task', getline(1))

" M5: 既存の箇条書き行はマーカーを二重にせず昇格させる
call setline(1, ['- task'])
1MDCheck
call assert_equal('- [ ] task', getline(1))
