" -------------------------------------------------------------
" Last Change: 2010, Apr 27
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Version:	   0.1
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "histwin.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
"
" TODO: - currently this works only linewise.
"       - make it work with arbitrary selections.
"         (need to find out, how to select/copy arbitrary selections)
"       - mark the narrowed region (using signs?) in the orig buffer        

" Init:
let s:cpo= &cpo
set cpo&vim
if exists("g:loaded_nrrw_rgn") || &cp
  finish
endif

let g:loaded_nrrw_rgn = 1

" Functions:
fun! s:Init()"{{{1
		if !exists("s:nrrw_winname")
				let s:nrrw_winname='Narrow_Region'
		endif
		if bufname('') != s:nrrw_winname
				let s:orig_buffer = bufnr('')
		endif

		" Customization
		let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert") ? g:nrrw_rgn_vert : 0)
		let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth") ? g:nrrw_rgn_wdth : 30)
		
endfun 

fun! s:NrwRgnWin() "{{{1
		let nrrw_win = bufwinnr('^'.s:nrrw_winname.'$')
		if nrrw_win != -1
			exe ":noa " . nrrw_win . 'wincmd w'
			silent %d_
			noa wincmd p
		else
			execute s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . s:nrrw_winname
			setl noswapfile buftype=acwrite bufhidden=delete foldcolumn=0 nobuflisted winfixwidth
			let nrrw_win = bufwinnr("")
		endif
		return nrrw_win
endfu

fun! s:NrrwRgn() range  "{{{1
	let o_lz=&lz
	set lz
	" Protect the original buffer,
	" so you won't accidently modify those lines,
	" that will later be overwritten
	setl noma
	let orig_buf=bufnr('')

	" initialize Variables
	call s:Init()
	let ft=&l:ft
	let b:startline = a:firstline
	let b:endline   = a:lastline
	let a=getline(b:startline, b:endline)
	let win=s:NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	com! -buffer WidenRegion :call s:WidenRegion()
	aug NrrwRgn
		au!
		au BufWriteCmd <buffer> :if (&l:mod)|setl nomod|exe ":WidenRegion"|else|q!|endif
	aug end

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfun

fu! s:WidenRegion() "{{{1
	let nrw_buf  = bufnr('')
	let orig_win = bufwinnr(b:orig_buf)
	let cont     = getline(1,'$')
	exe ':noa' . orig_win . 'wincmd w'
	if !(&l:ma)
		setl ma
	endif
	exe ':silent :'.b:startline.','.b:endline.'d _'
	call append((b:startline-1),cont)
	exe ':silent :bd!' nrw_buf
endfu

com! -range NarrowRegion :exe ":" . <line1> . ',' . <line2> . "call s:NrrwRgn()"
    
" Restore:
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\" spell spelllang=en
