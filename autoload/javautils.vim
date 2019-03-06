
scriptencoding utf-8

if !exists('g:loaded_javautils')
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

let s:f=javautils#funclib#new()
let s:javahome=$JAVA_HOME
let s:javaversion=fnamemodify(s:javahome,':t')
let s:classpass=fnamemodify(expand('<sfile>:h') . '/../rplugin/java/',':p:h')
let s:encodeTo='utf-8'

function! javautils#setjavahome(javahome)
    let s:javahome = a:javahome
    let s:javaversion=fnamemodify(s:javahome,':t')
endfunction
function! s:getjavacexe()
    return shellescape(s:javahome . '/bin/javac') . ' -cp ' . shellescape(s:getclasspath())
endfunction
function! s:getjavaexe()
    return shellescape(s:javahome . '/bin/java') . ' -cp ' . shellescape(s:getclasspath())
endfunction
function! s:getclasspath()
    let ret=[]
    call add(ret,'.')
    call add(ret, fnamemodify($JAVA_HOME . '/jre/lib/rt.jar',':p'))
    call add(ret,fnamemodify(expand('~') . '/.java/' . s:javaversion . '/classes/',':p:h'))
    call add(ret,s:classpass)
    if exists('g:javautils_classpath')
        call extend(ret,g:javautils_classpath)
    endif
    let sep=';'
    if has('win32')
        let sep = ";"
    else
        let sep = ":"
    endif
    return join(ret,sep)
endfunction
function! s:setclasspath()
    "let $CLASSPATH=s:getclasspath()
