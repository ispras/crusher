#!/bin/bash

# Этот скрипт скачивает Крашер.
# В качестве аргумента указывается путь, по которому надо скачать и разархивировать дистрибутив.

# В случае, если по указанному пути уже обнаружится развернутый Крашер (как минимум Changelog.md от него),
# повторное скачивание производиться не будет.

DEST_PATH=$1

curl -V >/dev/null  # проверяем наличие curl
if [  $? -ne 0 ]; then
    echo curl is not found!!! Please install it! >&2
    exit 1
fi

if [ -n "$DEST_PATH" ] && [ -f "$DEST_PATH/crusher/Changelog.md" ];
then
    echo "Похоже Крашер у нас уже есть. Еще раз не скачиваем"
    exit 0
fi

URL_BASE="https://nextcloud.ispras.ru/index.php/s/xrtSXt8rMydRiFf/download"

VERSION=`curl "$URL_BASE?path=%2FLinux&files=Changelog-Linux.md" 2>/dev/null | grep '## Версия' | head -n1 | sed 's/.*\[\(.*\)\].*/\1/'`


if [ -z "$1" ]
then
    echo "Crusher latest version: $VERSION"
    echo "Please set download path as first arg to get it"
    exit
fi

if [[ -v CBSES_LOG_COMMANDS ]]; then
  rm -f $CBSES_LOG_COMMANDS
fi

run_and_log(){
  local command="$1"
  echo $command
  if [[ -v CBSES_LOG_COMMANDS ]]; then
    echo "$command" >> $CBSES_LOG_COMMANDS
  fi
  eval $command
}

run_and_log "wget '$URL_BASE?path=%2FLinux&files=crusher-linux-v$VERSION.tar.gz' -O $DEST_PATH/crusher-linux-v$VERSION.tar.gz"

run_and_log "tar -xvzf $DEST_PATH/crusher-linux-v$VERSION.tar.gz -C $DEST_PATH"
