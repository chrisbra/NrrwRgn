" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.13
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Sun, 22 Aug 2010 14:59:59 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to NrrwRgn.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 13 :AutoInstall: NrrwRgn.vim
"
" Functions:

fun! <sid>WarningMsg(msg)"{{{1
	echohl WarningMsg
	let msg = "NarrowRegion: " . a:msg
	if exists(":unsilent") == 2
		unsilent echomsg msg
	else
		echomsg msg
	endif
	echohl Normal
	let v:errmsg = msg
endfun

fun! <sid>Init()"{{{1
    if !exists("s:instn")
		let s:instn=1
    else
		let s:instn+=1
    endif
	if !exists("s:nrrw_rgn_lines")
		let s:nrrw_rgn_lines = {}
	endif
	let s:nrrw_rgn_lines[s:instn] = {}
    let s:nrrw_winname='Narrow_Region'

    " Customization
    let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert")  ? g:nrrw_rgn_vert   : 0)
    let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth")  ? g:nrrw_rgn_wdth   : 20)
    let s:nrrw_rgn_hl   = (exists("g:nrrw_rgn_hl")    ? g:nrrw_rgn_hl     : "WildMenu")
    let s:nrrw_rgn_nohl = (exists("g:nrrw_rgn_nohl")  ? g:nrrw_rgn_nohl   : 0)

    let s:debug=1
	if exists("s:debug") && s:debug
		com! NI :call <sid>WarningMsg("Instance: ".s:instn)
		com! NJ :call <sid>WarningMsg("Data: ".string(s:nrrw_rgn_lines))
	endif
		
endfun 

fun! <sid>NrwRgnWin() "{{{1
	let s:nrrw_winname .= '_' . s:instn
    let nrrw_win = bufwinnr('^'.s:nrrw_winname.'$')
    if nrrw_win != -1
		exe ":noa " . nrrw_win . 'wincmd w'
		silent %d _
		noa wincmd p
    else
		exe 'topleft ' . s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . s:nrrw_winname
		setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted
		let nrrw_win = bufwinnr("")
    endif
    return nrrw_win
endfu