endfunction
function! javautils#findbugs()
    if expand('%:e') != "java" | return | endif
    call s:setclasspath()
    let package=matchstr(join(filter(readfile(expand('%:p')),{_,x->x=~'\v^\s*package\s+.+;'})),'\v^\s*package\s+\zs.+\ze;')
    let dest=expand('~') . '/.java/' . s:javaversion . '/classes/' . substitute(package,'\.','/','g') . '/'
    let dest=substitute(dest,'//','/','g')
    let input=expand('~') . '/.java/lib/'
    call javautils#make({'dest':expand('~') . '/.java/' . s:javaversion . '/classes/'})
    let cmd= s:getjavaexe() . ' -jar ' . input . g:javautils_findbugs_jar . ' -textui -auxclasspath "' . join(s:getclasspath(),';') . '" ' .  dest . expand('%:r') . '.class'
    "echom cmd
    let o=split(system(cmd),"\n")
    let o=map(o, {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('Findbugs','',s:encodeTo)
        call append(0, cmd)
        call append(1, o)
    endif
endfunction
function! javautils#checkstyle()
    if expand('%:e') != "java" | return | endif
    call s:setclasspath()
    let input=expand('~') . '/.java/lib/'
    let cmd= s:getjavaexe() . ' -jar ' . input . g:javautils_checkstyle_jar . ' -c ' . input . 'sun_checks.xml ' . expand('%')
    "echom cmd
    let o=split(system(cmd),"\n")
    let o=map(o, {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('Checkstyle','',s:encodeTo)
        call append(0, cmd)
        call append(1, o)
    endif
endfunction
function! javautils#make(opt)
    if expand('%:e') != "java" | return | endif
    call s:setclasspath()
    if type(a:opt) == v:t_string
        let dest='.'
        let param=''
    else
        let dest=expand('~') . '/.java/' . s:javaversion . '/classes'
        if !empty(get(a:opt,'dest',''))
            let dest=get(a:opt,'dest','')
        endif
        let param=substitute(get(a:opt,'param',''),'\v^''|''$','','g')
    endif
    if !isdirectory(dest)
        call mkdir(dest,"p")
    endif
    "echom param
    let cmd= s:getjavacexe() . ' ' . param . ' -encoding utf-8 -d ' . dest . ' ' . expand('%')
    "echom cmd
    let o=split(system(cmd),"\n")
    let o=map(o, {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('CompileError','',s:encodeTo)
        call append(0, cmd)
        call append(1, o)
    endif
endfunction
function! javautils#exejunit()
    if expand('%:e') != "java" | return | endif
    call s:setclasspath()
    let cmd= s:getjavaexe() . ' org.junit.runner.JUnitCore ' . expand('%:p:t:r')
    let o=split(system(cmd), "\n")
    let o=map(o, {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('JavaConsole', '', s:encodeTo)
        call append (0, o)
    endif
endfunction
function! javautils#exe(...)
    if expand('%:e') != "java" | return | endif
    call s:setclasspath()
    let package=filter(readfile(expand('%:p')),{_,x->x =~ '\v^\s*package\s+'})
    let package=matchstr(join(package),'\v^\s*package\s+\zs.*\ze\s*;')
    if package != ''
        let cmd= s:getjavaexe() . ' ' . package . '.' . expand('%:p:t:r') . ' ' . join(a:000)
    else
        let cmd= s:getjavaexe() . ' ' . expand('%:p:t:r') . ' ' . join(a:000)
    endif
    let o=split(system(cmd), "\n")
    let o=map(o, {_,x->iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('JavaConsole','',s:encodeTo)
        call append(0, o)
    endif
endfunction
function! javautils#autoimports()
    if expand('%:e') != "java" | return | endif
    let srclist=map(getline(0,'$'), {_,x->substitute(x,'\v"\zs%(\\(")@=|.)+\ze"', '' , 'g')})
    let srclist=map(srclist, {_,x->substitute(x,'\v\zs\/\/.*$','','')})
    let srcstr=substitute(join(srclist, ''),'\v\zs\/\*.{-}\*\/','', 'g')
    let mstrlist=[]
    while 1
        let mstr=matchstr(srcstr,'\v(\.)@<!(<\u\w+>)\ze')
        if mstr == ''
            break
        else
            call add(mstrlist,mstr)
        endif
        let srcstr=substitute(srcstr,'\v(\.)@<!(<\u\w+>)\ze','','')
    endwhile
    let imports=[]
    let save_cursor = getcurpos()
    let tmp=@a
    let @a=''
    let list=[]
    silent g/\v^\s*import/ call add(list,line('.'))
    exe 'silent ' . min(list) . ',' . max(list) . 'g/^\s*$/ d'
    silent g/\v^\s*import/ yank A
    let imports=split(@a, '\n')
    let @a=tmp
    "echom string(mstrlist)
    for class in uniq(sort(mstrlist))
        let imp=s:getimport(class, 1)
        if imp!=''
            call add(imports, imp)
        endif
    endfor
    call s:insertimports(imports)
    call setpos('.', save_cursor)
    "w!
    "JavaCodeFormatter
endfunction
function! javautils#outputmethod(class)
    if a:class[0] !~ '^\C[A-Z]'
        let save_cursor = getcurpos()
        call searchdecl(a:class)
        call search('\<','b')
        nohlsearch
        let class = expand('<cword>')
        call setpos('.', save_cursor)
    else
        let class = a:class
    endif
    echom class
    let o=s:getmethod(class)
    let o=map (o, {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('OutputMethod','', s:encodeTo)
        call append(0, o)
        silent %EasyAlign / /
        norm gg
    endif
endfunction
function! s:getmethod(class)
    call s:setclasspath()
    if empty(g:insertimportDict)
        call javautils#loadpackages()
    endif
    let absclass=a:class
    let size=len(get(g:insertimportDict,a:class,[]))
    if size==1
        let absclass=g:insertimportDict[a:class][0] . '.' . a:class
    elseif size>1
        echom 'select package-> ' .a:class
        let ans=inputlist(map(g:insertimportDict[a:class][:], {i,x->(i+1).':' .x}))
        if ans!='' && size>=ans
            let absclass=g:insertimportDict[a:class][ans-1] . '.' . a:class
        endif
        redraw
    else
        "return []
    endif
    let ret = split(system(s:getjavaexe() . ' OutputMethod ' . absclass),'\n')
    return ret
endfunction
function! s:createimportclasses(cmd)
    call s:setclasspath()
    let ret=[]
    call extend(ret, split(system(a:cmd),'\n'))
    return uniq(sort(ret))
endfunction
function! s:cleanimports()
    let save_cursor = getcurpos()
    let tmp=@a
    let @a=''
    let list=[]
    silent g/\v^\s*import/ call add(list,line('.'))
    exe 'silent ' . min(list) . ',' . max(list) . 'g/^\s*$/ d'
    silent g/\v^\s*import/ yank A
    let imports=split(@a,'\n')
    call s:insertimports(imports)
    let @a=tmp
    call setpos('.', save_cursor)
endfunction
function! javautils#insertimport(class)
    if expand('%:e') != "java" | return | endif
    let save_cursor = getcurpos()
    let imp=s:getimport(a:class, 0)
    if imp!=''
        call append('$', imp)
    endif
    call s:cleanimports()
    call setpos ('.', save_cursor)
endfunction
if !exists('g:insertimportDict')
    let g:insertimportDict={}
endif
function! javautils#loadpackages()
    let g:insertimportDict = {}
    function! s:Callback(insertimportDict, import) closure
        let keyval = split(a:import, '\zs\.\ze[^.]*$')
        let key = get(keyval, 1,'')
        let value = get(keyval,0,'')
        if !has_key(a:insertimportDict,key)
            let a:insertimportDict[key] = []
        endif
        call add(a:insertimportDict[key], value)
        call uniq(sort(a:insertimportDict[key]))
    endfunction
    echom 'searching import classes start'
    call s:setclasspath()
    for import in uniq(sort(s:createimportclasses(s:getjavaexe() . ' ClassSearch')))
        call s:Callback(g:insertimportDict, import)
    endfor
    echom 'searching import classes end'
endfunction
function! s:getimport(class, igjavalang)
    if empty(g:insertimportDict)
        call javautils#loadpackages()
    endif
    norm gg
    if a:class == '' || a:class =='*' || a:class == expand('%:r') || search('\v^\s*import.*<' . a:class . '>','c') >0
        return ''
    endif
    norm gg
    let ret=''
    if !a:igjavalang || len(filter(get(g:insertimportDict,a:class, [])[:], {_,x->x =~ '^java\.lang$'})) ==0
        let size=len(get(g:insertimportDict, a:class, []))
        if size==1
            let ret=g:insertimportDict[a:class][0]
        elseif size>1
            echom 'select package-> ' .a:class
            let ans=inputlist(map(g:insertimportDict[a:class][:], {i,x->(i+1).':'.x}))
            if ans!='' && size>=ans
                let ret=g:insertimportDict[a:class][ans-1]
            endif
            redraw
        endif
    endif
    if ret!=''
        let ret="import " . ret . '.' . a:class . ';'
    endif
    return ret
endfunction
function! s:insertimports(imports)
    if empty(a:imports)
        return
    endif
    norm gg
    if search('^package','c') ==0
        let package=''
    else
        let package=matchstr(getline('.'),'\v^\s*package\s+\zs.*\ze;')
    endif
    silent g/\v^\s*import/ d

    let importdict={}
    let importlist=s:distinctimport(package,a:imports)
    let javautils_sortdomains = {}
    call map(g:javautils_sortdomains[:],{i,x->extend(javautils_sortdomains,{x:i})})
    for imp in importlist
        let breakflg=0
        for key in sort(keys(javautils_sortdomains),{x,y->len(x) == len(y) ? 0 : len(x) < len(y) ? 1 : -1})
            if matchstr(imp,'^import \zs.\+') =~ '^\V' . key
                if !has_key(importdict,key)
                    let importdict[key] = []
                endif
                call add(importdict[key],imp)
                let breakflg=1
                break
            endif
        endfor
        if breakflg==0
            if !has_key(importdict,'-')
                let importdict['-'] = []
            endif
            call add(importdict['-'],imp)
        endif
    endfor
    "echom string(importdict)
    let importlist=[]
    for [key,val] in sort(items(javautils_sortdomains),{x,y->x[1] == y[1] ? 0 : x[1] > y[1] ? 1 : -1})
        let importlist3=get(importdict,key,[])
        let importlist3=map(importlist3,{i,x->[get(javautils_sortdomains,key,'999'),x]})
        let importlist3=map(uniq(sort(importlist3,{x,y->x[0] == y[0] ? x[1] == y[1] ? 0 : x[1] > y[1] ? 1 : -1 : x[0] > y[0] ? 1 : -1})),{_,x->x[1]})
        call extend(importlist,importlist3)
    endfor
    let importlist3=get(importdict,'-',[])
    let importlist3=map(importlist3,{i,x->[get(javautils_sortdomains,'-','999'),x]})
    let importlist3=map(uniq(sort(importlist3,{x,y->x[0] == y[0] ? x[1] == y[1] ? 0 : x[1] > y[1] ? 1 : -1 : x[0] > y[0] ? 1 : -1})),{_,x->x[1]})
    call extend(importlist,importlist3)
    if empty(importlist)
        echo a:imports
        return
    endif
    let tempimp=''
    let importlist2=[]
    for imp in importlist
        if matchstr(imp,'^import \zs\w\+') != matchstr(tempimp,'^import \zs\w\+')
            let tempimp=imp
            call add(importlist2,'')
        endif
        call add(importlist2,imp)
    endfor
    call remove(importlist2,0)
    norm gg
    if search('^package','c') > 0
        if getline(line('.')+1) == ''
            norm j
        else
            norm o
        endif
    else
        if getline(line('.')) != ''
            norm O
        endif
    endif
    silent put =importlist2
    if getline('.') == ''
        silent norm dd _
    endif
endfunction
function! s:distinctimport(package, importlist)
    let ret=a:importlist[:]
    if !empty(a:package)
        let ret=filter(ret, {_,x->x !~ '\v^\s*import\s+' . substitute(a:package,'\.','\\.','g') . '\.[^.]+$'})
    endif
    let delimport=[]
    let srcstr=join(filter(getline(0,'$'), {_,x->x !~ '\v^\s*//'}))
    for class in map(ret[:], {_,x->matchstr (x, '\v.*\.\zs.*\ze;\s*$')})
        if class != '*' && srcstr !~ '\v\C<' . class . '>'
            call add(delimport,class)
        endif
    endfor
    if !empty(delimport)
        let ret=filter(ret, {_,x->x !~ '\v\C' . join(delimport,'|')})
    endif
    return ret
endfunction
function! javautils#gettersetter() range
    let ret=['']
    let list = getline(a:firstline, a:lastline)
    let str4=''
    for line in list
        if trim(line)==''
            continue
        endif
        if line =~ '\v\s*\/\*'
            let str4=trim(matchstr(line,'\v\s*\/\*\*?\s*\zs.+\ze\*\/'))
            continue
        endif
        let line = substitute(line,'\v\s*private\s+','','')
        let str3 = matchstr(line,'\v\zs\w+\ze\s*;$')
        let str1 = substitute(line,'\v\zs\s+\w+\s*;$','','')
        let str2 = toupper(str3[0]) . str3[1:]
        if str4==''
            let str4=str3
        endif
        let setter = g:javautils_setter
        let setter = substitute(setter,'#1#',str1,'g')
        let setter = substitute(setter,'#2#',str2,'g')
        let setter = substitute(setter,'#3#',str3,'g')
        let setter = substitute(setter,'#4#',str4,'g')
        let getter = g:javautils_getter
        let getter = substitute(getter,'#1#',str1,'g')
        let getter = substitute(getter,'#2#',str2,'g')
        let getter = substitute(getter,'#3#',str3,'g')
        let getter = substitute(getter,'#4#',str4,'g')
        call extend(ret,split(setter,"\n",1))
        call extend(ret,split(getter,"\n",1))
        let str4=''
    endfor
    call append(a:lastline,ret)
    call cursor(a:lastline+1,0)
    exe 'norm V' . len(ret) . 'j='
endfunction
function javautils#JCodeFormatterFiles(...)
    let input=expand('~') . '/.java/lib/'
    let cmd = 'eclipse -nosplash -application org.eclipse.jdt.core.JavaCodeFormatter -verbose -config ' . input . 'formatter.prefs ' . join(a:000)
    echom cmd
    echo substitute(system(cmd), "\v[\r\n]+", "\r", "g")
endfunction
function javautils#JCodeFormatter()
    if expand('%:e') != "java" | return | endif
    call javautils#JCodeFormatterFiles(expand('%:p'))
endfunction
function javautils#JStepCounterFiles(...)
    let input=expand('~') . '/.java/lib/'
    let cmd =s:getjavaexe() . ' -cp ' . input . g:javautils_stepcounter_jar . ' jp.sf.amateras.stepcounter.Main java ' . join(a:000)
    echom cmd
    let o=map(split(system(cmd),'\n'), {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('JStepCounter','', s:encodeTo)
        call append(0, o)
        norm gg
    endif
endfunction
function javautils#JGoogleFormatter()
    if expand('%:e') != "java" | return | endif
    let input=expand('~') . '/.java/lib/'
    let cmd =s:getjavaexe() . ' -jar ' . input . g:javautils_google_formatter_jar
    echom cmd
    exe '%!' . cmd . ' -'
endfunction
function javautils#JGoogleFormatterFiles(...)
    let input=expand('~') . '/.java/lib/'
    let cmd =s:getjavaexe() . ' -jar ' . input . g:javautils_google_formatter_jar . ' ' . join(a:000)
    echom cmd
    let o=map(split(system(cmd),'\n'), {_,x-> iconv(x,g:javautils_encodeFrom,s:encodeTo)})
    if !empty(o)
        call s:f.newBuffer('JGoogleFormatter','', s:encodeTo)
        call append(0, o)
        norm gg
    endif
endfunction
function javautils#JStepCounter()
    if expand('%:e') != "java" | return | endif
    call javautils#JStepCounterFiles(expand('%'))
endfunction


let &cpo = s:cpo_save
unlet s:cpo_save

