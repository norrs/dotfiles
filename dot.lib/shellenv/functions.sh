
function get_cols() {
    FS=' '
    OPTIND=1
    while getopts "F:" OPTCHAR; do
        case $OPTCHAR in
            F)
                FS=$OPTARG
                ;;
        esac
    done
    shift $((OPTIND-1))
    gawk -f "$HOME/.lib/get_cols.awk" -v "cols=$*" -v "FS=$FS"
}

function filter_by_column_value {
    awk '$'"$1"' == '"$2"'  { print $0 }'
}

function prometheus_rules_validate {
   docker run --volume "$1:$1" --workdir="$1" --entrypoint /bin/sh prom/prometheus:latest -c 'find . -iname "*.rules" | xargs /bin/promtool check rules'
}

function kwatchdiff {
 kind="$1"
 name="$2"
 kubectl get -w -o json "$kind" "$name" \
  | jq -c --unbuffered . \
  | bash -c ' \
    PREV="{}"; \
    while read -r NEXT; do \
      diff -u <(echo -E "$PREV" | jq .) <(echo -E "$NEXT" | jq .); \
      PREV=$NEXT; \
      echo; done' \
  | colordiff
}

deeplink() {
    adb shell am start -a "android.intent.action.VIEW" -d "$@"
}

jdk8() {
  export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
}

outlookmsgtoeml() {
  # apt-get install libemail-outlook-message-perl libemail-sender-perl	
  perl -we 'use Email::Outlook::Message; print Email::Outlook::Message->new(shift)->to_email_mime->as_string' "$1" > "${1%.msg}.eml"
}
