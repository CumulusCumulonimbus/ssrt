#!/usr/bin/env bash

___printversion(){
  
cat << 'EOB' >&2
ssrt - version: 2020.06.21.0
updated: 2020-06-21 by budRich
EOB
}


# environment variables
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${SSR_CONFIG_DIR:=$HOME/.ssr}"
: "${SSRT_INPUT_FILE:=/tmp/ssrt/in}"


main() {

  declare -ri _ssrpid _dunstid=1338
  declare -r  _confdir=${__o[config-dir]:-$SSR_CONFIG_DIR}
  declare -r  _ssrcnf="$_confdir"/settings.conf
  declare -r  _ssrsts="$_confdir"/stats
  declare -r  _infile=${__[input-file]:-$SSRT_INPUTFILE}

  _ssrpid=$(pidof simplescreenrecorder)

  if ((__o[pause])); then
    play-toggle
  elif ((_ssrpid)); then
    stop
  else
    launch
  fi

}

___printhelp(){
  
cat << 'EOB' >&2
ssrt - SHORT DESCRIPTION


SYNOPSIS
--------
ssrt [--pause|-p] [--delay|-d SECONDS] [--select|-s] [--config-dir|-c DIR] [--input-file|-i FILE]
ssrt --help|-h
ssrt --version|-v

OPTIONS
-------

--pause|-p  

--delay|-d SECONDS  

--select|-s  

--config-dir|-c DIR  

--input-file|-i FILE  

--help|-h  
Show help and exit.


--version|-v  
Show version and exit.
EOB
}


area() {
  local re mode=$1
  local am # active monitor (1920/520x1080/290+0+0)
  local frm='%w/000x%h/000+%x+%y'

  if [[ $mode = fixed ]]; then
    am=$(slop --format "$frm")
  else
    mode=screen
    am=$(xrandr --listactivemonitors | awk '/[*]/ {print $3}')
  fi

  re='^([^/]+)/.+x([^/]+)/[^-+]+([-+][^-+]+)([-+][^-+]+)'

  [[ $am =~ $re ]] && {
    w=${BASH_REMATCH[1]}
    h=${BASH_REMATCH[2]}
    x=${BASH_REMATCH[3]}
    y=${BASH_REMATCH[4]}
  }

  t=$(mktemp)

  awk -F= '
    $1 == "video_area" {sub($2,mode)}
    $1 == "video_h"    {sub($2,h)}
    $1 == "video_w"    {sub($2,w)}
    $1 == "video_x"    {sub($2,x)}
    $1 == "video_y"    {sub($2,y)}
    {print}
  ' w="$w" h="$h" x="$x" y="$y" mode="$mode" "$_ssrcnf" > "$t"

  mv -f "$t" "$_ssrcnf"
}

createconf() {
local trgdir="$1"
declare -a aconfdirs

aconfdirs=(
"$trgdir/events"
)

mkdir -p "$1" "${aconfdirs[@]}"

cat << 'EOCONF' > "$trgdir/events/stop"

opf=$SSR_OUTPUTFILE
notify-send "i stopped $opf"

EOCONF

chmod +x "$trgdir/events/stop"
cat << 'EOCONF' > "$trgdir/events/resume"

echo i resumed
EOCONF

chmod +x "$trgdir/events/resume"
cat << 'EOCONF' > "$trgdir/events/start"

notify-send "im starting"
EOCONF

chmod +x "$trgdir/events/start"
cat << 'EOCONF' > "$trgdir/events/pause"

echo i paused
EOCONF

chmod +x "$trgdir/events/pause"
}

set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

ERX() { >&2 echo "$*" && exit 77 ;}
ERM() { >&2 echo "$*" ;}

event() {
  local opf
  local trg="$_confdir/events/$1"

  opf=$(getoutputpath)

  [[ -x $trg ]] && (
    SSR_OUTPUTFILE="${opf:-}"          \
    PATH="$_confdir/events/lib:$PATH"  \
    exec "$trg"
  )
}

getlaststate() {
  [[ -f $_infile ]] \
    || ERX could not get state, no input-file

  tail -n 1 "$_infile"
}

getoutputpath() {

  # in config (_ssrcnf) get directory
  # file=/home/bud/ssrop.mkv
  # in stats file (_ssrsts) get filename
  # file_name  ssrop-2020-06-16_19.24.43.mkv
  
  [[ -f $_ssrsts ]] && awk '

    /^file=/ { gsub(/^file=|[^/]+$/,"")    ; dir=$0 }
    /^file_name/ { gsub(/^file_name\s+/,""); fil=$0 }

    END { print dir fil }

  ' "$_ssrcnf" "$_ssrsts"
}

ifcmd() { command -v "$1" > /dev/null ;}

launch() {

  declare -i del=${__o[delay]}
  echo record-start > "$_infile"

  area "${__o[select]:+fixed}"

  {
    ((del)) && {
      if ifcmd dunstify ; then
        while ((del--)); do
          dunstify -r "$_dunstid" "recording starts in $((del+1))"
          sleep 1
        done
        
        dunstify --close "$_dunstid"
      else
        notify-send --expire-time "$del" \
          "recording delayed $del seconds."
        sleep "${del}"
      fi
    }

    event start

    < <(tail -f "$_infile") \
    > /dev/null 2>&1        \
      simplescreenrecorder --start-hidden            \
                           --settingsfile="$_ssrcnf" \
                           --statsfile="$_ssrsts"
    rm -f "${_infile:?}"
  } &
}

msg() {
  mkdir -p "${_infile%/*}"
  echo "$*" >> "$_infile"
}

play-toggle() {
  local state

  # if ssr is not running execute the script again
  # without -p option to toggle launch
  ((_ssrpid)) || exec "$0"
  state=$(getlaststate)

  if [[ $state = record-start ]]; then
    msg record-pause
    event pause
  else
    msg record-start
    event resume
  fi

}

stop() {

  if [[ $(getlaststate) = record-start ]]; then
    msg record-save
    event stop
    msg quit
  else
    play-toggle
  fi
  
}

declare -A __o
options="$(
  getopt --name "[ERROR]:ssrt" \
    --options "pd:sc:i:hv" \
    --longoptions "pause,delay:,select,config-dir:,input-file:,help,version," \
    -- "$@" || exit 77
)"

eval set -- "$options"
unset options

while true; do
  case "$1" in
    --pause      | -p ) __o[pause]=1 ;; 
    --delay      | -d ) __o[delay]="${2:-}" ; shift ;;
    --select     | -s ) __o[select]=1 ;; 
    --config-dir | -c ) __o[config-dir]="${2:-}" ; shift ;;
    --input-file | -i ) __o[input-file]="${2:-}" ; shift ;;
    --help       | -h ) ___printhelp && exit ;;
    --version    | -v ) ___printversion && exit ;;
    -- ) shift ; break ;;
    *  ) break ;;
  esac
  shift
done

[[ ${__lastarg:="${!#:-}"} =~ ^--$|${0}$ ]] \
  && __lastarg="" 


main "${@:-}"


