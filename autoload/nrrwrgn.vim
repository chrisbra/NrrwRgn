" nrrwrgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.26
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Mon, 02 Jan 2012 21:33:50 +0100
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to NrrwRgn.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 26 :AutoInstall: NrrwRgn.vim
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
		if !exists("g:nrrw_custom_options") || empty(g:nrrw_custom_options)
			let s:opts=<sid>Options('local to buffer')
        endif
	else
		" Prevent accidently overwriting windows with instn_id set
		" back to an already existing instn_id
		let s:instn = (s:instn==0 ? 1 : s:instn)
		while (has_key(s:nrrw_rgn_lines, s:instn))
			let s:instn+=1
		endw
	endif
	let s:nrrw_aucmd = {}
	if exists("b:nrrw_aucmd_create")
		let s:nrrw_aucmd["create"] = b:nrrw_aucmd_create
	endif
	if exists("b:nrrw_aucmd_close")
		let s:nrrw_aucmd["close"] = b:nrrw_aucmd_close
	endif
	if !exists("s:nrrw_rgn_lines")
		let s:nrrw_rgn_lines = {}
	endif
	let s:nrrw_rgn_lines[s:instn] = {}
	" show some debugging messages
	let s:nrrw_winname='Narrow_Region'

	" Customization
	let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert") ? g:nrrw_rgn_vert : 0)
	let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth") ? g:nrrw_rgn_wdth : 20)
	let s:nrrw_rgn_hl	= (exists("g:nrrw_rgn_hl")	 ? g:nrrw_rgn_hl   : "WildMenu")
	let s:nrrw_rgn_nohl = (exists("g:nrrw_rgn_nohl") ? g:nrrw_rgn_nohl : 0)

	let s:debug         = (exists("s:debug") ? s:debug : 0)
		
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
		if !exists('g:nrrw_topbot_leftright')
			let g:nrrw_topbot_leftright = 'topleft'
		endif
		exe  g:nrrw_topbot_leftright s:nrrw_rgn_wdth .
			\(s:nrrw_rgn_vert?'v':'') . "sp " . nrrw_winname
		" just in case, a global nomodifiable was set 
		" disable this for the narrowed window
		setl ma
		" Just in case
		silent %d _
		" Set up some options like 'bufhidden', 'noswapfile', 
		" 'buftype', 'bufhidden', when enabling Narrowing.
		call <sid>NrrwSettings(1)
		let nrrw_win = bufwinnr("")
	endif
	call <sid>SetOptions(local_options)
	return nrrw_win
endfun

fun! <sid>CleanRegions() "{{{1
	 let s:nrrw_rgn_line=[]
	 unlet! s:nrrw_rgn_last
endfun

fun! <sid>CompareNumbers(a1,a2) "{{{1
	return (a:a1+0) == (a:a2+0) ? 0
		\ : (a:a1+0) > (a:a2+0) ? 1
		\ : -1
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
         endif
		 let i+=1
         let temp=item
     endfor
     return result
endfun

fun! <sid>WriteNrrwRgn(...) "{{{1
	" if argument is given, write narrowed buffer back
	" else destroy the narrowed window
	let nrrw_instn = exists("b:nrrw_instn") ? b:nrrw_instn : s:instn
	if exists("b:orig_buf") && (bufwinnr(b:orig_buf) == -1) &&
		\ !<sid>BufInTab(b:orig_buf)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	if &l:mod && exists("a:1") && a:1
		" Write the buffer back to the original buffer
		setl nomod
		exe ":WidenRegion"
		if bufname('') !~# 'Narrow_Region'
			exe ':noa' . bufwinnr(s:nrrw_winname . '_' . s:instn) . 'wincmd w'
		endif
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
endfun

fun! <sid>SaveRestoreRegister(mode) "{{{1
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
endfun!

