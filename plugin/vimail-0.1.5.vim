" File:        vimail.vim
" Scirpt Name: ViMail
" Version:     0.1.5
" Author:      Little Dragon
" Email:       littledragon@altern.org
"
" This script is intended to provide an easy and quick way of sending e-mail
" messages from within vim.
"
" Commands:
" - NewMail   opens a new mail window
" - SendMail  sends the current mail
"
" Key Bindings:
" Normal Mode
" -----------
"  M-Sh-'     binding for :NewMail
"  M-Sh-/     binding for :SendMail
"
" Insert Mode
" -----------
"  M-Sh-z     completes the alias under the cursor
" 
" Todo:
" Cc and Bcc
" 
" ChangeLog:
" 13.02.2002 - 0.1.5
" ------------------
"  Modified the SendMail behaviour to send the current buffer, even if no
"  To or From fields were specified. If no To field exists in the message,
"  the user will be prompted for it.
" 
" 13.01.2002 - 0.1.4
" ------------------
"  Added the complete alias function.
" 
" 13.01.2002 - 0.1.3
" ------------------
"  Created the global variables
"    g:vimail_from     the default sender
"    g:vimail_to       the default recipient(s) - you can use aliases too
"    g:vimail_subject  the default subject
"    g:vimail_host     the hostname to which the mailer program should connect
"                      (can be left blank where not applicable, such as when
"                      using sendmail that will always connect to localhost)
"    g:vimail_sendmail the program used to send mail (it defaults to
"                      'sendmail' if none is specified)
" 
"  Globalized the mail alias variables
"    g:vimail_alias{'alias'} = name and/or e-mail address
"
"  Globalized the settings
"    g:vimail_signature_file  the file used to insert the signature from
"    g:vimail_close_on_send   wether or not to close the message window after
"                             sending the message
"    g:vimail_lang_change     wether or not to change the language to English
"                             while writing the date/time.
" 
" 12.01.2002 - 0.1.2
" ------------------
"  Mutiple aliases can now be specified in the To: field.
" 
" 12.01.2002 - 0.1.1
" ------------------
"  Fixed the key bindings and a minor bug.
" 
" 11.01.2002 - 0.1.0
" ------------------
"  Initial release.

" General informations about the script.
let s:script_name = "ViMail"
let s:script_version = "0.1.5"

" Configuration variables.

" Specify the program that will send the message. Please don't hesitate to
" contact the author if you can help with others, such as qmail or postfix.
"
"  - sendmail     http://www.sendmail.org/
"  - relayclient  http://www.littledragon.f2s.com/unix/relayclient/

if !exists('g:vimail_sendmail')
	let g:vimail_sendmail = 'sendmail'
endif

if !exists('g:vimail_signature_file')
	if stridx($OS, "Windows") == -1
		let g:vimail_signature_file = '/home/' . $USER . '/.signature'
	else
		let g:vimail_signature_file = 'C:\signature.txt'
	endif
endif
if !exists('g:vimail_close_on_send')
	let g:vimail_close_on_send = 0
endif
if !exists('g:vimail_lang_change')
	if stridx($OS, "Windows") == -1
		let g:vimail_lang_change = 1
	else
		let g:vimail_lang_change = 0
	endif
endif

" Function definitions.
function! SendMail()
	" Declare the variables that we are going to use
	let s:from = ''
	let s:to = ''
	
	" Search for a To: line to extract the recipient(s)
	let s:line = search("^To: ", "w")
	if s:line > 0
		let s:text = getline(s:line)
		let s:to_idx = stridx(s:text, " ")
		let s:to = strpart(s:text, s:to_idx+1)
		
		" s:to should now contain the contents of the To: line. We
		" will now extract the actual email addresses form it.
		let s:to_tmp = s:to
		let s:lastidx = stridx(s:to_tmp, "<")
		if s:lastidx > 0
			let s:to = ''
		endif
		while s:lastidx >= 0
			let s:closeidx = match(s:to_tmp, ">", s:lastidx)
			let s:to = s:to . strpart(s:to_tmp, s:lastidx+1, s:closeidx-s:lastidx-1)
			let s:to = s:to . ", "
			let s:lastidx = match(s:to_tmp, "<", s:closeidx)
		endwhile
	else
		if !exists('g:vimail_to')
			let s:to = input("To: ")
		else
			let s:to = g:vimail_to
		endif
	endif

	" Search for a From: line to extract the sender name
	let s:line = search("^From: ", "w")
	if s:line > 0
		let s:text = getline(s:line)
		let s:from_idx = stridx(s:text, " ")
		let s:from = strpart(s:text, s:from_idx+1)
	else
		if !exists('g:vimail_from')
			let s:from = $USER."@".$HOSTNAME
		else
			let s:from = g:vimail_from
		endif
	endif
	
	" Verify wether or not the sender and the recipient are
	" both specified
	if s:from == ''
		echoerr "No sender specified."
	elseif s:to == ''
		echoerr "No recipient specified."
	else
		" Everything is OK, let's send the message.
		redraw
		echo "Sending message..."
		
		" Declare the temporary file name.
		let s:tempfile = tempname()

		" Write the buffer to a temporary file
		execute("write! " . s:tempfile)
		redraw
		echo "Sending message..."

		" Get the sender program to send the message.
		if g:vimail_sendmail == 'sendmail'
			let s:cmd = "cat " . s:tempfile
			let s:cmd = s:cmd . "\| sendmail -- " . s:to . " 2>&1"
			let s:error = system(s:cmd)
			redraw
		elseif g:vimail_sendmail == 'relayclient'
			let s:cmd = "cat " . s:tempfile
			let s:cmd = s:cmd . "\| relayclient -- " . s:to . " 2>&1"
			let s:error = system(s:cmd)
		endif
		redraw
		
		" If anything went wrong, report it.
		if exists('s:error')
			if strlen(s:error) > 0
				let s:error = substitute(s:error, '.$', '.', '')
				echoerr s:error
			else
				" Remove the temporary file.
				call delete(s:tempfile)

				" Redraw the screen and inform the user that the
				" message has been sent.
				redraw
				echo "Mail sent."
				if g:vimail_close_on_send == 1
					bdelete
				endif
			endif
		endif
	endif
