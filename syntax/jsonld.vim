if exists("b:current_syntax")
  finish
endif

runtime! syntax/json.vim

if !exists("g:vim_json_syntax_conceal")
    syn region  jsonString oneline start=/"/  skip=/\\\\\|\\"/  end=/"/
    syn match   jsonKeywordMatch /"[^\"\:]\+"[[:blank:]\r\n]*\:/ contains=jsonKeywordRegion
    syn region  jsonKeywordRegion matchgroup=jsonQuote start=/"/  end=/"\ze[[:blank:]\r\n]*\:/ contained
    hi def link jsonldKeyword Keyword
else
    hi def link jsonldKeyword Underlined
endif

syn match jsonldKeyword /@\w\+/ contained containedin=jsonString,jsonKeywordRegion
syn match jsonldCurie '\w\+:\(\([^/"][^/"]\|/\?[^/"]\)[^"]*\)\+' contained containedin=jsonString,jsonKeywordRegion

hi def link jsonldCurie Special