fun! <sid>NrrwRgnAuCmd(instn) "{{{1
	" If a:instn==0, then enable auto commands
	" else disable auto commands for a:instn
	if !a:instn
		exe "aug NrrwRgn" . b:nrrw_instn
			au!
			au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
			au BufWinLeave,BufWipeout,BufDelete <buffer> nested :call s:WriteNrrwRgn()
		aug end
	else
		exe "aug NrrwRgn" .  a:instn
		au!
		aug end
		exe "aug! NrrwRgn" . a:instn
		if !&ma
			setl ma
		endif
		if s:debug
			echo printf("bufnr: %d a:instn: %d\n", bufnr(''), a:instn)
			echo "bwipe " s:nrrw_winname . '_' . a:instn
		endif
		if (has_key(s:nrrw_rgn_lines[a:instn], 'disable') &&
		\	!s:nrrw_rgn_lines[a:instn].disable ) ||
		\   !has_key(s:nrrw_rgn_lines[a:instn], 'disable')
			call <sid>DeleteMatches(a:instn)
			exe "bwipe! " bufnr(s:nrrw_winname . '_' . a:instn)
			if s:instn>=1
				unlet s:nrrw_rgn_lines[a:instn]
				let s:instn-=1
			endif
		endif
	endif
endfun

fun! <sid>RetVisRegionPos() "{{{1
	let startline = [ getpos("'<")[1], virtcol("'<") ]
	let endline   = [ getpos("'>")[1], virtcol("'>") ]
	return [ startline, endline ]
endfun

fun! <sid>GeneratePattern(startl, endl, mode) "{{{1
	if a:mode ==# '' && a:startl[0] > 0 && a:startl[1] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) .
			\ 'v\&\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	elseif a:mode ==# 'v' && a:startl[0] > 0 && a:startl[1] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) .
			\ 'v\_.*\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	elseif a:startl[0] > 0
		return '\%>' . (a:startl[0]-1) . 'l\&\%<' . (a:endl[0]+1) . 'l'
	else
		return ''
	endif
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
		let filter_opt='\%(modifi\%(ed\|able\)\|readonly\|noswapfile\|' .
				\ 'buftype\|bufhidden\|foldcolumn\|buflisted\)'
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
	if exists("g:nrrw_custom_options") && !empty(g:nrrw_custom_options)
		let result = g:nrrw_custom_options
	else
		let result={}
		for item in a:opt
			try
				exe "let result[item]=&l:".item
			catch
			endtry
		endfor
	endif
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
	" Protect the original window, unless the user explicitly defines not to
	" protect it
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		return
	endif
	let b:orig_buf_ro=0
	if !&l:ma || &l:ro
		let b:orig_buf_ro=1
		call s:WarningMsg("Buffer is protected, won't be able to write".
			\ "the changes back!")
	else 
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that might later be overwritten
		setl noma
	endif
endfun

