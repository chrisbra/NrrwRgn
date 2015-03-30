#!/bin/bash
#set -x

dir="$(realpath ../..)"
LC_ALL=C vim -u NONE -N \
    --cmd ':set noswapfile hidden' \
    --cmd 'argadd *.txt' \
    -c "sil :so $dir/plugin/NrrwRgn.vim" \
    -c 'sil :bufdo :NRP' \
    -c 'sil :NRM' \
    -c 'sil :g/^foobar.*/s//& some more stuff/' \
    -c 'sil :wq' \
    -c ':bufdo if bufname("")=~"^\\d\\.txt$"|saveas! %.mod|endif' \
    -c ':qa!'

rt=$(diff -uN0 <(cat *.mod) <(cat *.ok))
if [ "$?" -ne 0 ]; then
    printf "Test1 failed\n"
    printf "Diff:\n%s" "$rt"
    exit 2;
else
    printf "Test1 successful!\n"
fi
