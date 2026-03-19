#!/bin/bash

# Check if a parameter is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

APP_NAME=$1
curl -sL https://github.com/Bhacaz/rails_template_app/archive/main.tar.gz | tar xz
mv rails_template_app-main $APP_NAME
cd $APP_NAME
rbenv local $(cat .ruby-version)
bundle install
bin/rails generate rename $APP_NAME
git init && git add . && git commit -m "Initial commit"
bin/setup
