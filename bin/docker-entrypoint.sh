#!/bin/bash

# Attempt to remove the socket file directly
echo "Attempting to remove $file_path"

rm -rf ./tmp/sockets
mkdir ./tmp/sockets

echo "Starting Puma..."

if [ "$RAILS_ENV" == "production" ]; then
  echo "Precompiling assets..."
  bundle exec rake assets:precompile
fi

bundle exec puma -C config/puma.rb
