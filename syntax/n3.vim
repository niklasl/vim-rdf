" Vim syntax file
" Language:     RDF Notation 3
" Version:      1.1
" SeeAlso:      <http://www.w3.org/DesignIssues/Notation3.html>
" Maintainer:   Niklas Lindstrom <lindstream@gmail.com>
" Created:      2004-03-24
" Updated:      2014-02-10

" TODO:
"   * string value specials
"   * fix XML Literal syntax (triplequoutes PLUS ^^rdfs:XMLLiteral)
"   * "@"-prefix of verbs (?)
"   * grouping e.g. statements to enable folding, error checking etc.


if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" TODO: factor out triplebase
if !exists('n3_actually')
  let n3_actually = 1
endif


syn keyword n3Verb              a
syn match   n3Separator         "[][;,)(}{^!]"
syn match   n3EndStatement      "\."
syn match   n3Declaration       "@prefix\|@base"
"syn match   n3LName             "\(:\?\)\@<=[a-zA-Z_][a-zA-Z0-9_]*"
syn match   n3ClassName         "\(:\?\)\@<=[A-Z][a-zA-Z0-9_-]*"
syn match   n3PropertyName      "\(:\?\)\@<=[a-z][a-zA-Z0-9_-]*"
syn match   n3Prefix            "\([a-zA-Z_][a-zA-Z0-9_]*\)\?:"
syn match   n3Comment           "#.*$" contains=n3Todo
syn keyword n3Todo              TODO FIXME XXX contained

if n3_actually
  syn match   n3Declaration       "@keywords"
  syn keyword n3Verb            has is of
  syn match   n3Quantifier        "@forAll\|@forSome"
  syn match   n3Deprecated        "@this"
endif

" URI:s, strings, numbers, variables
syn match n3Number              "[-+]\?[0-9]\+\(\.[0-9]\+\)\?\(e[-+]\?[0-9]\+\)\?"
syn keyword n3Boolean           true false
syn match n3Variable            "?[a-zA-Z_][a-zA-Z0-9_]*"
syn region n3URI                matchgroup=n3URI start=+<+ end=+>+ skip=+\\\\\|\\"+ contains=n3URITokens
" TODO: n3URITokens
syn region n3String             matchgroup=n3StringDelim start=+"+ end=+"+ skip=+\\\\\|\\"+ contains=n3Escape
" TODO: n3Escape
syn region n3MultilineString    matchgroup=n3StringDelim start=+"""+ end=+"""+ skip=+\\\\\|\\"+ keepend contains=n3Escape

syn match   n3Verb              "<=\|=>\|="

" Lang notation
syn match n3Langcode  +\("\s*\)\@<=@[a-zA-Z0-9]\+\(-[a-zA-Z0-9]\+\)\?+

" Type notation
syn match n3Datatype +\("\s*\)\@<=^^+
" TODO: then follows: explicituri | qname

" XMLLiteral and HTML
if version >= 600 || filereadable(expand("<sfile>:p:h")."/xml.vim")
  if version < 600
    syn include @n3XMLLiteral <sfile>:p:h/xml.vim
    unlet b:current_syntax
  else
    syn include @n3XMLLiteral syntax/xml.vim
    unlet b:current_syntax
    "syn include @n3HTML syntax/html.vim
    "unlet b:current_syntax
  endif
  syn region n3XMLLiteralRegion matchgroup=n3StringDelim start=+"""\(\_s*<\)\@=+ end=+"""+ keepend contains=@n3XMLLiteral
  " end=+"""\(\^\^\w*:XMLLiteral\)\@=+
  "syn region n3HTMLRegion matchgroup=n3StringDelim start=+"""+ end=+"""\(\^\^\w*:HTML\)\@=+ keepend contains=@n3HTML
endif


" Highlight Links

if version >= 508 || !exists("did_n3_syn_inits")
  if version <= 508
    let did_n3_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  " The default methods for highlighting.  Can be overridden later
  HiLink n3Verb                 keyword
  HiLink n3Quantifier           keyword
  HiLink n3Separator            Operator
  HiLink n3EndStatement         Special
  "hi n3EndStatement gui=underline,bold " TODO: just remove?
  HiLink n3Declaration          PreCondit
  HiLink n3Prefix               Special
  "HiLink n3LName                Normal
  HiLink n3ClassName            Type
  HiLink n3PropertyName         Function
  HiLink n3Comment              Comment
  HiLink n3Todo                 Todo
  HiLink n3Deprecated           Error
  HiLink n3Number               Number
  HiLink n3Boolean              Boolean
  HiLink n3Variable             Identifier
  HiLink n3URI                  Label
  HiLink n3String               String
  HiLink n3MultilineString      String
  HiLink n3StringDelim          Constant
  HiLink n3Langcode             Type
  HiLink n3Datatype             Type
  HiLink n3XMLLiteralRegion     String

  delcommand HiLink
endif


unlet n3_actually

let b:current_syntax = "n3"
