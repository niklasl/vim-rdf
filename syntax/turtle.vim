" Vim syntax file
" Language:     Turtle - Terse RDF Triple Language
" Version:      1.1
" SeeAlso:      <http://www.w3.org/TR/turtle/>
" Maintainer:   Niklas Lindstrom <lindstream@gmail.com>

let n3_actually = 0
runtime! syntax/n3.vim
unlet b:current_syntax

syn match   turtleDeclaration       "\<prefix\>\|\<base\>\c"
hi def link turtleDeclaration n3Declaration

syn region turtleString         matchgroup=n3StringDelim start=+'+ end=+'+ skip=+\\\\\|\\'+ contains=n3Escape
hi def link turtleString n3String
syn region turtleMultilineString matchgroup=n3StringDelim start=+'''+ end=+'''+ skip=+\\\\\|\\'+ keepend contains=n3Escape
hi def link turtleMultilineString n3MultilineString

let b:current_syntax = "turtle"
