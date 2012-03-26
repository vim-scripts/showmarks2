" ==============================================================================
" 4-26-12: tested on Ubuntu
" 			added autochdir
" 			added <F11>; "SaveSession()"
" 4-22-12: fixed the highlight disappearing after auto loading info
" 			enabled autoloading/autosaving; See the comment about how to setup
" 			this on WinXP
" 			added/changed F12; "SaveSessionAs()"
" 4-21-12: fixed cursor jumping after marking using 'm'
" 			extended ShowMarks function to outside, for the reason below
" 			added example of auto session+marks loading/saving
" 4-21-12: moved (activated) <F2> key mapping.
" 			made the marker tag shorter by '>'
"
" This is definitely a copy of sowmarks.vim, modified, crude
"  For now, it works similar to MS utilities
"
" Desire to configure to (the effort is shown at the end of this file):
" ^<F2>: toggle a bookmark
" <F2>: goto next bookmark
" shift-<F2>: goto prev. bookmark
" ^-shift-<F2>: clear all bookmark
" all other marker command: as it was (like m, ', `, and etc.)
"
" Functions:
"		ShowMarksToggle: Toggles a bookmark at the cursor line
"		ShowMarksClearAll: Clears all bookmarks
"		ShowMarks: To show the bookmarks, for initial loading
"       
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showmarks" )
	finish
endif
let loaded_showmarks = 1

" Bail if Vim isn't compiled with signs support.
if has( "signs" ) == 0
	echohl ErrorMsg
	echo "ShowMarks requires Vim to have +signs support."
	echohl None
	finish
endif

" Options: Set up some nice defaults
if !exists('g:showmarks_ignore_type' ) | let g:showmarks_ignore_type  = "hq" | endif

let s:all_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

" Commands
command! -nargs=0 -bar ShowMarksClearAll  call s:ShowMarksClearAll()
command! -nargs=0 -bar ShowMarksToggle call s:ShowMarksToggle()
command! -nargs=0 -bar ShowMarks call s:_ShowMarks()

noremap <unique> <script> \sm m
noremap <silent> m :let ShowMarks_curline=line(".")<bar>call <sid>_ShowMarksPlaceMark()<bar>call setpos(".", ShowMarks_curline)<CR>


" Highlighting: Setup some nice colours to show the mark positions.
" Another might be in the _RecallSession(), take a look
hi default BookmarkCol ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold

fun! s:IncludeMarks()
	if exists('b:showmarks_include') && exists('b:showmarks_previous_include') && b:showmarks_include != b:showmarks_previous_include
		" The user changed the marks to include; hide all marks; change the
		" included mark list, then show all marks.  Prevent infinite
		" recursion during this switch.
		if exists('s:use_previous_include')
			" Recursive call from ShowMarksHideAll()
			return b:showmarks_previous_include
		elseif exists('s:use_new_include')
			" Recursive call from ShowMarks()
			return b:showmarks_include
		else
			let s:use_previous_include = 1
			"call <sid>ShowMarksHideAll()
			unlet s:use_previous_include
			let s:use_new_include = 1
			call <sid>_ShowMarks()
			unlet s:use_new_include
		endif
	endif

	if !exists('g:showmarks_include')
		let g:showmarks_include = s:all_marks
	endif
	if !exists('b:showmarks_include')
		let b:showmarks_include = g:showmarks_include
	endif

	" Save this include setting so we can detect if it was changed.
	let b:showmarks_previous_include = b:showmarks_include

	return b:showmarks_include
endf

fun! s:_NameOfMark(mark)
	let name = a:mark
	if a:mark =~# '\W'
		let name = stridx(s:all_marks, a:mark) + 10
	endif
	return name
endf


