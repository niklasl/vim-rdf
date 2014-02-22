" Vim syntax file
" Language:     Turtle - Terse RDF Triple Language
" Version:      1.0
" SeeAlso:      <http://www.w3.org/TR/turtle/>
" Maintainer:   Niklas Lindstrom <lindstream@gmail.com>

let n3_actually = 0
runtime! syntax/n3.vim
unlet b:current_syntax

syn match   turtleDeclaration       "\<prefix\>\|\<base\>\c"
hi def link turtleDeclaration n3Declaration

let b:current_syntax = "turtle"
