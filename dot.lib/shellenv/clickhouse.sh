NUM_SHARDS=4
run_on_clickhouse_servers() {
    for i in $(seq 0 "$NUM_SHARDS"); do 
        kubectl exec -ti "clickhouse-clickhouse-$i" -- "$@"
    done
}

clickhouse_portforward() {
 (set -x; kubectl port-forward clickhouse-clickhouse-0 9000)
}



clickhouse_portforward_prod() {
 (set -x; kubectl --context env:analytics port-forward clickhouse-clickhouse-0 9000)
}

run_on_clickhouse_server() {
 local shard="$1"
 test "$shard" -ge 0 || { >&2 echo "ERR: Only have clickhouse shards from 0 to $NUM_SHARDS"; return -1; }
 test "$shard" -le "$NUM_SHARDS" || { >&2 echo "ERR: Only have clickhouse shards from 0 to $NUM_SHARDS"; return -1; }
 shift
 kubectl exec -ti "clickhouse-clickhouse-$shard" -- "$@"
}
