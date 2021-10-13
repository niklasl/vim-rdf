if !has('python3')
    echoerr "Requires vim compiled with +python3"
    finish
endif

python3 <<END
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
        return py3eval("rdfns_tool.get_completions(vim.current.buffer, *vim.eval('l:args'))")

    endif
endfunc


func! rdfnscomplete#reload()
    python3 import importlib
    python3 rdfns_tool = importlib.reload(rdfns).Tool()
endfunc


func! rdfnscomplete#includeexpr(uri)
    return py3eval("rdfns_tool.graphcache.get_fs_path(vim.eval('a:uri'))")
endfunc


func! rdfnscomplete#fspath(uri)
    return py3eval("rdfns_tool.graphcache.get_fs_path(vim.eval('a:uri'))")
endfunc


func! rdfnscomplete#expand_pfx(pfx)
    return py3eval("rdfns_tool.expand_pfx(vim.current.buffer, vim.eval('a:pfx'))")
endfunc


func! rdfnscomplete#to_pfx(uri)
    return py3eval("rdfns_tool.to_pfx(vim.current.buffer, vim.eval('a:uri'))")
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
