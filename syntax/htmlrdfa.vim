if exists("b:current_syntax")
  finish
endif

runtime! syntax/html.vim
runtime! syntax/html/*.vim
unlet b:current_syntax
runtime! syntax/rdfa.vim
unlet b:current_syntax

"syn cluster htmlPreproc add=rdfaExpr,rdfaLink

syn region rdfaExpr matchgroup=htmlString start=+\(\(prefix\|property\|rel\|rev\|typeof\)=\)\@9<=\z(["']\)+ keepend end=+\z1+ containedin=htmlTag contained
syn region rdfaLink matchgroup=htmlString start=+\(\(about\|datatype\|href\|resource\|src\|vocab\)=\)\@9<=\z(["']\)+ keepend end=+\z1+ containedin=htmlTag contained

let b:current_syntax = "htmlrdfa"
