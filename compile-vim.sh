#! /bin/bash
set -e

# Note for me
false && 
{
    lua download page
    http://www.lua.org/download.html
    tcl download page
    http://www.tcl.tk/software/tcltk/download.html

    一个 xxx_feat 能处理 config remove 这两个参数
    config 在配置的时候调用 remove 在移除的时候调用
}

FEATURES=( lua python puthon3 perl tcl ole static )
WITH_FEATURES=()

# setup environment
# should modify here to suit you self
setup_env()
{
    : ${CROSS_COMPILE:=''}

    : ${CYGWIN_FLAG:=no}
    : ${MINGW_FLAG:=no}

    : ${WORK_DIR:=$PWD}
    : ${TARGET_DIR:=$WORK_DIR/target}

    : ${COMPILE_BY_USERDOMAIN:=$USERDOMAIN}
    : ${COMPILE_BY_USERNAME:=$USERNAME}


    # download urls
    LUA_DL_URL=http://www.lua.org/ftp/lua-5.2.3.tar.gz
    VIM_DL_URL=https://codeload.github.com/b4winckler/vim/zip/master
    PERL_DL_URL=
    TCL_DL_URL=http://prdownloads.sourceforge.net/tcl/tcl8.6.1-src.tar.gz

    VIM_DL_URL=ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2

    # tools with some default flags
    : ${WGET:='wget -N -nv -o /dev/null --progress=bar '}
    : ${TAR:='tar -x -f'}
    : ${MAKE:='-sB -j8'}

    # for vim
    VIM_FLAGS=( STATIC_STDCPLUS=yes FEATURES=HUGE )
    VIM_FLAGS+=("USERNAME=$COMPILE_BY_USERNAME" "USERDOMAIN=$COMPILE_BY_USERDOMAIN")

    # dyn
    [ "$CROSS_COMPILE" == '' ] || VIM_FLAGS+=( "CROSS_COMPILE=$CROSS_COMPILE" )
}

executable()
{
    command -v $1 > /dev/null && return 0 || return 1
}

useage()
{
    echo -en " 
UESAGE: $(basename $0) [options] [features]
Use to compile vim with extra features automatically

features:
    ${FEATURES[@]}

misc:
    -h display this message
    -r report only
    -p plain text, no color
    -F force re-download

platform:
    -c cygwin
    -m mingw
    -C cross compile prefix

compile:
    -S use static
    -U username [default $$USERNAME]
    -D userdomain [default $$USERDOMAIN]
    
place:
    -w work place [default $$PWD]
    -t target dir [default $$WORK_DIR/target]

require:
    wget

VERSION: 1.0
AUTHOR: wener
BLOG: http://blog.wener.me
THIS PROJECT: https://github.com/wenerme/compile-vim
"
}

# report env
r_env()
{
    echolb Current enviroment setting

    local vars=( CROSS_COMPILE CYGWIN_FLAG MINGW_FLAG \
        COMPILE_BY_USERDOMAIN COMPILE_BY_USERNAME STATIC_FLAG )

    for var_name in "${vars[@]}"
    do
        echo -e "$var_name \t: '${!var_name}'"
    done

    echo -e "WITH_FEATURES \t: ${WITH_FEATURES[@]}"
    echo -e "VIM_FLAGS\t: ${VIM_FLAGS[@]}"
}

echocolor(){ [ "$NO_COLOR_FLAG" == 'yes' ] && shift; echo -e "$@" "\e[0m" ;}
echor(){ echocolor "\e[0;31m" "$@" ; }
echog(){ echocolor "\e[0;32m" "$@" ; }
echoy(){ echocolor "\e[0;33m" "$@" ; }
echob(){ echocolor "\e[0;34m" "$@" ; }
# l for light
echolr(){ echocolor "\e[1;31m" "$@" ; }
echolg(){ echocolor "\e[1;32m" "$@" ; }
echoly(){ echocolor "\e[1;33m" "$@" ; }
echolb(){ echocolor "\e[1;34m" "$@" ; }

dl()
{
    case $# in
        0)
            echo "
            ERROR: no parameter for dl
            UESAGE: dl url [saveas]"
            ;;
        1)
            ;;
    esac
}

when_config(){ [ $1 == 'config' ] && return 0 || return 1; }
when_clean(){ [ $1 == 'clean' ] && return 0 || return 1 ; }
when_unknown(){ echolr "unknown action" "$@" ; }

isstatic()
{
    [ "$STATIC_FLAG" == 'yes' ] && return 0 || return 1
}

