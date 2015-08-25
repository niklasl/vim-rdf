"===============================================================
" RDF Vocabulary Namespace Completion for Vim 7+
" Maintainer: Niklas Lindström <lindstream@gmail.com>
" Version: 1.4.1
" Updated: 2015-08-26
" Published: 2007-03-25
" URL: <http://www.vim.org/scripts/script.php?script_id=1835>
"===============================================================
"
" USAGE:
" In a file with namespace prefix declarations similar to XML, Turtle or
" SPARQL, call
"
"   :RDF
"
" to turn on completion on terms within a namespace using the preceding prefix.
"
" This will load prefixes and vocabularies from the web, and cache them in one
" of the following dirs:
"
"   - $RDF_VOCAB_CACHE (environment variable)
"   - ~/rdf-vocab-cache/
"   - ~/Documents/rdf-vocab-cache/
"   - /usr/local/share/rdf-vocab-cache/
"
" Completion will work on:
"
"   - [..]:__       -> all terms from vocabulary bound to given prefix
"   - ..            -> anything known, both prefixes and non-prefixed terms
"   - xmlns:..      -> any namespaces gathered from usage in loaded files; xml
"                      atribute-style
"   - prefix [..]   -> -|| -; Turtle/SPARQL-style (<..namespace..>)
"
" Prefixes are bound to vocabularies by looking for matches like:
"
"   - XML: xmlns:[PFX]="..."
"   - Turtle: @prefix [PFX] <...>
"   - SPARQL: PREFIX [PFX] <...>
"   - JSON-LD: '"[PFX]|@vocab": "..."'
"   - RDFa: vocab="..."
"
" Call
"
"   :RDF reload
"
" to reload cached data, and
"
"   :RDF quit
"
" to restore the original completefunc (if any).
"
" REQUIRES:
" Vim compiled with Python and RDFLib installed for Python.
"
"===============================================================


func! s:RdfnsArgs(A,L,P)
    return "reload\nquit"
endfunc

command! -complete=custom,s:RdfnsArgs -nargs=* RDF :call rdfnscomplete#setup(<f-args>)
