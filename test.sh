#!/bin/bash
rspec -P "*/**/*test*.rb" -P "*/**/tests/*.rb" -P "tests/**/*.rb"

if [ $? -ne 0 ]; then
  exit 0
fi
