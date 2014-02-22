if exists("b:current_syntax")
  finish
endif

runtime! syntax/json.vim

syn match jsonldKeyword '"@\w\+"'
syn match jsonldCurie '"\w\+:\(\([^/"][^/"]\|/\?[^/"]\)[^"]*\)\?"'

hi def link jsonldKeyword Keyword
hi def link jsonldCurie Special