fun! nrrwrgn#NrrwRgn() range  "{{{1
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that might later be overwritten
	setl noma
	let ft=&l:ft
	let s:nrrw_rgn_lines[s:instn].startline = [ a:firstline, 0 ]
	let s:nrrw_rgn_lines[s:instn].endline   = [ a:lastline, 0 ]
	if exists("s:nrrw_rgn_lines[s:instn].matchid")
	    " if you call :NarrowRegion several times, without widening 
	    " the previous region, b:matchid might already be defined so
	    " make sure, the previous highlighting is removed.
	    call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
	endif
	if !s:nrrw_rgn_nohl
	    let s:nrrw_rgn_lines[s:instn].matchid =  matchadd(s:nrrw_rgn_hl, 
		\<sid>GeneratePattern(
		\s:nrrw_rgn_lines[s:instn].startline, 
		\s:nrrw_rgn_lines[s:instn].endline, 
		\'V')) "set the highlighting
	endif
	let a=getline(
	    \s:nrrw_rgn_lines[s:instn].startline[0], 
	    \s:nrrw_rgn_lines[s:instn].endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	let b:nrrw_instn = s:instn
	setl nomod
	"com! -buffer WidenRegion :call nrrwrgn#WidenRegion(0) |sil bd!
    com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(0, (empty("<bang>") ? 0 : 1))
	call <sid>NrrwRgnAuCmd(0)

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfun

fu! s:WriteNrrwRgn(...) "{{{1
	if (bufwinnr(b:orig_buf) == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
    if &l:mod && exists("a:1") && a:1
		" Write the buffer back to the original buffer
		setl nomod
		exe ":WidenRegion"
    else
		call setbufvar(b:orig_buf, '&ma', 1)
		exe ':noa' . bufwinnr(b:orig_buf) . 'wincmd w'
		"if exists("s:nrrw_rgn_lines[s:instn].matchid")
		"	call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
		"	unlet s:nrrw_rgn_lines[s:instn].matchid
		"endif
    endif
endfun

fu! nrrwrgn#WidenRegion(vmode,force) "{{{1
    let nrw_buf  = bufnr('')
    let orig_win = bufwinnr(b:orig_buf)
	if (orig_win == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
    let cont     = getline(1,'$')
	let instn    = b:nrrw_instn
    call <sid>SaveRestoreRegister(1)
    exe ':noa' . orig_win . 'wincmd w'
	let wsv=winsaveview()
    if !(&l:ma)
		setl ma
    endif
    if a:vmode "charwise, linewise or blockwise selection 
		call setreg('a', join(cont, "\n") . "\n", s:nrrw_rgn_lines[instn].vmode)
		if s:nrrw_rgn_lines[instn].vmode == 'v'
		   " in characterwise selection, remove trailing \n
		   call setreg('a', substitute(@a, '\n$', '', ''), 
			   \s:nrrw_rgn_lines[instn].vmode)
		endif
		exe "keepj" s:nrrw_rgn_lines[instn].startline[0]
		exe "keepj norm!" s:nrrw_rgn_lines[instn].startline[1] . '|'
		exe "keepj norm!" s:nrrw_rgn_lines[instn].vmode
		exe "keepj" s:nrrw_rgn_lines[instn].endline[0]
		exe "keepj norm!" s:nrrw_rgn_lines[instn].endline[1] . '|'
		norm! "aP
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		let [ s:nrrw_rgn_lines[instn].startline, 
			 \s:nrrw_rgn_lines[instn].endline ] = <sid>RetVisRegionPos()
		" also, renew the highlighted region
		if exists("s:nrrw_rgn_lines[instn].matchid")
			" if you call :NarrowRegion several times, without widening 
			" the previous region, b:matchid might already be defined so
			" make sure, the previous highlighting is removed.
			call matchdelete(s:nrrw_rgn_lines[instn].matchid)
		endif
		if !s:nrrw_rgn_nohl
			let s:nrrw_rgn_lines[instn].matchid =  matchadd(s:nrrw_rgn_hl, 
			\<sid>GeneratePattern(
			\s:nrrw_rgn_lines[instn].startline, 
			\s:nrrw_rgn_lines[instn].endline, 
			\s:nrrw_rgn_lines[instn].vmode))
		endif
    else "linewise selection because we started the NarrowRegion with the command NarrowRegion(0)
		"
		" if the endposition of the narrowed buffer is also the last line of
		" the buffer, the append will add an extra newline that needs to be
		" cleared.
		if s:nrrw_rgn_lines[instn].endline[0]==line('$') &&
		\  s:nrrw_rgn_lines[instn].startline[0] == 1
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
		exe ':silent :'.s:nrrw_rgn_lines[instn].startline[0].','
			\.s:nrrw_rgn_lines[instn].endline[0].'d _'
		call append((s:nrrw_rgn_lines[instn].startline[0]-1),cont)
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		" so subsequent calls will adjust the region accordingly
	    let  s:nrrw_rgn_lines[instn].endline[0] =
			\s:nrrw_rgn_lines[instn].startline[0] + len(cont) -1
		if s:nrrw_rgn_lines[instn].endline[0] > line('$')
			let s:nrrw_rgn_lines[instn].endline[0] = line('$')
		endif
		" also, renew the highlighted region
		if exists("s:nrrw_rgn_lines[instn].matchid")
			" if you call :NarrowRegion several times, without widening 
			" the previous region, b:matchid might already be defined so
			" make sure, the previous highlighting is removed.
			call matchdelete(s:nrrw_rgn_lines[instn].matchid)
		endif
		if !s:nrrw_rgn_nohl
			let s:nrrw_rgn_lines[instn].matchid =  matchadd(s:nrrw_rgn_hl, 
			\<sid>GeneratePattern(
			\s:nrrw_rgn_lines[instn].startline, 
			\s:nrrw_rgn_lines[instn].endline, 
			\'V'))
		endif
	    if delete_last_line
			:$d _
	    endif
    endif
    call <sid>SaveRestoreRegister(0)
    let  @/=s:o_s
	call winrestview(wsv)
    " jump back to narrowed window
    exe ':noa' . bufwinnr(nrw_buf) . 'wincmd w'
    "call <sid>NrrwRgnAuCmd(0)
	"exe ':silent :bd!' nrw_buf
	setl nomod
	if a:force
		"exe 'bd! ' nrw_buf
		:bd!
	endif
endfu

fu! <sid>SaveRestoreRegister(mode) "{{{1
    if a:mode
		let s:savereg  = getreg('a')
		let s:saveregt = getregtype('a')
    else
		call setreg('a', s:savereg, s:saveregt)
    endif
endfu!

fu! nrrwrgn#VisualNrrwRgn(mode) "{{{1
    if empty(a:mode)
		" in case, visual mode wasn't entered, visualmode()
		" returns an empty string and in that case, we finish
		" here
		call <sid>WarningMsg("There was no region visually selected!")
		return
    endif
    " This beeps, when called from command mode
    " e.g. by using :NRV, so using :sil!
    " else exiting visual mode
    exe "sil! norm! \<ESC>"
    " stop visualmode
    let o_lz = &lz
    let s:o_s  = @/
    set lz
    call <sid>Init()
    let s:nrrw_rgn_lines[s:instn].vmode=a:mode
    " Protect the original buffer,
    " so you won't accidentally modify those lines,
    " that will later be overwritten
    setl noma
    let orig_buf=bufnr('')
    call <sid>SaveRestoreRegister(1)

    let ft=&l:ft
    let [ s:nrrw_rgn_lines[s:instn].startline, s:nrrw_rgn_lines[s:instn].endline ] = <sid>RetVisRegionPos()
    if exists("s:nrrw_rgn_lines[s:instn].matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
    endif
    if !s:nrrw_rgn_nohl
		let s:nrrw_rgn_lines[s:instn].matchid =  matchadd(s:nrrw_rgn_hl, 
		\<sid>GeneratePattern(s:nrrw_rgn_lines[s:instn].startline, s:nrrw_rgn_lines[s:instn].endline, s:nrrw_rgn_lines[s:instn].vmode))
    endif
    norm gv"ay
    let win=<sid>NrwRgnWin()
    exe ':noa ' win 'wincmd w'
    let b:orig_buf = orig_buf
    silent put a
	let b:nrrw_instn = s:instn
    silent 0d _
    setl nomod
    "com! -buffer WidenRegion :call nrrwrgn#WidenRegion(1)|sil bd!
    com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(1, (empty("<bang>") ? 0 : 1))
    call <sid>NrrwRgnAuCmd(0)
    call <sid>SaveRestoreRegister(0)

    " restore settings
    let &l:ft = ft
    let &lz   = o_lz
endfu

fu! <sid>NrrwRgnAuCmd(bufnr) "{{{1
	" If a:bufnr==0, then enable auto commands
	" else disable auto commands for a:bufnr
    if !a:bufnr
		exe "aug NrrwRgn" . b:nrrw_instn
			au!
			au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
			exe "au BufWipeout,BufDelete <buffer> nested :call s:WriteNrrwRgn()|:call <sid>NrrwRgnAuCmd(".b:nrrw_instn.")"
		aug end
    else
		exe "aug NrrwRgn" .  a:bufnr
		au!
		aug end
		exe "aug! NrrwRgn" . a:bufnr
		if exists("s:nrrw_rgn_lines[a:bufnr].matchid")
			call matchdelete(s:nrrw_rgn_lines[a:bufnr].matchid)
			unlet s:nrrw_rgn_lines[a:bufnr].matchid
		endif
		if s:instn>0
			unlet s:nrrw_rgn_lines[a:bufnr]
			let s:instn-=1
		endif
    endif
endfun

fu! <sid>RetVisRegionPos() "{{{1
    let startline = [ getpos("'<")[1], virtcol("'<") ]
    let endline   = [ getpos("'>")[1], virtcol("'>") ]
    return [ startline, endline ]
endfu

fun! <sid>GeneratePattern(startl, endl, mode) "{{{1
    if a:mode ==# ''
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\&\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
    elseif a:mode ==# 'v'
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\_.*\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
    else
		return '\%>' . (a:startl[0]-1) . 'l\&\%<' . (a:endl[0]+1) . 'l'
    endif
endfun "}}}
fun! nrrwrgn#UnifiedDiff() "{{{1
	let save_winposview=winsaveview()
	let orig_win = winnr()
	" close previous opened Narrowed buffers
	silent! windo | if bufname('')=~'^Narrow_Region' && &diff |diffoff|q!|endif
	" minimize Window
	" this is disabled, because this might be useful, to see everything
	"exe "vert resize -999999"
	"setl winfixwidth
	" move to current start of chunk of unified diff
	if search('^@@', 'bcW') > 0
		call search('^@@', 'bc')
	else
		call search('^@@', 'c')
	endif
	let curpos=getpos('.')
	for i in range(2)
		if search('^@@', 'nW') > 0
			.+,/@@/-NR
		else
			" Last chunk in file
			.+,$NR
		endif
	   " Split vertically
	   wincmd H
	   if i==0
		   silent! g/^-/d _
	   else
		   silent! g/^+/d _
	   endif
	   diffthis
	   0
	   exe ":noa wincmd p"
	   call setpos('.', curpos)
	endfor
	call winrestview(save_winposview)
endfun
	

" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
