
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
