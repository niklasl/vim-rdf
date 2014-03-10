
if exists("b:current_syntax")
  finish
endif

syn match rdfaUrl +\(#\|\w*[/.]\)[^"' \t\n]*+ containedin=rdfaExpr,rdfaLink contained
syn match rdfaPrefix '\w*:' containedin=rdfaExpr,rdfaLink contained
syn match rdfaError +[^"' \t]*\s[^"' \t]*+ containedin=rdfaLink contained

hi link rdfaExpr Special
hi link rdfaLink Special
hi link rdfaUrl Preproc
hi link rdfaPrefix Preproc
hi link rdfaError Error

let b:current_syntax = "rdfa"
