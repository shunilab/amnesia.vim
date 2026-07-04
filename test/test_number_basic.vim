" MDNumber: 基本の連番付与の回帰テスト（ネスト記法自体は Phase4 で仕様変更するため対象外）

call setline(1, ['one', 'two', 'three'])
1,3MDNumber
call assert_equal(['1. one', '2. two', '3. three'], getline(1, '$'))
