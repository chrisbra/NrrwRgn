" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/NrrwRgn.vim	[[[1
51
" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.18
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 10 Dec 2010 15:16:29 +0100
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 18 :AutoInstall: NrrwRgn.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_nrrw_rgn") || &cp
  finish
endif
set cpo&vim
let g:loaded_nrrw_rgn = 1

" ------------------------------------------------------------------------------
" Public Interface: {{{1

" Define the Command aliases "{{{2
com! -range NRPrepare :<line1>,<line2>NRP
com! -range NarrowRegion :<line1>,<line2>NR
com! NRMulti :NRM
com! NarrowWindow :NW

" Define the actual Commands "{{{2
com! -range NR	 :<line1>, <line2>call nrrwrgn#NrrwRgn()
com! -range NRP  :exe ":" . <line1> . ',' . <line2> . "call nrrwrgn#Prepare()"
com! NRV :call nrrwrgn#VisualNrrwRgn(visualmode())
com! NUD :call nrrwrgn#UnifiedDiff()
com! NW	 :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn()"
com! NRM :call nrrwrgn#NrrwRgnDoPrepare()

" Define the Mapping: "{{{2
if !hasmapto('<Plug>NrrwrgnDo')
	xmap <unique> <Leader>nr <Plug>NrrwrgnDo
endif
xnoremap <unique> <script> <Plug>NrrwrgnDo <sid>VisualNrrwRgn
xnoremap <sid>VisualNrrwRgn :<c-u>call nrrwrgn#VisualNrrwRgn(visualmode())<cr>

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
autoload/nrrwrgn.vim	[[[1
677
" nrrwrgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.18
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 10 Dec 2010 15:16:29 +0100
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to NrrwRgn.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 18 :AutoInstall: NrrwRgn.vim
"
" Functions:

fun! <sid>WarningMsg(msg) "{{{1
	let msg = "NarrowRegion: " . a:msg
	echohl WarningMsg
	if exists(":unsilent") == 2
		unsilent echomsg msg
	else
		echomsg msg
	endif
	sleep 1
	echohl Normal
	let v:errmsg = msg
endfun

fun! <sid>Init() "{{{1
	if !exists("s:instn")
		let s:instn=1
		let s:opts=<sid>Options('local to buffer')
	else
		let s:instn+=1
	endif
	if !exists("s:nrrw_rgn_lines")
		let s:nrrw_rgn_lines = {}
	endif
	let s:nrrw_rgn_lines[s:instn] = {}
	" show some debugging messages
	let s:nrrw_winname='Narrow_Region'

	" Customization
	let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert")  ? g:nrrw_rgn_vert   : 0)
	let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth")  ? g:nrrw_rgn_wdth   : 20)
	let s:nrrw_rgn_hl	= (exists("g:nrrw_rgn_hl")	  ? g:nrrw_rgn_hl	  : "WildMenu")
	let s:nrrw_rgn_nohl = (exists("g:nrrw_rgn_nohl")  ? g:nrrw_rgn_nohl   : 0)

	let s:debug = 1
		
endfun 

fun! <sid>NrwRgnWin() "{{{1
	let local_options = s:GetOptions(s:opts)
	let nrrw_winname = s:nrrw_winname . '_' . s:instn
	let nrrw_win = bufwinnr('^'.nrrw_winname.'$')
	if nrrw_win != -1
		exe ":noa " . nrrw_win . 'wincmd w'
		" just in case, a global nomodifiable was set 
		" disable this for the narrowed window
		setl ma
		silent %d _
		noa wincmd p
	else
		exe 'topleft ' . s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . nrrw_winname
		" just in case, a global nomodifiable was set 
		" disable this for the narrowed window
		setl ma
		" Just in case
		silent %d _
		setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted
		let nrrw_win = bufwinnr("")
	endif
	call <sid>SetOptions(local_options)
	return nrrw_win
endfu

fun! nrrwrgn#NrrwRgn() range  "{{{1
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
    call <sid>CheckProtected()
	let s:nrrw_rgn_lines[s:instn].startline = [ a:firstline, 0 ]
	let s:nrrw_rgn_lines[s:instn].endline	= [ a:lastline, 0 ]
	call <sid>DeleteMatches()
	" Set the highlighting
	call <sid>AddMatches(<sid>GeneratePattern(
		\s:nrrw_rgn_lines[s:instn].startline, 
		\s:nrrw_rgn_lines[s:instn].endline, 
		\'V'))
	let a=getline(
		\s:nrrw_rgn_lines[s:instn].startline[0], 
		\s:nrrw_rgn_lines[s:instn].endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	let b:nrrw_instn = s:instn
	"com! -buffer WidenRegion :call nrrwrgn#WidenRegion(0) |sil bd!
	com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(0, (empty("<bang>") ? 0 : 1))
	call <sid>NrrwRgnAuCmd(0)

	" restore settings
	let &lz   = o_lz
endfun

fun! nrrwrgn#Prepare() "{{{1
	if !exists("s:nrrw_rgn_line") | let s:nrrw_rgn_line=[] | endif
	call add(s:nrrw_rgn_line, line('.'))
endfun

fun! <sid>CleanRegions() "{{{1
	 let s:nrrw_rgn_line=[]
endfun

fun! <sid>CompareNumbers(a1,a2) "{{{1
	return (a:a1+0) == (a:a2+0) ? 0
				\: (a:a1+0) > (a:a2+0) ? 1
				\: -1
endfun

fun! nrrwrgn#NrrwRgnDoPrepare() "{{{1
	let s:nrrw_rgn_buf =  <sid>ParseList(s:nrrw_rgn_line)
	if empty(s:nrrw_rgn_buf)
		call <sid>WarningMsg("You need to first select the lines to narrow using NRP!")
	   return
	endif
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
    call <sid>CheckProtected()
	let s:nrrw_rgn_lines[s:instn].startline = []
	let s:nrrw_rgn_lines[s:instn].endline	= []
	let s:nrrw_rgn_lines[s:instn].multi     = s:nrrw_rgn_buf
	call <sid>DeleteMatches()

	let nr=0
	let lines=[]
	let buffer=[]

	let keys = keys(s:nrrw_rgn_buf)
	call sort(keys,"<sid>CompareNumbers")
	"for [ nr,lines] in items(s:nrrw_rgn_buf)
	let comment=<sid>ReturnCommentFT()
	for nr in keys
		let lines = s:nrrw_rgn_buf[nr]
		let start = lines[0]
		let end   = len(lines)==2 ? lines[1] : lines[0]
"		call <sid>AddMatches('\%>'.(start-1).'l\%<'.(end+1).'l')"
		call <sid>AddMatches(<sid>GeneratePattern([start,0], [end,0], 'V'))
"		if !s:nrrw_rgn_nohl
"			if !exists("s:nrrw_rgn_lines[s:instn].matchid")
"				let s:nrrw_rgn_lines[s:instn].matchid=[]
"			endif
"			exe "call add(s:nrrw_rgn_lines[s:instn].matchid, matchadd(s:nrrw_rgn_hl, '\\%>".(start-1)."l\\%<".(end+1)."l'))"
"		endif
		call add(buffer, comment.' Start NrrwRgn'.nr)
		let buffer = buffer +
				\ getline(start,end) +
				\ [comment.' End NrrwRgn'.nr, '']
	endfor

	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, buffer)
	setl nomod
	let b:nrrw_instn = s:instn
	com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(0, (empty("<bang>") ? 0 : 1))
	call <sid>NrrwRgnAuCmd(0)
	call <sid>CleanRegions()

	" restore settings
	let &lz   = o_lz
endfun

fun! <sid>ParseList(list) "{{{1
     let result={}
     let start=0
     let temp=0
     let i=1
     for item in sort(a:list, "<sid>CompareNumbers")
         if start==0
            let start=item
         endif
         if temp==item-1
             let result[i]=[start,item]
         else
             let start=item
             let result[i]=[item]
             let i+=1
         endif
         let temp=item
     endfor
     return result
endfun


fu! s:WriteNrrwRgn(...) "{{{1
	" if argument is given, write narrowed buffer back
	" else destroy the narrowed window
	let nrrw_instn = exists("b:nrrw_instn") ? b:nrrw_instn : s:instn
	if exists("b:orig_buf") && (bufwinnr(b:orig_buf) == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	if &l:mod && exists("a:1") && a:1
		" Write the buffer back to the original buffer
		setl nomod
		exe ":WidenRegion"
		if bufname('') !~# 'Narrow_Region'
			exe ':noa' . bufwinnr(s:nrrw_winname . '_' . s:instn) . 'wincmd w'
			"exe ':noa' . bufwinnr(nrrw_instn) . 'wincmd w'
		endif
"		call setbufvar(b:orig_buf, '&ma', 1)
"	 elseif &l:mod
	else
		" Best guess
		if bufname('') =~# 'Narrow_Region'
			exe ':noa' . bufwinnr(b:orig_buf) . 'wincmd w'
		endif
		if !exists("a:1") 
			" close narrowed buffer
			call <sid>NrrwRgnAuCmd(nrrw_instn)
		endif
	endif
"	if bufwinnr(nrrw_instn) != -1
"		exe ':noa' . bufwinnr(nrrw_instn) . 'wincmd w'
"	endif
endfun

fu! nrrwrgn#WidenRegion(vmode,force) "{{{1
	let nrw_buf  = bufnr('')
	let orig_win = bufwinnr(b:orig_buf)
	if (orig_win == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	let cont	 = getline(1,'$')
	let instn	 = b:nrrw_instn
	exe ':noa' . orig_win . 'wincmd w'
	call <sid>SaveRestoreRegister(1)
	let wsv=winsaveview()
	if exists("b:orig_buf_ro") && b:orig_buf_ro && !a:force
	   call s:WarningMsg("Original buffer protected. Can't write changes!")
	   :noa wincmd p
	   return
	endif
	if !&l:ma && !( exists("b:orig_buf_ro") && b:orig_buf_ro)
		setl ma
	endif
	call <sid>DeleteMatches()
	" Multiselection
	if has_key(s:nrrw_rgn_lines[instn], 'multi')
		call <sid>WidenRegionMulti(cont, instn)
	elseif a:vmode "charwise, linewise or blockwise selection 
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
		call <sid>AddMatches()
		if !s:nrrw_rgn_nohl
			let pattern=<sid>GeneratePattern(
			\s:nrrw_rgn_lines[s:instn].startline, 
			\s:nrrw_rgn_lines[s:instn].endline, 
			\s:nrrw_rgn_lines[instn].vmode)
			if !empty(pattern)
				let s:nrrw_rgn_lines[s:instn].matchid=[]
				call add(s:nrrw_rgn_lines[instn].matchid, matchadd(s:nrrw_rgn_hl, pattern))
			endif
		endif
	else 
		" linewise selection because we started the NarrowRegion with the
		" command NarrowRegion(0)
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
		call <sid>AddMatches(<sid>GeneratePattern(
			\s:nrrw_rgn_lines[instn].startline, 
			\s:nrrw_rgn_lines[instn].endline, 
			\'V'))
		if delete_last_line
			silent! $d _
		endif
	endif
	call <sid>SaveRestoreRegister(0)
	let  @/=s:o_s
	call winrestview(wsv)
	" jump back to narrowed window
	exe ':noa ' . bufwinnr(nrw_buf) . 'wincmd w'
	setl nomod
	if a:force
		" execute auto command
		bw
	endif
endfu

fu! <sid>SaveRestoreRegister(mode) "{{{1
	if a:mode
		let s:savereg  = getreg('a')
		let s:saveregt = getregtype('a')
		let s:fold = 0
		if &fen
			let s:fold=1
			setl nofoldenable
			let s:fdm = &l:fdm
		endif
	else
		call setreg('a', s:savereg, s:saveregt)
		if s:fold
			setl foldenable
			if exists("s:fdm")
				let &l:fdm=s:fdm
			endif
		endif
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
	let orig_buf=bufnr('')
	call <sid>SaveRestoreRegister(1)

	call <sid>CheckProtected()
	let [ s:nrrw_rgn_lines[s:instn].startline, s:nrrw_rgn_lines[s:instn].endline ] = <sid>RetVisRegionPos()
	call <sid>DeleteMatches()
	call <sid>AddMatches(<sid>GeneratePattern(s:nrrw_rgn_lines[s:instn].startline,
					\s:nrrw_rgn_lines[s:instn].endline, s:nrrw_rgn_lines[s:instn].vmode))
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
	let &lz   = o_lz
endfu

fu! <sid>NrrwRgnAuCmd(bufnr) "{{{1
	" If a:bufnr==0, then enable auto commands
	" else disable auto commands for a:bufnr
	if !a:bufnr
		exe "aug NrrwRgn" . b:nrrw_instn
			au!
			au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
			au BufWinLeave,BufWipeout,BufDelete <buffer> nested :call s:WriteNrrwRgn()
		aug end
	else
		exe "aug NrrwRgn" .  a:bufnr
		au!
		aug end
		exe "aug! NrrwRgn" . a:bufnr
		call <sid>DeleteMatches()
		if !&ma
			setl ma
		endif
"		if s:debug
"			echo printf("bufnr: %d a:bufnr: %d\n", bufnr(''), a:bufnr)
"			echo "bwipe " s:nrrw_winname . '_' . a:bufnr
"		endif
		exe "bwipe! " bufnr(s:nrrw_winname . '_' . a:bufnr)
		if s:instn>1
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
	if a:mode ==# '' && a:startl[0] > 0 && a:startl[1] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\&\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	elseif a:mode ==# 'v' && a:startl[0] > 0 && a:startl[1] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\_.*\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	elseif a:startl[0] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%<' . (a:endl[0]+1) . 'l'
	else
		return ''
	endif
endfun 

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

fun! <sid>Options(search) "{{{1
	let c=[]
	let buf=bufnr('')
	try
		" empty search pattern
		if empty(a:search)
			return c
		endif
		silent noa sview $VIMRUNTIME/doc/options.txt
		" for whatever reasons $VIMRUNTIME/doc/options.txt
		" does not exist, return empty list
		if line('$') == 1
			return c
		endif
		keepj 0
		let reg_a=[]
		call add(reg_a,getreg('a'))
		call add(reg_a, getregtype('a'))
		let @a=''
		exe "silent :g/" . '\v'.escape(a:search, '\\/') . "/-y A"
		let b=split(@a, "\n")
		call setreg('a', reg_a[0], reg_a[1])
		call filter(b, 'v:val =~ "^''"')
		" the following options should be set
		let filter_opt='\%(modifi\%(ed\|able\)\|readonly\|noswapfile\|buftype\|bufhidden\|foldcolumn\|buflisted\)'
		call filter(b, 'v:val !~ "^''".filter_opt."''"')
		for item in b
			let item=substitute(item, '''', '', 'g')
			call add(c, split(item, '\s\+')[0])
		endfor
	finally
		if fnamemodify(bufname(''),':p') ==
		   \expand("$VIMRUNTIME/doc/options.txt")
			bwipe
		endif
		exe "noa "	bufwinnr(buf) "wincmd  w"
		return c
	endtry
endfun

fun! <sid>GetOptions(opt) "{{{1
	 let result={}
	 for item in a:opt
		 exe "let result[item]=&l:".item
	 endfor
	 return result
endfun

fun! <sid>SetOptions(opt) "{{{1
	 if type(a:opt) == type({})
		for [option, result] in items(a:opt)
			exe "let &l:". option " = " string(result)
		endfor
	 endif
	 setl nomod noro
endfun

fun! <sid>CheckProtected() "{{{1
	let b:orig_buf_ro=0
	if !&l:ma || &l:ro
		let b:orig_buf_ro=1
		call s:WarningMsg("Buffer is protected, won't be able to write the changes back!")
	else 
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that might later be overwritten
		setl noma
	endif
endfun

fun! <sid>DeleteMatches() "{{{1
	if exists("s:nrrw_rgn_lines[s:instn].matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		for item in s:nrrw_rgn_lines[s:instn].matchid
			if item > 0
				" If the match has been deleted, discard the error
				silent call matchdelete(item)
			endif
		endfor
		let s:nrrw_rgn_lines[s:instn].matchid=[]
	endif
endfun

fun! <sid>HideNrrwRgnLines() "{{{1
	 syn region StartNrrwRgnIgnore start="^# Start NrrwRgn\z(\d\+\).*$" fold
	 syn region EndNrrwRgnIgnore start="^# End NrrwRgn\z1\d\+.*$" end="^$" fold
	 hi def link StartNrrwRgnIgnore Ignore
	 hi def link EndNrrwRgnIgnore Ignore
endfun

fun! <sid>ReturnCommentFT() "{{{1
	" Vim
	if &l:ft=="vim"
		return '"'
	" Perl, PHP, Ruby, Python, Sh
	elseif &l:ft=~"^\(perl\|php\|ruby\|python\|sh\)$"
	    return '#'
	" C, C++
	elseif &l:ft=~"^\(c\%(pp\)\?\|java\)"
		return '//'
	" HTML, XML
	elseif &l:ft=~"^\(ht\|x\)ml\?$"
		return '<!-- -->'
	" LaTex
	elseif &l:ft=~"^\(la\)tex"
		return '%'
	else
		" Fallback
		return '#'
	endif
endfun

fun! <sid>WidenRegionMulti(content, instn) "{{{1
	if empty(s:nrrw_rgn_lines[a:instn].multi)
		return
	endif

	let output= []
	let list  = []
	let cmt   = <sid>ReturnCommentFT()
	let lastline = line('$')
	" We must put the regions back from top to bottom,
	" otherwise, changing lines in between messes up the list of lines that
	" still need to put back from the narrowed buffer to the original buffer
	for key in sort(keys(s:nrrw_rgn_lines[a:instn].multi), "<sid>CompareNumbers")
		let adjust   = line('$') - lastline
		let range    = s:nrrw_rgn_lines[a:instn].multi[key]
		let last     = (len(range)==2) ? range[1] : range[0]
		let first    = range[0]
		let indexs   = index(a:content, cmt.' Start NrrwRgn'.key) + 1
		let indexe   = index(a:content, cmt.' End NrrwRgn'.key) - 1
		if indexs <= 0 || indexe < -1
		   call s:WarningMsg("Skipping Region " . key)
		   continue
		endif
		" Adjust line numbers. Changing the original buffer, might also 
		" change the regions we have remembered. So we must adjust these numbers.
		" This only works, if we put the regions from top to bottom!
		let first += adjust
		let last  += adjust
		if last == line('$') &&  first == 1
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
		exe ':silent :' . first . ',' . last . 'd _'
		call append((first-1),a:content[indexs : indexe])
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		" so subsequent calls will adjust the region accordingly
		let  last = first + len(a:content[indexs : indexe]) - 1
		if last > line('$')
			let last = line('$')
		endif
		call <sid>AddMatches(<sid>GeneratePattern([first, 0 ], [last,0], 'V'))
		if delete_last_line
			silent! $d _
		endif
	endfor
endfun
	
fun! <sid>AddMatches(pattern) "{{{1
	if !s:nrrw_rgn_nohl || empty(a:pattern)
		if !exists("s:nrrw_rgn_lines[s:instn].matchid")
			let s:nrrw_rgn_lines[s:instn].matchid=[]
		endif
		call add(s:nrrw_rgn_lines[s:instn].matchid, matchadd(s:nrrw_rgn_hl, a:pattern))
	endif
endfun

" Debugging options "{{{1
if exists("s:debug") && s:debug
	fun! <sid>NrrwRgnDebug() "{{{2
		"sil! unlet s:instn
		com! NI :call <sid>WarningMsg("Instance: ".s:instn)
		com! NJ :call <sid>WarningMsg("Data: ".string(s:nrrw_rgn_lines))
		com! -nargs=1 NOutput :exe 'echo s:'.<q-args>
	endfun
	call <sid>NrrwRgnDebug()
endif

" Modeline {{{1
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
doc/NarrowRegion.txt	[[[1
327
*NrrwRgn.txt*   A Narrow Region Plugin (similar to Emacs)

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.18 Fri, 10 Dec 2010 15:16:29 +0100

Copyright: (c) 2009, 2010 by Christian Brabandt         
           The VIM LICENSE applies to NrrwRgnPlugin.vim and NrrwRgnPlugin.txt
           (see |copyright|) except use NrrwRgnPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                     *NarrowRegion*  *NrrwRgnPlugin*

        1.  Contents.....................................: |NrrwRgnPlugin|
        2.  NrrwRgn Manual...............................: |NrrwRgn-manual|
        2.1   NrrwRgn Howto..............................: |NR-HowTo|
        2.2   NrrwRgn Multi..............................: |NR-multi-example|
        2.3   NrrwRgn Configuration......................: |NrrwRgn-config|
        3.  NrrwRgn Feedback.............................: |NrrwRgn-feedback|
        4.  NrrwRgn History..............................: |NrrwRgn-history|

==============================================================================
2. NrrwRgn Manual                                       *NrrwRgn-manual*

Functionality

This plugin is based on a discussion in comp.editors (see the thread at
http://groups.google.com/group/comp.editors/browse_frm/thread/0f562d97f80dde13)

Narrowing means focussing on a region and making the rest inaccessible. You
simply select the region, call :NarrowRegion and the selected part will open
in a new scratch buffer. The rest of the file will be protected, so you won't
accidentally modify that buffer. In the new buffer, you can do a global
replace, search or anything else to modify that part. When you are finished,
simply write that buffer (e.g. by |:w|) and your modifications will be put in
the original buffer making it accessible again.

NrrwRgn allows you to either select a line based selection using an Ex-command
or you can simply use any visual selected region and press your prefered key
combination to open that selection in a new buffer.

This plugin defines the following commands:

                                                        *:NarrowRegion* *:NR*
:[range]NR
:[range]NarrowRegion        When [range] is omited, select only the current
                            line, else use the lines in the range given and 
                            open it in a new Scratch Window. 
                            Whenever you are finished modifying that region
                            simply write the buffer.

                                                        *:NarrowWindow* *:NW*
:NW
:NarrowWindow               Select only the range that is visible the current
                            window and open it in a new Scratch Window. 
                            Whenever you are finished modifying that region
                            simply write the buffer.

                                                                *:WidenRegion*
:WidenRegion[!]             This command is only available in the narrowed 
                            scratch window. If the buffer has been modified,
                            the contents will be put back on the original
                            buffer. If ! is specified, the window will be
                            closed, otherwise it will remain open.

                                                                        *:NRV*
:NRV                        Opened the narrowed window for the region that was
                            last selected in visual mode

                                                                        *:NUD*

:NUD                        When viewing unified diffs, this command opens the
                            current chunk in 2 Narrowed Windows in |diff-mode|
                            The current chunk is determined as the one, that
                            the cursor is at.
                            This command does not make sense if editing a
                            different file format (or even different diff format)

                                                                  *:NRPrepare*
:[range]NRPrepare
:[range]NRP                 You can use this command, to mark several lines
                            that will later be put into a Narrowed Window
                            using |:NRM|.

                                                                  *:NRMulti*
:NRMulti
:NRM                        This command takes all lines, that have been
                            marked by |:NRP| and puts them together in a new
                            narrowed buffer.
                            When you write your changes back, all separate
                            lines will be put back at their origin.
                            This command also clears the list of marked lines,
                            that was created with |NRP|.
                            See also |NR-multi-example|.

                                                                 *NR-HowTo*
Use the commands provided above to select a certain region to narrow. You can
also start visual mode and have the selected region being narrowed. In this
mode, NarrowRegion allows you to block select |CTRL-V| , character select |v|
or linewise select |V| a region. Then press <Leader>nr where <Leader> by
default is set to '\', unless you have set it to something different (see
|<Leader>| for information how to change this) and the selected range will
open in a new scratch buffer. This key combination only works in |Visual-mode|

When finished, simply write that Narrowed Region window, from which you want
to take the modifications in your original file.

It is possible, to recursively open a Narrowed Window on top of an already
narrowed window. This sounds a little bit silly, but this makes it possible,
to have several narrowed windows, which you can use for several different
things, e.g. If you have 2 different buffers opened and you want to diff a
certain region of each of those 2 buffers, simply open a Narrowed Window for
each buffer, and execute |:diffthis| in each narrowed window.

You can then interactively merge those 2 windows. And when you are finished,
simply write the narrowed window and the changes will be taken back into the
original buffer.

When viewing unified diffs, you can use the provided |:NUD| command to open 2
Narrowed Windows side by side viewing the current chunk in |diff-mode|. Those
2 Narrowed windows will be marked 'modified', since there was some post
processing involved when opening the narrowed windows. Be careful, when
quitting the windows, not to write unwanted changes into your patch file! In
the window that contains the unified buffer, you can move to a different
chunk, run |:NUD| and the 2 Narrowed Windows in diff mode will update.

                                                     *NR-multi-example*
Using the commands |:NRP| and |:NRM| allows to select a range of lines, that
will be put into a narrowed buffer together. This might sound confusing, but
this allows to apply a filter before making changes. For example before
editing your config file, you decide to strip all comments for making big
changes but when you write your changes back, these comments will stay in your
file. You would do it like this: >
    :v/^#/NRP
    :NRMulti
< 
Now a Narrowed Window will open, that contains only the configuration lines.
Each block of independent region will be seperated by a string like

# Start NarrowRegion1
.....
# End NarrowRegion1

This is needed, so the plugin later knows, which region belongs where in the
original place. Blocks you don't want to change, you can safely delete, they
won't be written back into your original file. But other than that, you
shouldn't change those separating lines.

When you are finished, simply write your changes back.

==============================================================================
2.1 NrrwRgn Configuration                                    *NrrwRgn-config*

NarrowRegion can be customized by setting some global variables. If you'd
like to open the narrowed windo as a vertical split buffer, simply set the
variable g:nrrw_rgn_vert to 1 in your |.vimrc| >

    let g:nrrw_rgn_vert = 1
<
------------------------------------------------------------------------------

If you'd like to specify a certain width/height for you scratch buffer, then
set the variable g:nrrw_rgn_wdth in your |.vimrc| . This variable defines the
width or the nr of columns, if you have also set g:nrrw_rgn_vert. >

    let g:nrrw_rgn_wdth = 30
<
------------------------------------------------------------------------------

By default, NarrowRegion highlights the region that has been selected
using the WildMenu highlighting (see |hl-WildMenu|). If you'd like to use a
different highlighting, set the variable g:nrrw_rgn_hl to your preferred
highlighting Group. For example to have the region highlighted like a search
result, you could put that in your |.vimrc| >

    let g:nrrw_rgn_hl = 'Search'
<
If you want to turn off the highlighting (because this can be disturbing, you
can set the global variable g:nrrw_rgn_nohl to 1 in your |.vimrc| >

    let g:nrrw_rgn_nohl = 1
<
------------------------------------------------------------------------------

If you'd like to change the key combination, that starts the Narrowed Window
for you selected range, you could put this in your |.vimrc| >

   xmap <F3> <Plug>NrrwrgnDo
<
This will let <F3> open the Narrow-Window, but only if you have pressed it in
Visual Mode. It doesn't really make sense to map this combination to any other
mode, unless you want it to Narrow your last visually selected range.

==============================================================================
3. NrrwRgn Feedback                                         *NrrwRgn-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3075

You can also follow the development of the plugin at github:
http://github.com/chrisbra/NrrwRgn

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. NrrwRgn History                                          *NrrwRgn-history*

0.18: December 10, 2010
- experimental feature: Allow to Narrow several different regions at once
  using :g/pattern/NRP and afterwards calling :NRM
  (This only works linewise. Should that be made possible for any reagion?)
- disable folds, before writing changes back, otherwise chances are, you'll
  lose more data then wanted
- code cleanup


0.17: November 23, 2010
- cache the options, that will be set (instead of parsing
  $VIMRUNTIME/doc/options.txt everytime) in the Narrowed Window
- getting the options didn't work, when using an autocommand like this:
  autocmd BufEnter * cd %:p:h
  (reported by Xu Hong, Thanks!)
- :q didn't clean up the Narrowed Buffer correctly. Fix this
- some code cleanup

0.16: November 16, 2010
- Bugfix: copy all local options to the narrowed window (reported by Xu Hong,
  Thanks!)

0.15: August 26, 2010
- Bugfix: minor documentation update (reported by Hong Xu, Thanks!)

0.14: August 26, 2010
- Bugfix: :only in the original buffer resulted in errors (reported by Adam
  Monsen, Thanks!)

0.13: August 22, 2010
- Unified Diff Handling (experimental feature)

0.12: July 29, 2010

- Version 0.11, wasn't packaged correctly and the vimball file
  contained some garbage. (Thanks Dennis Hostetler!)

0.11: July 28, 2010

- Don't set 'winfixwidth' and 'winfixheight' (suggested by Charles Campbell)

0.10: May 20,2010

- Restore Cursorposition using winrestview() and winsaveview()
- fix a bug, that prevented the use of visual narrowing
- Make sure when closing the narrowed buffer, the content will be written to
  the right original region
- use topleft for opening the Narrowed window
- check, that the original buffer is still available
- If you Narrow the complete buffer using :NRV and write the changes back, an
  additional trailing line is inserted. Remove that line.
- When writing the changes back, update the highlighting.

0.9: May 20, 2010

- It is now possible to Narrow a window recursively. This allows to have
  several narrowed windows, and allows for example to only diff certain
  regions (as was suggested in a recent thread at the vim_use mailinglist:
  http://groups.google.com/group/vim_use/msg/05d7fd9bd1556f0e) therefore, the
  use for the g:nrrw_rgn_sepwin variable isn't necessary anymore.
- Small documentation updates

0.8: May 18, 2010

- the g:nrrw_rgn_sepwin variable can be used to force seperate Narrowed
  Windows, so you could easily diff those windows.
- make the separating of several windows a little bit safer (look at the
  bufnr(), so it should work without problems for several buffers)
- switch from script local variables to buffer local variables, so narrowing
  for several buffers should work.
- set 'winfixheight' for narrowed window 
- Added command :NRV (suggested by Charles Campbell, thanks!)
- added error handling, in case :NRV is called, without a selected region
- take care of beeps, when calling :NRV
- output WarningMsg

0.7: May 17, 2010

- really use the black hole register for deleting the old buffer contents in
  the narrowed buffer (suggestion by esquifit in
  http://groups.google.com/group/comp.editors/msg/3eb3e3a7c68597db)
- make autocommand nesting, so the highlighting will be removed when writing
  the buffer contents.
- Use g:nrrw_rgn_nohl variable to disable highlighting (as this can be
  disturbing).

0.6: May 04, 2010

- the previous version had problems restoring the orig buffer, this version
  fixes it (highlighting and setl ma did not work correctly)

0.5: May 04, 2010       

- The mapping that allows for narrowing a visually selected range, did not
  work.  (Fixed!)
- Make :WidenRegion work as expected (close the widened window) (unreleased)

0.4: Apr 28, 2010       

- Highlight narrowed region in the original buffer
- Save and Restore search-register
- Provide shortcut commands |:NR| 
- Provide command |:NW| and |:NarrowWindow|
- Make plugin autoloadable
- Enable GLVS (see |:GLVS|)
- Provide Documenation (:h NarrowRegion)
- Distribute Plugin as vimball |pi_vimball.txt|

0.3: Apr 28, 2010       

- Initial upload
- development versions are available at the github repository
- put plugin on a public repository (http://github.com/chrisbra/NrrwRgn)

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help:et