lua_feat()
{
    when_config "$@" && 
    {
        verbose $FUNCNAME download url $LUA_DL_URL

        local fn=`basename $LUA_DL_URL`
        local ver=`echo $fn | sed -rne 's/[^0-9]//gip' | sed -rne 's/([0-9]{2}).*/\1/p'`

        verbose $FUNCNAME: download
        $WGET $LUA_DL_URL
        tar -xf $fn

        verbose $FUNCNAME: compile
        cd ${fn%.tar.*}

        $MAKE clean
        rm -rf install

        $MAKE mingw \
            CC=${CROSS_COMPILE}gcc \
            "AR=${CROSS_COMPILE}ar rcu" \
            RANLIB=${CROSS_COMPILE}ranlib

        $MAKE local
        cp install/lib/liblua.a install/lib/lua52.lib

        VIM_FLAGS+=( LUA_VER=$ver LUA=$PWD/install )
        isstatic lua && VIM_FLAGS+=( DYNAMIC_LUA=no )

        # done
        cd ..
        return 0
    }

    when_unknown "$@"
}

install_vim()
{
    verbose $FUNCNAME: download from $VIM_DL_URL

    $WGET $VIM_DL_URL
    $TAR `basename $VIM_DL_URL`

    verbose $FUNCNAME: download patches
    mkdir -p patches && cd $_
    $WGET ftp://ftp.vim.org/pub/vim/patches/7.4/7.4.*
    cd ..

    verbose $FUNCNAME: apply patches
    cd vim74
    for i in ../patches/7.4.*
    do
        patch -st -p0 < $i || 
        {
            echo error code $?
            echor failed when applying patch $i
            exit 1
        }
    done

    verbose $FUNCNAME: compile vim
    echoy VIM_FLAGS: ${VIM_FLAGS[@]}
    cd src
    $MAKE -f Make_cyg.mak ${VIM_FLAGS[@]} gvim.exe

    cd ../..
}

guess_cygwin()
{
    local prefixes=( i686-pc-mingw32 i686-w64-mingw32 )
    for p in "${prefixes[@]}"
    do
        executable "$p-gcc" && executable "$p-g++" && CROSS_COMPILE=$p- && break
    done

}

verbose()
{
    [ "$VERBOSE_FLAG" == 'yes' ] && 
    {
        [ $# == 0 ] || echoly $@
        return 0
    } || return 1
}

# parse options
while getopts "hrpvcmSFt:w:U:D:C:" arg;
do
    case $arg in
        h)
            useage
            exit
            ;;
        v)
            VERBOSE_FLAG=yes
            ;;
        r)
            REPORT_ONLY_FLAG=yes
            ;;
        c)
            CYGWIN_FLAG=yes
            guess_cygwin
            ;;
        m)
            MINGW_FLAG=yes
            ;;
        p)
            NO_COLOR_FLAG=yes
            ;;
        S)
            STATIC_FLAG=yes
            ;;
        C)
            CROSS_COMPILE=$OPTARG
            ;;
        t)
            TARGET_DIR=$OPTARG
            ;;
        w)
            WORK_DIR=$OPTARG
            ;;
        U)
            COMPILE_BY_USERNAME=$OPTARG
            ;;
        D)
            COMPILE_BY_USERDOMAIN=$OPTARG
            ;;
        ?)
            echo  "$0 -h for more information"
            exit 1
            ;;
    esac
done

verbose remove parsed options
shift $(($OPTIND - 1))
verbose parse feature
for feat in "$@"
do
    feat=${feat,,}
    case "${FEATURES[@]}" in
        *"$feat"* )
            WITH_FEATURES+=($feat)
            ;;
        *)
            echor ERROR: unrecornize feature $feat
            echo features could be: ${FEATURES[@]}
            exit 1
            ;;
    esac
done

setup_env
r_env

# report only, exit now
[ "$REPORT_ONLY_FLAG" == 'yes' ] && exit 0


verbose setup directory
mkdir -p $WORK_DIR
mkdir -p $TARGET_DIR

cd $WORK_DIR

verbose config feature
for feat in "${WITH_FEATURES[@]}"
do
    featfn=${feat}_feat
    executable $featfn || 
    {
        echor "deal feature '$feat' failed, '$featfn' not found"
        exit 1
    }

    echolg $feat dealing
    $featfn config
    echolg "$feat done"
done

install_vim


echolb "everything is done"

# vim: set ft=sh sw=4 ts=4 sts=4 et tw=78 fmr={,} foldlevel=0 fdm=marker spell:
