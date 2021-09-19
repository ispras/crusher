#!/bin/bash

# Этот скрипт скачивет Крашер.
# Первым аргументом указывается путь по которому надо скачать и разархивировать дистирбутив
# Вторым, опциональным можно указать желаемую версию крашера.

# В случае если по указанному пути уже обнаружится развернутый Крашер (как минимум Changelog.md от него)
# повторное скачивание производиться не будет.

DEST_PATH=$1

VERSION=$2

curl -V >/dev/null  # проверяем наличие curl
if [  $? -ne 0 ]; then
    echo curl is not found!!! Please install it! >&2
    exit 1
fi

if [ -n "$DEST_PATH" ] && [ -f "$DEST_PATH/crusher/Changelog.md" ];
then
    echo "Похоже крашер у нас уже есть. Еще раз не скачиваем"
    exit 0
fi

URL_BASE="https://nextcloud.ispras.ru/s/y4JQq7K5YXmfDSy/download"

LATEST_VERSION=`curl "$URL_BASE?path=%2FLinux&files=Changelog-Linux.md" 2>/dev/null | grep '## Версия' | head -n1 | sed 's/.*\[\(.*\)\].*/\1/'`


if [ -z "$1" ]
then
    echo "Cusher latest version: $LATEST_VERSION"
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

# Если нам не указали какую, то добываем последнюю версию
[ -z "$VERSION" ] && VERSION=$LATEST_VERSION

if [ $VERSION == $LATEST_VERSION ];
then
    run_and_log "wget '$URL_BASE?path=%2FLinux&files=crusher-linux-v$VERSION.tar.gz' -O $DEST_PATH/crusher-linux-v$VERSION.tar.gz"
else
    run_and_log "wget \"$URL_BASE?path=%2FLinux%2FOld%20releases%2F$VERSION&&files=crusher-linux-v$VERSION.tar.gz\" -O $DEST_PATH/crusher-linux-v$VERSION.tar.gz"
fi

run_and_log "tar -xvzf $DEST_PATH/crusher-linux-v$VERSION.tar.gz -C $DEST_PATH"
