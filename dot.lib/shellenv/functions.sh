
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

adb-zid() {
    adb exec-out run-as net.zedge.android cat /data/data/net.zedge.android/shared_prefs/net.zedge.android_preferences.xml | grep 'ZID' | awk -F">" '{print $2}' | awk -F"<" '{print $1}'
}

deeplink() {
    adb shell am start -a "android.intent.action.VIEW" -d "$@"
}

adb-zprefs() {
    APP_ID="net.zedge.android"
    adb exec-out run-as ${APP_ID} cat /data/data/${APP_ID}/shared_prefs/${APP_ID}_preferences.xml
}

adb-zprefs-edit() {
    APP_ID="net.zedge.android"
    adb exec-out run-as "${APP_ID}" cat "/data/data/${APP_ID}/shared_prefs/${APP_ID}_preferences.xml" > /tmp/prefs_${APP_ID}
    editor /tmp/prefs_${APP_ID} &&
    adb push /tmp/prefs_${APP_ID} /sdcard/temp_prefs_${APP_ID}.xml &&
    adb shell run-as ${APP_ID} "cp /sdcard/temp_prefs_${APP_ID}.xml /data/data/${APP_ID}/shared_prefs/${APP_ID}_preferences.xml" &&
    adb shell rm /sdcard/temp_prefs_${APP_ID}.xml
}

adb-zprefs-config() {
    APP_ID="net.zedge.android"
    adb exec-out run-as ${APP_ID} cat /data/data/${APP_ID}/shared_prefs/zedge_configuration_loader.xml
}

jdk8() {
  export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
}