fun! <sid>DeleteMatches(instn) "{{{1
    " Make sure, we are in the correct buffer
	if bufname('') =~# 'Narrow_Region'
		exe ':noa' . bufwinnr(b:orig_buf) . 'wincmd w'
	endif
	if exists("s:nrrw_rgn_lines[a:instn].matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		for item in s:nrrw_rgn_lines[a:instn].matchid
			if item > 0
				" If the match has been deleted, discard the error
				exe (s:debug ? "" : "silent!") "call matchdelete(item)"
			endif
		endfor
		let s:nrrw_rgn_lines[a:instn].matchid=[]
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
	elseif &l:ft=~'^\(perl\|php\|ruby\|python\|sh\)$'
	    return '#'
	" C, C++
	elseif &l:ft=~'^\(c\%(pp\)\?\|java\)'
		return '/* */'
	" HTML, XML
	elseif &l:ft=~'^\(ht\|x\)ml\?$'
		return '<!-- -->'
	" LaTex
	elseif &l:ft=~'^\(la\)tex'
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
	let [c_s, c_e] =  <sid>ReturnComments()
	let lastline = line('$')
	" We must put the regions back from top to bottom,
	" otherwise, changing lines in between messes up the list of lines that
	" still need to put back from the narrowed buffer to the original buffer
	for key in sort(keys(s:nrrw_rgn_lines[a:instn].multi),
			\ "<sid>CompareNumbers")
		let adjust   = line('$') - lastline
		let range    = s:nrrw_rgn_lines[a:instn].multi[key]
		let last     = (len(range)==2) ? range[1] : range[0]
		let first    = range[0]
		let indexs   = index(a:content, c_s.' Start NrrwRgn'.key.c_e) + 1
		let indexe   = index(a:content, c_s.' End NrrwRgn'.key.c_e) - 1
		if indexs <= 0 || indexe < -1
		   call s:WarningMsg("Skipping Region " . key)
		   continue
		endif
		" Adjust line numbers. Changing the original buffer, might also 
		" change the regions we have remembered. So we must adjust these
		" numbers.
		" This only works, if we put the regions from top to bottom!
		let first += adjust
		let last  += adjust
		if last == line('$') &&  first == 1
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
		exe ':silent :' . first . ',' . last . 'd _'
		call append((first-1), a:content[indexs : indexe])
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		let  last = first + len(a:content[indexs : indexe]) - 1
		if last > line('$')
			let last = line('$')
		endif
		call <sid>AddMatches(<sid>GeneratePattern([first, 0 ],
					\ [last, 0], 'V'), a:instn)
		if delete_last_line
			silent! $d _
		endif
	endfor
endfun
	
fun! <sid>AddMatches(pattern, instn) "{{{1
	if !s:nrrw_rgn_nohl || empty(a:pattern)
		if !exists("s:nrrw_rgn_lines[a:instn].matchid")
			let s:nrrw_rgn_lines[a:instn].matchid=[]
		endif
		call add(s:nrrw_rgn_lines[a:instn].matchid,
					\matchadd(s:nrrw_rgn_hl, a:pattern))
	endif
endfun

fun! <sid>BufInTab(bufnr) "{{{1
	for tab in range(1,tabpagenr('$'))
		if !empty(filter(tabpagebuflist(tab), 'v:val == a:bufnr'))
			return tab
		endif
	endfor
	return 0
endfun

fun! <sid>JumpToBufinTab(tab,buf) "{{{1
	if a:tab
		exe "tabn" a:tab
	endif
	exe ':noa ' . bufwinnr(a:buf) . 'wincmd w'
endfun

fun! <sid>RecalculateLineNumbers(instn, adjust) "{{{1
	" This only matters, if the original window isn't protected
	if !exists("g:nrrw_rgn_protect") || g:nrrw_rgn_protect !~# 'n'
		return
	endif

	for instn in filter(keys(s:nrrw_rgn_lines), 'v:val != a:instn')
		" Skip narrowed instances, when they are before
		" the region, we are currently putting back
		if s:nrrw_rgn_lines[instn].startline[0] <=
		\ s:nrrw_rgn_lines[a:instn].startline[0]
			" Skip this instn
			continue
		else 
		   let s:nrrw_rgn_lines[instn].startline[0] += a:adjust
		   let s:nrrw_rgn_lines[instn].endline[0]   += a:adjust

		   if s:nrrw_rgn_lines[instn].startline[0] < 1
			   let s:nrrw_rgn_lines[instn].startline[0] = 1
		   endif
		   if s:nrrw_rgn_lines[instn].endline[0] < 1
			   let s:nrrw_rgn_lines[instn].endline[0] = 1
		   endif
		   call <sid>DeleteMatches(instn)
		   call <sid>AddMatches(<sid>GeneratePattern(
				\s:nrrw_rgn_lines[instn].startline, 
				\s:nrrw_rgn_lines[instn].endline, 
				\'V'), instn)
		endif
	endfor

endfun

fun! <sid>NrrwSettings(on) "{{{1
	if a:on
		setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted
	else
		setl swapfile buftype= bufhidden= buflisted
	endif
endfun

fun! <sid>SetupBufLocalCommands(visual) "{{{1
	exe 'com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion('. a:visual.
		\ ', <bang>0)'
	com! -buffer NRSyncOnWrite  :call nrrwrgn#ToggleSyncWrite(1)
	com! -buffer NRNoSyncOnWrite :call nrrwrgn#ToggleSyncWrite(0)
endfun

fun! <sid>ReturnComments() "{{{1
	let cmt = <sid>ReturnCommentFT()
	let c_s    = split(cmt)[0]
	let c_e    = (len(split(cmt)) == 1 ? "" : " " . split(cmt)[1])
	return [c_s, c_e]
endfun

fun! nrrwrgn#NrrwRgnDoPrepare() "{{{1
	if !exists("s:nrrw_rgn_line")
		call <sid>WarningMsg("You need to first select the lines to".
			\ " narrow using :NRP!")
	   return
	endif
	let s:nrrw_rgn_buf =  <sid>ParseList(s:nrrw_rgn_line)
	if empty(s:nrrw_rgn_buf)
		call <sid>WarningMsg("No lines selected from :NRP, aborting!")
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
	call <sid>DeleteMatches(s:instn)

	let nr=0
	let lines=[]
	let buffer=[]

	let keys = keys(s:nrrw_rgn_buf)
	call sort(keys,"<sid>CompareNumbers")
	"for [ nr,lines] in items(s:nrrw_rgn_buf)
	let [c_s, c_e] =  <sid>ReturnComments()
	for nr in keys
		let lines = s:nrrw_rgn_buf[nr]
		let start = lines[0]
		let end   = len(lines)==2 ? lines[1] : lines[0]
		call <sid>AddMatches(<sid>GeneratePattern([start,0], [end,0], 'V'),
				\s:instn)
		call add(buffer, c_s.' Start NrrwRgn'.nr.c_e)
		let buffer = buffer +
				\ getline(start,end) +
				\ [c_s.' End NrrwRgn'.nr.c_e, '']
	endfor

	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, buffer)
	setl nomod
	let b:nrrw_instn = s:instn
	call <sid>SetupBufLocalCommands(0)
	call <sid>NrrwRgnAuCmd(0)
	call <sid>CleanRegions()

	" restore settings
	let &lz   = o_lz
