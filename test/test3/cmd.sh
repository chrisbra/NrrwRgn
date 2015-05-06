#!/bin/bash
#set -x

Test="Test3"

dir="$(realpath ../..)"
LC_ALL=C vim -u NONE -N \
    --cmd ':set noswapfile hidden' \
    -c "sil :so $dir/plugin/NrrwRgn.vim" \
    -c 'sp description.md | noa wincmd p | :e 1.txt' \
    -c 'sil :1,$NR' \
    -c 'sil :$put =\"Added Line\"' \
    -c 'sil :wq' \
    -c '2wincmd w' \
    -c 'sil :$put =\"Added after Narrowing Line\"' \
    -c ':bufdo if bufname("")=~"^\\d\\.txt$"|saveas! %.mod|endif' \
    -c ':qa!'

rt=$(diff -uN0 <(cat *.mod) <(cat *.ok))
if [ "$?" -ne 0 ]; then
    printf "$Test failed\n"
    printf "Diff:\n%s" "$rt"
    exit 2;
else
    printf "$Test successful!\n"
fi
