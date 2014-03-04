if exists("b:current_syntax")
  finish
endif

runtime! syntax/json.vim

syn match jsonldKeyword /@\w\+/ contained containedin=jsonString,jsonKeywordRegion
syn match jsonldCurie '\w\+:\(\([^/"][^/"]\|/\?[^/"]\)[^"]*\)\+' contained containedin=jsonString,jsonKeywordRegion

hi def link jsonldKeyword Keyword
hi def link jsonldCurie Special
