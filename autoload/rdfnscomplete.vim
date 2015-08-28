if !has('python')
    echoerr "Requires vim compiled with +python"
    finish
endif

python <<END
import vim
import logging
logging.getLogger().addHandler(logging.StreamHandler())
try:
    import rdfns
except ImportError as e:
    print("Failed to load rdfns: %s" % e)
else:
    rdfns_tool = rdfns.Tool()
END


func! rdfnscomplete#complete(findstart, base)
    let line = getline('.')
    let cpos = col('.') - 1

    " 1 - get the text length
    if a:findstart == 1
        while cpos > 0 && line[cpos - 1] =~ '\w\|-'
            let cpos -= 1
        endwhile
        return cpos

    " 0 - return the list of completions
    else
        let context = ''
        while cpos > 0
            let cpos -= 1
            let c = line[cpos]
            if c =~ '\w' || c =~ '\:'
                let context = c . context
                continue
            elseif strlen(context) > 0 || cpos == 0
                break
            endif
        endwhile
        let args = [context, a:base]
        return pyeval("rdfns_tool.get_completions(vim.current.buffer, *vim.eval('l:args'))")

    endif
endfunc


func! rdfnscomplete#reload()
    python rdfns_tool = reload(rdfns).Tool()
endfunc


func! rdfnscomplete#setup(...)
    if a:0 == 0
        let b:rdfns_saved_completefunc = &completefunc
        setlocal completefunc=rdfnscomplete#complete
    elseif a:1 == 'reload'
        call rdfnscomplete#reload()
    elseif a:1 == 'quit'
        if exists('b:rdfns_saved_completefunc')
            let &completefunc=b:rdfns_saved_completefunc
            unlet b:rdfns_saved_completefunc
        endif
    endif
endfunc


" TODO: show label and comment for term/vocab under cursor
"
"func! rdfnscomplete#balloon()
"    return 'Cursor is at line ' . v:beval_lnum . ', column ' . v:beval_col . \
"        ' of file ' .  bufname(v:beval_bufnr) . ' on word "' . v:beval_text . '"'
"endfunc
"
"set bexpr=rdfnscomplete#balloon()
"setl ballooneval
