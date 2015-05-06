#!/bin/bash
#set -x

Test="Test4"

dir="$(realpath ../..)"
LC_ALL=C vim -u NONE -N \
    --cmd ':set noswapfile hidden' \
    -c "sil :so $dir/plugin/NrrwRgn.vim" \
    -c ':e 1.txt' \
    -c 'sil :1,$NR!' \
    -c 'sil :$put =\"Added Line\"' \
    -c ':w|b#' \
    -c ':saveas! 1.txt.mod' \
    -c '2b|w|b#|b#' \
    -c 'sil :$put =\"Added another Line\"' \
    -c ':w|b#|wq!'

rt=$(diff -uN0 <(cat *.mod) <(cat *.ok))
if [ "$?" -ne 0 ]; then
    printf "$Test failed\n"
    printf "Diff:\n%s\n" "$rt"
    exit 2;
else
    printf "$Test successful!\n"
fi