fun! s:_ShowMarksSetup()
	" Make sure the textlower, textupper, and textother options are valid.

	let n = 0
	let s:maxmarks = strlen(s:all_marks)
	while n < s:maxmarks
		let c = strpart(s:all_marks, n, 1)
		let nm = s:_NameOfMark(c)
		let text = c
		let lhltext = ''
			let s:ShowMarksDLink{nm} = 'BookmarkCol'
			let lhltext = 'linehl='.s:ShowMarksDLink{nm}.nm

		" Define the sign with a unique highlight which will be linked when placed.
		exe 'sign define ShowMark'.nm.' '.lhltext.' text='.text.' texthl='.s:ShowMarksDLink{nm}.nm
		"exe 'sign define ShowMark'.nm.' '.lhltext
		let b:ShowMarksLink{nm} = ''
		let n = n + 1
	endw
endf


fun! s:_ShowMarks()

	if   ((match(g:showmarks_ignore_type, "[Hh]") > -1) && (&buftype    == "help"    ))
	\ || ((match(g:showmarks_ignore_type, "[Qq]") > -1) && (&buftype    == "quickfix"))
	\ || ((match(g:showmarks_ignore_type, "[Pp]") > -1) && (&pvw        == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Rr]") > -1) && (&readonly   == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Mm]") > -1) && (&modifiable == 0         ))
		return
	endif

	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		let nm = s:_NameOfMark(c)
		let id = n + (s:maxmarks * winbufnr(0))
		let ln = line("'".c)

		if ln == 0 && (exists('b:placed_'.nm) && b:placed_{nm} != ln)
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
		elseif ln > 1 || c !~ '[a-zA-Z]'
			" Have we already placed a mark here in this call to ShowMarks?
			if exists('mark_at'.ln)
				" Already placed a mark, set the highlight to multiple
				if c =~# '[a-zA-Z]' && b:ShowMarksLink{mark_at{ln}} != 'BookmarkCol'
					let b:ShowMarksLink{mark_at{ln}} = 'BookmarkCol'
					exe 'hi link '.s:ShowMarksDLink{mark_at{ln}}.mark_at{ln}.' '.b:ShowMarksLink{mark_at{ln}}
				endif
			else
				if !exists('b:ShowMarksLink'.nm) || b:ShowMarksLink{nm} != s:ShowMarksDLink{nm}
					let b:ShowMarksLink{nm} = s:ShowMarksDLink{nm}
					exe 'hi link '.s:ShowMarksDLink{nm}.nm.' '.b:ShowMarksLink{nm}
				endif
				let mark_at{ln} = nm
				if !exists('b:placed_'.nm) || b:placed_{nm} != ln
					exe 'sign unplace '.id.' buffer='.winbufnr(0)
					exe 'sign place '.id.' name=ShowMark'.nm.' line='.ln.' buffer='.winbufnr(0)
					let b:placed_{nm} = ln
				endif
			endif
		endif
		let n = n + 1
	endw
endf






" Set things up
call s:_ShowMarksSetup()
call s:_ShowMarks()







fun! s:_ShowMarksPlaceMark_do()
	" Find the first, next, and last [a-z] mark in showmarks_include (i.e.
	" priority order), so we know where to "wrap".
	let first_alpha_mark = -1
	let last_alpha_mark  = -1
	let next_mark        = -1

	if !exists('b:previous_auto_mark')
		let b:previous_auto_mark = -1
	endif

	" Find the next unused [a-z] mark (in priority order); if they're all
	" used, find the next one after the previously auto-assigned mark.
	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		if c =~# '[a-z]'
			if line("'".c) <= 1
				" Found an unused [a-z] mark; we're done.
				let next_mark = n
				break
			endif

			if first_alpha_mark < 0
				let first_alpha_mark = n
			endif
			let last_alpha_mark = n
			if n > b:previous_auto_mark && next_mark == -1
				let next_mark = n
			endif
		endif
		let n = n + 1
	endw

	if next_mark == -1 && (b:previous_auto_mark == -1 || b:previous_auto_mark == last_alpha_mark)
		" Didn't find an unused mark, and haven't placed any auto-chosen marks yet,
		" or the previously placed auto-chosen mark was the last alpha mark --
		" use the first alpha mark this time.
		let next_mark = first_alpha_mark
	endif

	if (next_mark == -1)
		echohl WarningMsg
		echo 'No marks in [a-z] included! (No "next mark" to choose from)'
		echohl None
		return
	endif

	let c = strpart(s:IncludeMarks(), next_mark, 1)
	let b:previous_auto_mark = next_mark
	exe 'mark '.c
	call <sid>_ShowMarks()
