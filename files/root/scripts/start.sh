#!/bin/sh

pid=$$

trap "stop_template" 2 15

log() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1"
}

error() {
  # ISO-8601
  echo "[$(date '+%FT%TZ')] [$0] $1" 1>&2
}

prepare_app() {
  if [ ! -f "/root/server/.installed" ]; then
    log "Server installation started"

    log "Unpacking server installer..."
    tar -xJf "/root/server-installer.tar.xz" -C "/tmp/"

    cd "/tmp/factorio/" || exit 1
    for file in $(find . | sed -r 's/^.{2}//g')
    do
      # File
      if [ -f "/tmp/factorio/$file" ]; then
        # Exists
        if [ -f "/root/server/$file" ]; then
          # Check hash
          if [ ! "$(sha1sum "/tmp/factorio/$file" | awk '{print $1}' )" = "$(sha1sum "/root/server/$file" | awk '{print $1}')" ]; then
            log "Copying /root/server/$file, hashes are not equal"
            cp "/tmp/factorio/$file" "$(echo "/root/server/$file" | sed -r "s/[A-Za-z0-9_\.\-]+$//g")"
          fi
        # Not exists
        else
          log "Copying /root/server/$file, file not exists"
          cp "/tmp/factorio/$file" "$(echo "/root/server/$file" | sed -r "s/[A-Za-z0-9_\.\-]+$//g")"
        fi

      # Directory
      elif [ -d "/tmp/factorio/$file" ]; then
        # Not exists
        if [ ! -d "/root/server/$file" ]; then
          log "Creating /root/server/$file, directory not exists"
          mkdir "/root/server/$file"
        fi
      fi
    done

    # Saves
    if [ ! -d "/root/server/saves" ]; then
      log "Creating /root/server/saves, directory not exists"
      mkdir /root/server/saves
    fi

    # Installed
    touch "/root/server/.installed"

    # Clean up
    log "Cleaning up server installer..."
    rm -rf "/tmp/factorio"
  
    log "Server installation success"
  else
    log "Server installation not required"
  fi

  # Create world if it is not created
	if [ ! -f "/root/server/saves/save.zip" ]; then
		log "World generation started..."
		/root/server/bin/x64/factorio --create /root/server/saves/save.zip || exit 1
    log "World generation success"
  else
    log "World generation not required"
  fi

  # Copy config if it is not mounted
	if [ ! -f "/root/server/data/server-settings.json" ]; then
		cp -v "/root/server/data/server-settings.example.json" "/root/server/data/server-settings.json"
  fi

	if [ ! -f "/root/server/data/server-adminlist.json" ]; then
		echo "[]" > "/root/server/data/server-adminlist.json"
  fi

  if [ ! -f "/root/server/data/server-banlist.json" ]; then
		echo "[]" > "/root/server/data/server-banlist.json"
  fi

  if [ ! -f "/root/server/data/server-whitelist.json" ]; then
		echo "[]" > "/root/server/data/server-whitelist.json"
  fi
}

start_app() {
  if [ $WHITELIST -eq 1 ]; then
    log "Starting with whitelist..."
    /root/server/bin/x64/factorio \
        --start-server /root/server/saves/save.zip \
        --server-settings /root/server/data/server-settings.json \
        --server-adminlist /root/server/data/server-adminlist.json \
        --server-banlist /root/server/data/server-banlist.json \
        --server-whitelist /root/server/data/server-whitelist.json \
        --use-server-whitelist &
  else
    log "Starting without whitelist..."
    /root/server/bin/x64/factorio \
        --start-server /root/server/saves/save.zip \
        --server-settings /root/server/data/server-settings.json \
        --server-adminlist /root/server/data/server-adminlist.json \
        --server-banlist /root/server/data/server-banlist.json &
  fi
}

stop_app() {
  :
}

### Don't touch ###

prepare_template() {
  log "Preparing..."
  prepare_date=$(date '+%s')
  
  prepare_app

  wait
  prepared_time=$(echo "$(date '+%s') - $prepare_date" | bc)
  log "Prepared in $prepared_time seconds"
  return 0
}

start_template() {
  log "Starting..."
  start_date=$(date '+%s')
  
  start_app

  pid=$!
  if [ $pid = -1 ]; then
    error "Can't start process"
    return 1
  else
    started_time=$(echo "$(date '+%s') - $start_date" | bc)
    log "Started in $started_time seconds"
    wait
    return 0
  fi
}

stop_template() {
  log "Stopping..."
  stop_date=$(date '+%s')

  stop_app

  if [ $pid = $$ ]; then
    return 0
  else
    log "Killing pid $pid"
    kill -15 $pid || error "Can't kill pid $pid"
    wait $pid
  fi
  stopped_time=$(echo "$(date '+%s') - $stop_date" | bc)
  log "Stopped in $stopped_time seconds"
  return 0
}

sleep_app() {
  error "Something went wrong"
  error "Sleeping 10 minutes..."
  sleep "10m"
  exit 1
}

if prepare_template; then
    start_template
else
    sleep_app
fi

log "Exited"
