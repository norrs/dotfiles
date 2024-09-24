
jwtparse() {
  jq -R 'gsub("-";"+") | gsub("_";"/") | split(".") | .[1] | @base64d | fromjson'
}

# extract header and payload
jwtparse_all() {
  jq -R 'gsub("-";"+") | gsub("_";"/") | split(".") |  select(length > 0) | .[0],.[1] | @base64d | fromjson'
}

# extract signature
jwtparse_signature() {
  jq -R 'gsub("-";"+") | gsub("_";"/") | split(".") |  select(length > 0) | .[2]' -r
}