endfunction

function! ExpandAlias(alias)
	if exists('g:vimail_alias' . a:alias)
		return g:vimail_alias{a:alias}
	else
		return a:alias
	endif
endfunction

function! NewMail()
	" Declare some variables that we are going to use later.
	let s:to = ''
	let s:subject = ''
	let s:tempfile = tempname()

	" Get the To: string from the user input or from the global variable, if
	" defined.
	if exists('g:vimail_to')
		let s:to = g:vimail_to
	else
		let s:to = input("To: ")
	endif
	
	" Get the Subject: string from the user input or from the global
	" variable, if defined.
	if exists('g:vimail_subject')
		let s:subject = g:vimail_subject
	else
		let s:subject = input("Subject: ")
	endif

	" Generate recipients from aliases.
	if stridx(s:to, ",") > -1
		let s:to_tmp = s:to
		let s:to = ''
		let s:lastbegin = 0
		let s:lastend = stridx(s:to_tmp, ",")
		while s:lastend > -1
			let s:getcount = s:lastend-s:lastbegin
			let s:recipient = strpart(s:to_tmp, s:lastbegin, s:getcount)
			let s:recipient = substitute(s:recipient, '^ *', '', '')
			let s:to = s:to . ExpandAlias(s:recipient)
			let s:to = s:to . ", "
			let s:lastbegin = s:lastend+1
			let s:lastend = match(s:to_tmp, ",", s:lastbegin)
		endwhile
		let s:lastrecp = strpart(s:to_tmp, strridx(s:to_tmp, ",")+1)
		let s:lastrecp = substitute(s:lastrecp, '^ *', '', '')
		let s:to = s:to . ExpandAlias(s:lastrecp)
	else
		let s:to = ExpandAlias(s:to)
	endif

	" Create a new file and set the syntax highlighting.
	if strlen(bufname("%"))
		new
	endif
	set filetype=mail

	" Make the time later on be in English, even if the $LANG variable
	" is not set to English. You can disable this by modifying the
	" s:lang_change value at the top of the script. 
	if g:vimail_lang_change == 1
		let s:lang = v:lang
		language time C
	endif

	" Write the mail header.
	let s:from_line = 'From: '
	if exists('g:vimail_from')
		let s:from_line = s:from_line . g:vimail_from
	endif
	call setline(1, s:from_line)
	call append(line('$'), 'To: ' . s:to)
	call append(line('$'), 'Subject: ' . s:subject)
	call append(line('$'), 'Date: ' . strftime('%a, %d %b %Y %H:%M:%S %z'))
	call append(line('$'), 'X-Mailer: ' . s:script_name . ' ' . s:script_version)
	call append(line('$'), '')
	call append(line('$'), '')
	:7
	
	" If a signature file is present, include it at the end of
	" the message.
	if filereadable(g:vimail_signature_file)
		call append(line('$'), '-- ')
		call append(line('$'), '')
		:8
		execute("read " . g:vimail_signature_file)
		redraw
		:7
	endif

	" Write the file.
	execute("write! " . s:tempfile)
	redraw
	if g:vimail_lang_change == 1
		execute("language time " . s:lang)
	endif

	" Remove the temporary file.
	call delete(s:tempfile)
endfunction

function! CompleteAlias()
	" Get the current line.
	let s:ca_line = getline('.')

	" Define the patterns that we're going to match later.
	let s:punct = '\W'
	let s:match = '^.\+\W\(\w\+\)$'

	" See if there is only one word on the line or if there are more.
	if s:ca_line =~ s:punct || stridx(s:ca_line, " ") > -1
		
		" There are more words. We'll get the word under the cursor or behind
		" the cursor if the cursor is at the end of the word.
		let s:ca_tmp_text = strpart(s:ca_line, 0, col('.')+1)
		
		" If the cursor is not at the end of the word, also get the characters
		" after the cursor, until the end of the word.
		let s:chr = 1
		while s:chr > 0
			let s:tmp_chr = strpart(s:ca_line, col('.')+s:chr, 1)
			if s:tmp_chr =~ '\w'
				let s:ca_tmp_text = s:ca_tmp_text . s:tmp_chr
				let s:chr = s:chr+1
			else
				let s:chr = 0
			endif
		endwhile

		" Put the word as the alias to substitute.
		let s:ca_alias = substitute(s:ca_tmp_text, s:match, '\1', '')
	else
		" The only word on the line will be the alias to substitute.
		let s:ca_alias = s:ca_line
	endif
	
	" Get the text surrounding the alias.
	let s:ca_left = strpart(s:ca_line, 0, strridx(s:ca_line, s:ca_alias))
	let s:ca_right = strpart(s:ca_line, strlen(s:ca_left)+strlen(s:ca_alias))

	" Resolve the alias and modify the line.
	let s:ca_mline = s:ca_left . ExpandAlias(s:ca_alias) . s:ca_right

	" Replace the line.
	call setline('.', s:ca_mline)
endfunction

" Command definitions.
command! SendMail call SendMail()
command! NewMail  call NewMail()

" Key bindings.
nmap <Esc>? :SendMail<CR>
nmap <Esc>" :NewMail<CR>
imap <Esc>Z <Esc>:call CompleteAlias()<CR>a