endfun

fun! nrrwrgn#NrrwRgn() range  "{{{1
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
    call <sid>CheckProtected()
	let first = a:firstline
	let last  = a:lastline
	" If first line is in a closed fold,
	" include complete fold in Narrowed window
	if first == last && foldclosed(first) != -1
		let first = foldclosed(first)
		let last  = foldclosedend(last)
	endif
	let s:nrrw_rgn_lines[s:instn].startline = [ first, 0 ]
	let s:nrrw_rgn_lines[s:instn].endline	= [ last , 0 ]
	call <sid>DeleteMatches(s:instn)
	" Set the highlighting
	call <sid>AddMatches(<sid>GeneratePattern(
		\s:nrrw_rgn_lines[s:instn].startline, 
		\s:nrrw_rgn_lines[s:instn].endline, 
		\'V'), s:instn)
	let a=getline(
		\s:nrrw_rgn_lines[s:instn].startline[0], 
		\s:nrrw_rgn_lines[s:instn].endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	let b:nrrw_instn = s:instn
	call <sid>NrrwSettings(1)
	call <sid>SetupBufLocalCommands(0)
	call <sid>NrrwRgnAuCmd(0)
	if has_key(s:nrrw_aucmd, "create")
		exe s:nrrw_aucmd["create"]
	endif
	if has_key(s:nrrw_aucmd, "close")
		let b:nrrw_aucmd_close = s:nrrw_aucmd["close"]
	endif

	" restore settings
	let &lz   = o_lz
endfun

fun! nrrwrgn#Prepare(bang) "{{{1
	let ltime = localtime()
	if !empty(a:bang) &&
	\ (!exists("s:nrrw_rgn_last") || s:nrrw_rgn_last + 10 < ltime)
		let s:nrrw_rgn_last = ltime
		let s:nrrw_rgn_line = []
	endif
	if !exists("s:nrrw_rgn_line") | let s:nrrw_rgn_line=[] | endif
	call add(s:nrrw_rgn_line, line('.'))
endfun

fun! nrrwrgn#WidenRegion(vmode,force) "{{{1
	let nrw_buf  = bufnr('')
	let orig_buf = b:orig_buf
	let orig_tab = tabpagenr()
	let instn    = b:nrrw_instn
	" Execute autocommands
	if has_key(s:nrrw_aucmd, "close")
		exe s:nrrw_aucmd["close"]
	endif
	let cont	 = getline(1,'$')

	let tab=<sid>BufInTab(orig_buf)
	if tab != tabpagenr()
		exe "tabn" tab
	endif
	let orig_win = bufwinnr(orig_buf)
	" Should be in the right tab now!
	if (orig_win == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	exe ':noa' . orig_win . 'wincmd w'
	call <sid>SaveRestoreRegister(1)
	let wsv=winsaveview()
	call <sid>DeleteMatches(instn)
	if exists("b:orig_buf_ro") && b:orig_buf_ro && !a:force
		call s:WarningMsg("Original buffer protected. Can't write changes!")
		call <sid>JumpToBufinTab(orig_tab, nrw_buf)
		return
	endif
	if !&l:ma && !( exists("b:orig_buf_ro") && b:orig_buf_ro)
		setl ma
	endif
	" This is needed to adjust all other narrowed regions
	" in case we have several narrowed regions within the same buffer
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		let  adjust_line_numbers = len(cont) - 1 - (
					\s:nrrw_rgn_lines[instn].endline[0] - 
					\s:nrrw_rgn_lines[instn].startline[0])
	endif

	" Now copy the content back into the original buffer

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
		call <sid>AddMatches(<sid>GeneratePattern(
					    \s:nrrw_rgn_lines[instn].startline,
						\s:nrrw_rgn_lines[instn].endline,
						\s:nrrw_rgn_lines[instn].vmode),
						\instn)
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
			\'V'),
			\instn)
		if delete_last_line
			silent! $d _
		endif
	endif
	" Recalculate start- and endline numbers for all other Narrowed Windows.
	" This matters, if you narrow different regions of the same file and
	" write your changes back.
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		call <sid>RecalculateLineNumbers(instn, adjust_line_numbers)
	endif
	call <sid>SaveRestoreRegister(0)
	let  @/=s:o_s
	call winrestview(wsv)
	" jump back to narrowed window
	call <sid>JumpToBufinTab(orig_tab, nrw_buf)
	setl nomod
	if a:force
		" execute auto command
		bw
	endif
