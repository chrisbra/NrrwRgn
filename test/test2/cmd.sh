#!/bin/bash
#set -x

Test="Test2"

dir="$(realpath ../..)"
LC_ALL=C vim -u NONE -N \
    --cmd ':set noswapfile hidden' \
    -c "sil :so $dir/plugin/NrrwRgn.vim" \
    -c 'sil :1,$NR' \
    -c 'sil :$put =\"Added Line\"' \
    -c 'sil :wq' \
    -c 'sil :$put =\"Added after Narrowing Line\"' \
    -c ':bufdo if bufname("")=~"^\\d\\.txt$"|saveas! %.mod|endif' \
    -c ':qa!' 1.txt

rt=$(diff -uN0 <(cat *.mod) <(cat *.ok))
if [ "$?" -ne 0 ]; then
    printf "$Test failed\n"
    printf "Diff:\n%s" "$rt"
    exit 2;
else
    printf "$Test successful!\n"
fi
