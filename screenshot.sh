#!/bin/bash
# Jack Dwyer 2017
# Feb 2017 - Adding b2 support, debug switch, ignore upload switch

CONFIG_LOCATION="${HOME}/.config/s3-screenshot.conf"
ALL_DISPLAYS=false
DEBUG=1
LOAD_IMAGES_IN_CHROME=false
UPLOAD=0
DATE=$(date -R)

log() { 
  echo "[${1}] ${2}"
}

log_debug() { 
  log "DEBUG" "${1}"
}

log_error() { 
  log "ERROR" "${1}"
}

log_info() { 
  log "INFO" "${1}"
}

check_ret() {
  if [[ $1 -ne 0 ]]; then
    log_error "$2"
    exit 10
  fi
}

generate_name() {
  echo "aut"
  echo $(cat /dev/urandom | tr -d -c [:alnum:] | head -c 15)
}

# Load config, or doesn't exist expect environment variables to be set
if [[ ! -f ${CONFIG_LOCATION} ]]; then
  log_info "No configuration at ${CONFIG_LOCATION}, skipping upload"
  UPLOAD=1
else
  # shellcheck source=/dev/null
  source "${CONFIG_LOCATION}"
fi

check_deps () {
  dependencies=('curl' 'openssl' 'scrot' 'xclip' 'file')
  for dependency in "${dependencies[@]}"; do
    if [[ $(command -v "${dependency}" > /dev/null; echo $?) -ne 0 ]]; then
      log_error "Missing dependency: ${dependency}"
      exit 2
    fi
  done
}

mime_type() {
  file --mime-type "${1}" | cut -d" " -f2
}

sha1_file() {
  openssl dgst -sha1 "${1}" | awk '{print $2}'
}

B2_AUTH_ACCOUNT_URL=https://api.backblazeb2.com/b2api/v1/b2_authorize_account
B2_GET_UPLOAD_URL=https://api001.backblazeb2.com/b2api/v1/b2_get_upload_url

upload_b2() {
  FILE=${1}
  AUTH_TOKEN=$(curl -s -u "${B2_ACCOUNT_ID}:${B2_APPLICATION_KEY}" \
               ${B2_AUTH_ACCOUNT_URL} | jq -r .authorizationToken)
  resp=$(curl -s -H "Authorization: ${AUTH_TOKEN}" \
              -d '{"bucketId": "'${B2_BUCKET_ID}'"}' \
              ${B2_GET_UPLOAD_URL} | jq -r .uploadUrl,.authorizationToken)
  UPLOAD_URL=$(echo ${resp} | awk '{print $1}')
  UPLOAD_AUTH=$(echo ${resp} | awk '{print $2}')

  curl -H "Authorization: ${UPLOAD_AUTH}" \
       -H "X-Bz-File-name: $(basename ${FILE})" \
       -H "Content-Type: $(mime_type ${FILE})" \
       -H "X-Bz-Content-sha1: $(sha1_file ${FILE})" \
       --data-binary @"${FILE}" \
       -s -o/dev/null \
       ${UPLOAD_URL}

  echo "${B2_BASE_FILE_URL}/$(basename ${FILE})" | xclip -selection clipboard
}

upload_aws() {
  local content_type
  local file
  local image_url
  local sign_me
  local sig
 
  file=${1}
  content_type="mimetype()"
  sign_me="PUT\n\n${content_type}\n$DATE\n/$BUCKET/$(basename "${file}")"
  sig=$(echo -en "${sign_me}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64)
  echo "uploading..."
  curl -X PUT -T "${file}" --insecure \
    -H "Host: ${BUCKET}.s3.amazonaws.com" \
    -H "Date: $DATE" \
    -H "Content-Type: ${content_type}" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${sig}" \
    https://"${BUCKET}".s3.amazonaws.com/"$(basename "${file}")"

  echo "http://${BUCKET}/$(basename "${file}")" | xclip -selection clipboard
}

upload () {
  if [[ "${UPLOAD}" -ne 0 ]]; then
    log_info "Upload disabled"
    return
  fi
  file="$1"
  log_info "Uploading ..."

  upload_b2 ${file}
  # upload_aws ${file}
  # echo "${image_url}"
  # echo "${image_url}" | xclip -selection clipboard

  # if [[ $LOAD_IMAGES_IN_CHROME = true ]]; then
  #   google-chrome "${image_url}"
  # fi
}

upload_file() {
  upload "$1"
}

screenshot () {
  local image
  local retval
  ran=$(cat /dev/urandom | tr -d -c 'a-zA-Z0-9' | head -c 35)
  image=$HOME/Pictures/${ran}.png

  if [[ "$ALL_DISPLAYS" = true ]]; then
    retval=$(scrot "${image}"; echo $?)
    check_ret "${retval}" "Screenshot failed"
  else
    echo "Select area for screenshot"
    retval=$(scrot -s "${image}"; echo $?)
    check_ret "${retval}" "Screenshot failed"
  fi
  if [[ ${DEBUG} -eq 0 ]]; then
    log_debug "Image path: ${image}"
  fi
  upload "${image}"
}

show_help () {
  echo "Usage: $(basename "$0") [OPTION]"
  echo "  [-a]            screenshot all displays"
  echo "  [-d]            enable debug"
  echo "  [-f FILE]       upload FILE"
  echo "  [-h]            show help"
  echo "  [-i]            do not upload"
}

check_deps

while getopts ":f:adhi" opt; do
  case $opt in
    a)
      ALL_DISPLAYS=true
      ;;
    d)
      DEBUG=0
      ;;
    f)
      upload_file "$OPTARG"
      ;;
    h)
      show_help
      exit 0
      ;;
    i)
      UPLOAD=1
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

screenshot