endf


fun! s:_ShowMarksPlaceMark()
	let ln = line(".")
	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		if c =~# '[a-zA-Z]' && ln == line("'".c)
			" Have we already placed a mark here in this call to ShowMarks?
			echohl WarningMsg
			echo 'You have a mark there, already'
			echohl None
			return
		endif
		let n = n + 1
	endw

	"call <sid>_ShowMarksPlaceMark_do()
	exe 'norm \sm'.nr2char(getchar())
	call <sid>_ShowMarks()

endf


fun! s:_ShowMarksClearMark_do()
	let ln = line(".")
	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		if c =~# '[a-zA-Z]' && ln == line("'".c)
			let nm = s:_NameOfMark(c)
			let id = n + (s:maxmarks * winbufnr(0))
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe '1 mark '.c
			let b:placed_{nm} = 1
		endif
		let n = n + 1
	endw
endf




fun! s:ShowMarksClearAll()
	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		if c =~# '[a-zA-Z]'
			let nm = s:_NameOfMark(c)
			let id = n + (s:maxmarks * winbufnr(0))
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe '1 mark '.c
			let b:placed_{nm} = 1
		endif
		let n = n + 1
	endw
endf

fun! s:ShowMarksToggle()
	let ln = line(".")
	let n = 0
	let s:maxmarks = strlen(s:IncludeMarks())
	while n < s:maxmarks
		let c = strpart(s:IncludeMarks(), n, 1)
		if c =~# '[a-zA-Z]' && ln == line("'".c)
			" Have we already placed a mark here in this call to ShowMarks?
			call <sid>_ShowMarksClearMark_do()
			return
		endif
		let n = n + 1
	endw

	call <sid>_ShowMarksPlaceMark_do()
endf


" -----------------------------------------------------------------------------

"goto previous lowercase mark
:map <F2> ]` 

"goto next lowercase mark
:map <S-F2> [`

:map <C-F2> :execute "ShowMarksToggle"<CR>

"clear all marks
:map <C-S-F2> :execute "ShowMarksClearAll"<CR>


" -----------------------------------------------------------------------------
"finish

" I have this part in _vimrc
" F12 saves session, double click on "_session.vis" reloads session
" those are saved in the directory-of-the-current-buffer
" loading blank doc may pose error for the first time
"
" In order to load session at double click (I am using Win XP):
" DOS> assoc .vis=vimsession
" DOS> ftype vimsession="C:\Program Files\Vim\vim72\gvim.exe" -S "%1"
"
"

set autochdir
"autocmd BufEnter * silent! lcd %:p:h
"autocmd BufEnter * lcd %:p:h


function! _SaveSessionAs()
	let svpath = input('Path and name to save .vis: ')
	execute 'mksession!' . svpath . ".vis"
endfunction
command! -nargs=0 SaveSessionAs :call _SaveSessionAs()


function! _SaveSession()
	execute "mksession! _session.vis"
	execute "wviminfo! _viminfo.vim"
endfunction
command! -nargs=0 SaveSession :call _SaveSession()


function! _RecallSession()
	execute "rviminfo _viminfo.vim"
	execute "ShowMarks"
	hi default BookmarkCol ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
endfunction
command! -nargs=0 RecallSession :call _RecallSession()

aug RecallSession
au!
autocmd VimEnter * :RecallSession
aug END

aug SaveSession
au!
autocmd VimLeave * :SaveSession
aug END

:map <F11> :execute "SaveSession"<CR>
:map <F12> :execute "SaveSessionAs"<CR>
" -----------------------------------------------------------------------------
finish

