#!/bin/bash 
#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37
# requires:
# inotifywait, sass, dub (and dmd), ufligy-js2
# ubuntu packages:
# inotify-utils
# sudo apt install npm
# npm install uglify-js -g
# OR
# sudo apt install node-uglify

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
LB='\033[0;34m'
BROWN='\033[0;33m'
NC='\033[0m' # No Color
SOURCE="source"
VIEWS="views"

APPLICATION="newtest"

PUBLIC_SASS_SRC="source/jass/public.sass"
PUBLIC_JS_SRC="source/jass/public.js"
PUBLIC_CSS="public/public.css"
PUBLIC_JS="public/public.js"

PRVT_SASS_SRC="source/jass/private.sass"
PRVT_JS_SRC="source/jass/private.js"
PRVT_CSS="private/private.css"
PRVT_JS="private/private.js"

function block_for_change {
  inotifywait -rq \
    -e modify,move,create,delete,close_write \
    $SOURCE $VIEWS $APPLICATION
}

task_info=("")
# brought this into code so that I can see if a compile is failing to be caught
#initialize () {
	#printf "${CYAN} IN ${task_info[0]} ${task_info[1]} ${task_info[2]}${NC}\n"
#}

while true; do
	printf "\n${GREEN}===== waiting for next task =====${NC}\n\n"
	task_string=$(block_for_change)
	IFS=' ' read -r -a task_info <<< "$task_string"
	info_path=${task_info[0]}
	info_action=${task_info[1]}
	info_file=${task_info[2]}

	printf "${CYAN} IN ${task_info[0]} ${task_info[1]} ${task_info[2]}${NC}\n"

	if [[ ${task_info[0]} = "source"* && ${task_info[2]} = *".d" ]] || \
		 [[ ${task_info[0]} = "views"* && ${task_info[2]} = *".dt" ]] ; then
		printf "${LB} source/views change${NC}\n"
		printf "${LB} running $ dub build${NC}\n"
		killall $APPLICATION
		dub run &
		printf "${BROWN} $APPLICATION recompiled ${NC}\n"
	fi

	if [[ ${task_info[2]} = "public.sass" ]] ; then
		printf "${LB} public.sass change${NC}\n"
		sass -v --cache-location /tmp/.sass-cache \
		  --style expanded \
			--update $PUBLIC_SASS_SRC:$PUBLIC_CSS &
		printf "${BROWN} public.sass recompiled ${NC}\n"
	fi
	if [[ ${task_info[2]} = "private.sass" ]] ; then
		printf "${LB} private.sass change${NC}\n"
		sass -v --cache-location /tmp/.sass-cache \
		  --style expanded \
			--update $PRVT_SASS_SRC:$PRVT_CSS &
		printf "${BROWN} private.sass recompiled ${NC}\n"
	fi

	if [[ ${task_info[2]} = "public.js" ]] ; then
		printf "${LB} public.js change${NC}\n"
		uglifyjs -v \
			--beautify \
			--lint \
			-o $PUBLIC_JS \
			$PUBLIC_JS_SRC &
		printf "${BROWN} public.js recompiled ${NC}\n"
	fi
	if [[ ${task_info[2]} = "private.js" ]] ; then
		printf "${LB} private.js change${NC}\n"
		uglifyjs -v \
			--beautify \
			--lint \
			-o $PRVT_JS \
			$PRVT_JS_SRC &
		printf "${BROWN} private.js recompiled ${NC}\n"
	fi

done
