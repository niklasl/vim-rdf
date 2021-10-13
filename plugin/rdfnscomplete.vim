"===============================================================
" RDF Vocabulary Namespace Completion for Vim 7+
" Maintainer: Niklas Lindström <lindstream@gmail.com>
" Version: 1.4.2
" Updated: 2016-04-08
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
" to restore the original omnifunc (if any).
"
" REQUIRES:
" Vim compiled with Python and RDFLib installed for Python.
"
"===============================================================


func! s:RdfnsArgs(A,L,P)
    return "reload\nquit"
endfunc

command! -complete=custom,s:RdfnsArgs -nargs=* RDF :call <SID>RDFSetup(<f-args>)

func! s:RDFSetup(...)
    if a:0 > 0
        if a:1 == 'reload'
            call rdfnscomplete#reload()
        elseif a:1 == 'quit'
            if exists('b:rdfns_saved_omnifunc')
                let &omnifunc=b:rdfns_saved_omnifunc
                unlet b:rdfns_saved_omnifunc
            endif
            " TODO: restore original mapping (if any)
            nunmap <buffer> <leader>d
        endif
    else
        let b:rdfns_saved_omnifunc = &omnifunc
        setlocal omnifunc=rdfnscomplete#complete
        nnoremap <buffer> <leader>d :call <SID>OpenRDFTerm()<CR>
    endif
endfunc

func! s:OpenRDFTerm()
    let pname = expand("<cWORD>")
    let pname = substitute(pname, '^[\^]\+\|[,;]$', "", 'g')
    let colonidx = stridx(pname, ':')
    if colonidx == -1
        return
    endif
    let pfx = colonidx? pname[0:colonidx-1] : ''
    let lname = pname[colonidx+1:]
    let uri = rdfnscomplete#expand_pfx(pfx)
    try
        let fspath = rdfnscomplete#fspath(uri)
    catch
        let fspath = ''
    endtry
    if fspath != ''
        let fpath = fnameescape(fspath)
        if bufloaded(fspath)
            exec "sb ". fpath
        else
            exec "sp ". fpath
        endif
        let lpfx = rdfnscomplete#to_pfx(uri)
        call search('^'. lpfx .':'. lname)
    endif
endfunc
