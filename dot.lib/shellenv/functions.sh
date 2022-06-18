
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

# Simple calculator
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions#L1-L17
calc() {
        local result=""
        result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
        #                       └─ default (when `--mathlib` is used) is 20
        #
        if [[ "$result" == *.* ]]; then
                # improve the output for decimal numbers
                printf "$result" |
                sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
                    -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
                    -e 's/0*$//;s/\.$//'   # remove trailing zeros
        else
                printf "$result"
        fi
        printf "\n"
}

# Create a new directory and enter it
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions
md() {
	mkdir -p "$@" && cd "$@"
}

# Create a data URL from a file
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions
dataurl() {
        local mimeType=$(file -b --mime-type "$1")
        if [[ $mimeType == text/* ]]; then
                mimeType="${mimeType};charset=utf-8"
        fi
        echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# All the dig info
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions
digga() {
	dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions
escape() {
	printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
	echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
# Credits: https://github.com/addyosmani/dotfiles/blob/master/.functions
unidecode() {
	perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
	echo # newline
}
