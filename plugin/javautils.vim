
scriptencoding utf-8

if exists('g:loaded_javautils')
    finish
endif
let g:loaded_javautils = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists('g:javautils_sortdomains')
    let g:javautils_sortdomains      = ['java','javax','org','com','jp','com.example']
endif
if !exists('g:javautils_getter')
    let g:javautils_getter           = "    /**\n"
    let g:javautils_getter          .= "    * <p>#4#を取得する。</p>\n"
    let g:javautils_getter          .= "    *\n"
    let g:javautils_getter          .= "    * @return #4#\n"
    let g:javautils_getter          .= "    */\n"
    let g:javautils_getter          .= "    public #1# get#2#() {\n"
    let g:javautils_getter          .= "        return this.#3#;\n"
    let g:javautils_getter          .= "    }\n"
endif

if !exists('g:javautils_setter')
    let g:javautils_setter           = "    /**\n"
    let g:javautils_setter          .= "    * <p>#4#を設定する。</p>\n"
    let g:javautils_setter          .= "    *\n"
    let g:javautils_setter          .= "    * @param val #4#\n"
    let g:javautils_setter          .= "    */\n"
    let g:javautils_setter          .= "    public void set#2#(#1# val) { \n"
    let g:javautils_setter          .= "        this.#3# = val;\n"
    let g:javautils_setter          .= "    }\n"
endif
if !exists('g:javautils_encodeFrom')
    let g:javautils_encodeFrom       = 'utf-8'
endif
if !exists('g:javautils_stepcounter_jar')
    let g:javautils_stepcounter_jar  = 'stepcounter-3.0.4-jar-with-dependencies.jar'
endif
if !exists('g:javautils_findbugs_jar')
    let g:javautils_findbugs_jar     = 'findbugs.jar'
endif
if !exists('g:javautils_checkstyle_jar')
    let g:javautils_checkstyle_jar   = 'checkstyle-8.14-all.jar'
endif

let s:javahome=$JAVA_HOME . '/bin/'
let input=expand('~') . '/.java/lib/'
command! -bar -nargs=? JMake :call javautils#make({"param":<q-args>})
command! -bar -nargs=? JMakeDest :call javautils#make({"dest":<q-args>})
command! JMakeThis :call javautils#make('.')
command! -nargs=? JExeJunit :JMake <args>|:call javautils#exejunit()
command! -nargs=? JExe :JMake <args>|:call javautils#exe()
command! JInsertImport :call javautils#insertimport(expand('<cword>'))
command! JAutoImports :call javautils#autoimports()
command! JLoadPackages :call javautils#loadpackages()
command! JOutputMethod :call javautils#outputmethod(expand('<cword>'))
command! JCheckstyleJava :call javautils#checkstyle()
command! JFindbugsJava :call javautils#findbugs()
command! -range JGetterSetter :<line1>,<line2>call javautils#gettersetter()
command! JSetjavahome :call javautils#setjavahome(<q-args>)
"eclipse.ini
"-javaagent:/Oracle/oepe/plugins/jp.sourceforge.mergedoc.pleiades/pleiades.jar
"-Dfile.encoding=utf-8
command! JCodeFormatter :call javautils#JCodeFormatter()
command! -nargs=+ JCodeFormatterParam :call javautils#JCodeFormatterParam(<q-args>)
command! -nargs=+ JStepCounter :call javautils#JStepCounter(<q-args>)
command! JStepCounterThis :call javautils#JStepCounterThis()

let &cpo = s:cpo_save
unlet s:cpo_save
