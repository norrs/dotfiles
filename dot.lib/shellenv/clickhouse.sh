NUM_SHARDS=4
run_on_clickhouse_servers() {
    for i in $(seq 0 "$NUM_SHARDS"); do 
        kubectl exec -ti "clickhouse-clickhouse-$i" -- "$@"
    done
}

