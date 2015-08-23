#!/bin/bash
# Jack Dwyer 2015


DIR="$(dirname "$(readlink -f "$0")")"

# Load config, or doesn't exist expect environment variables to be set
if [[ -f "$DIR"/config ]]; then
  . "$DIR"/config
fi

LOAD_IMAGES_IN_CHROME=false
ALL_DISPLAYS=false
DATE=$(date -R)

check_deps () {
  dependencies=('curl' 'openssl' 'scrot' 'xclip' 'file')
  for dependency in "${dependencies[@]}"; do
    if [[ $(command -v "${dependency}" > /dev/null; echo $?) -ne 0 ]]; then
      printf "ERROR: missing %s.  Please install, or add to PATH\n" "${dependency}"
      exit 2
    fi
  done
}

upload () {
  local file="$1"
  local content_type="$(file --mime-type "${file}" | cut -d" " -f2)"
  local sign_me="PUT\n\n${content_type}\n$DATE\n/$BUCKET/$(basename "${file}")"
  local sig=$(echo -en "${sign_me}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64)
  echo "uploading..."
  curl -X PUT -T "${file}" --insecure \
    -H "Host: ${BUCKET}.s3.amazonaws.com" \
    -H "Date: $DATE" \
    -H "Content-Type: ${content_type}" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${sig}" \
    https://${BUCKET}.s3.amazonaws.com/"$(basename "${file}")"

  local image_url="http://${BUCKET}/$(basename "${file}")"
  echo "${image_url}"
  echo "${image_url}" | xclip -selection clipboard

  if [[ $LOAD_IMAGES_IN_CHROME = true ]]; then
    google-chrome "${image_url}"
  fi
}

upload_file() {
  upload "$1"
}

check_ret() {
  if [[ $1 -ne 0 ]]; then
    echo "$2"
    exit 10
  fi
}

screenshot () {
  local image=$HOME/Pictures/$(date +"%Y_%m_%d-%H:%M:%S").png
  if [[ "$ALL_DISPLAYS" = true ]]; then
    local retval=$(scrot "${image}"; echo $?)
    check_ret "${retval}" "Screenshot failed"
    upload "${image}"
  else
    echo "Select area for screenshot"
    local retval=$(scrot -s "${image}"; echo $?)
    check_ret "${retval}" "Screenshot failed"
    upload "${image}"
  fi
}

show_help () {
  echo "Usage: $(basename "$0") [-f <file_to_upload>]"
  echo "                  [-a] screenshot all displays"
}

check_deps

if [[ $# -eq 0 ]]; then
  screenshot
  exit 0
fi

while getopts ":f:ah" opt; do
  case $opt in
    a)
      ALL_DISPLAYS=true
      screenshot
      exit 0
      ;;
   f)
      upload_file "$OPTARG"
      ;;
    h)
      show_help
      exit 0
      ;;
    \?)
      echo "invalid option : -$OPTARG"
      show_help
      exit 1
      ;;
    :)
      echo "-$OPTARG requires an argument." 
      show_help
      exit 1
      ;;
  esac
done
