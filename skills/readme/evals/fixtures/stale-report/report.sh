#!/bin/sh
# Lists files in the given folder not modified for N days (default 30), oldest first.
dir=${1:?folder}; days=${2:-30}
find "$dir" -type f -mtime +"$days" -exec ls -ltr {} + 2>/dev/null | awk '{print $6, $7, $9}'
