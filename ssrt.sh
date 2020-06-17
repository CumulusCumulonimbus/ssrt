#!/bin/bash

main() {
  
  ssrpid=$(pidof simplescreenrecorder)

  if ((clop)); then
    play-toggle
  elif ((ssrpid)); then
    stop
  else
    start
  fi

}



ERX() { >&2 echo "$*" && exit 1 ;}
ERM() { >&2 echo "$*" ;}

getlaststate() {

  [[ -f $infile ]] \
    || ERX could not send command, no infile

  tail -n 1 "$infile"

}

getoutputpath() {

  # in config find directory
  # file=/home/bud/ssrop.mkv

  # in stats file
  # file_name         ssrop-2020-06-16_19.24.43.mkv
  awk '

    /^file=/ { gsub(/^file=|[^/]+$/,"")    ; dir=$0 }
    /^file_name/ { gsub(/^file_name\s+/,""); fil=$0 }

    END { print dir fil }

  ' "$ssrcnf" "$ssrsts"
}

play-toggle() {
  local state m
  ERM play/pause

  ((ssrpid)) || ERX ssr is not running
  state=$(getlaststate)

  [[ $state = record-start ]] \
    && m=record-pause || m=record-start

  msg "$m"

}

menu() {

  local m o prompt OPTARG OPTIND
  
  for m in "${menus[@]}"; do
    command -v "$m" > /dev/null && break
    unset m
  done

  while getopts :p:f: o; do
    [[ $o = p ]] && prompt=$OPTARG
    [[ $o = f ]] && filter=$OPTARG
  done ; shift $((OPTIND-1))

  case "$m" in
    dmenu  ) "$m" -p "$prompt" ;;
    rofi   ) "$m" -dmenu -p "$prompt" -filter "$filter" ;;
    i3menu ) "$m" -p "$prompt" -f "$filter" ;;
    *      ) ERX cannot find menu command ;;
  esac < <(printf "%s${1:+\n}" "${@}")
}

msg() {
  mkdir -p "${infile%/*}"
  echo "$*" >> "$infile"
}

preview() {
  local f=$1

  eval "$previewcommand '$f'" > /dev/null 2>&1

  menu -p "Save file? " Yes No Maybe New
}

save() {
  local f=$1
  declare -i validpath

  until ((validpath)); do

    path=$(menu -p "Save as: " -f "${savedir/~/'~'}")
    path=${path/'~'/~}

    [[ -z $path ]] && {
      confirm=$(menu -p "Delete $f ? " No Yes)
      [[ $confirm = Yes ]] && return
    }

    [[ ${path} =~ ^/ ]] && validpath=1
  done

  [[ -d $path ]] && path+=/$defaultname

  [[ $path =~ .+[^/]+([.].+)$ ]] && path=${path%.*}
  mkdir -p "${path%/*}"

  mv "$f" "$path"."${f##*.}"
}

start() {

  ERM start

  msg record-pause

  { 

    ((clod)) && {
      if command -v dunstify >/dev/null ; then
        while ((clod--)); do
          dunstify -r "$dunstid" "recording starts in $((clod+1))"
          sleep 1
        done
        
        dunstify --close "$dunstid"
      else
        sleep "$clod"
      fi
    }
    
    

    < <(tail -f "$infile") \
    > /dev/null 2>&1       \
      simplescreenrecorder --start-hidden           \
                           --settingsfile="$ssrcnf" \
                           --statsfile="$ssrsts"
    rm -f "${infile:?}"
  } &
}

stop() {

  local state opf choice

  ERM stop

  state=$(getlaststate)

  if [[ $state = record-start ]]; then
    msg record-save

    opf=$(getoutputpath)

    [[ -f $opf ]] || ERX could not find output file "$opf"
    command -v "$previewcommand" >/dev/null || choice=Yes

    while [[ ${choice:=Maybe} = Maybe ]]; do
      choice=$(preview "$opf")
    done

    [[ $choice = Yes ]] && save "$opf"
    
    rm -f "$opf"
    [[ $choice = New ]] && exec "$0" 

    msg quit
  else
    play-toggle
  fi
}

declare -i ssrpid clop clod dunstid=1338

declare -r infile=/tmp/ssrt/in
declare -r ssrcnf=~/.ssr/settings.conf
declare -r ssrsts=~/.ssr/stats
declare -r previewcommand=mpv

declare defaultname

defaultname=$(date +%y%m%d%-H:%M:%S)

declare savedir

[[ -z $savedir ]] && {
  savedir=~
  command -v xdg-user-dir >/dev/null \
    && savedir=$(xdg-user-dir VIDEOS)
}

menus=(i3menu dmenu rofi)

while getopts :pd: o; do
  case "$o" in
    p ) clop=1 ;;
    d ) clod=$OPTARG ;;
    * ) ERX incorrect option abort ;;
  esac
done ; shift $((OPTIND-1))

main "$@"