endfun

fun! nrrwrgn#VisualNrrwRgn(mode) "{{{1
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
	let [ s:nrrw_rgn_lines[s:instn].startline,
		\s:nrrw_rgn_lines[s:instn].endline ] = <sid>RetVisRegionPos()
	call <sid>DeleteMatches(s:instn)
	call <sid>AddMatches(<sid>GeneratePattern(
				\s:nrrw_rgn_lines[s:instn].startline,
				\s:nrrw_rgn_lines[s:instn].endline,
				\s:nrrw_rgn_lines[s:instn].vmode),
				\s:instn)
	norm! gv"ay
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	silent put a
	let b:nrrw_instn = s:instn
	silent 0d _
	setl nomod
	call <sid>SetupBufLocalCommands(1)
	" Setup autocommands
	call <sid>NrrwRgnAuCmd(0)
	" Execute autocommands
	if has_key(s:nrrw_aucmd, "create")
		exe s:nrrw_aucmd["create"]
	endif
	call <sid>SaveRestoreRegister(0)

	" restore settings
	let &lz   = o_lz
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

fun! nrrwrgn#ToggleSyncWrite(enable) "{{{1
	let s:nrrw_rgn_lines[b:nrrw_instn].disable = !a:enable
	" Enable syncing of bufers
	if a:enable
		" Enable Narrow settings and autocommands
		call <sid>NrrwSettings(1)
		call <sid>NrrwRgnAuCmd(0)
		setl modified
	else
		" Disable Narrow settings and autocommands
		call <sid>NrrwSettings(0)
		" b:nrrw_instn should always be available
		call <sid>NrrwRgnAuCmd(b:nrrw_instn)
	endif
endfun
" Debugging options "{{{1
fun! nrrwrgn#Debug(enable) "{{{1
	if (a:enable)
		let s:debug=1
		fun! <sid>NrrwRgnDebug() "{{{2
			"sil! unlet s:instn
			com! NI :call <sid>WarningMsg("Instance: ".s:instn)
			com! NJ :call <sid>WarningMsg("Data: ".string(s:nrrw_rgn_lines))
			com! -nargs=1 NOutput :exe 'echo s:'.<q-args>
		endfun
		call <sid>NrrwRgnDebug()
	else
		let s:debug=0
		delf <sid>NrrwRgnDebug
		delc NI
		delc NJ
		delc NOutput
	endif
endfun

" Modeline {{{1
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
