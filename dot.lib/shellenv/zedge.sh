alias grantStorage='echo Granting storage permission for net.zedge.android; adb shell pm grant net.zedge.android android.permission.WRITE_EXTERNAL_STORAGE; adb shell pm grant net.zedge.android android.permission.READ_EXTERNAL_STORAGE'
alias revokeStorage='echo Revoking storage permission for net.zedge.android; adb shell pm revoke net.zedge.android android.permission.WRITE_EXTERNAL_STORAGE; adb shell pm revoke net.zedge.android android.permission.READ_EXTERNAL_STORAGE'
alias grantContacts='echo Granting contacts permission for net.zedge.android; adb shell pm grant net.zedge.android android.permission.WRITE_CONTACTS; adb shell pm grant net.zedge.android android.permission.READ_CONTACTS'
alias revokeContacts='echo Revoking contacts permission for net.zedge.android; adb shell pm revoke net.zedge.android android.permission.WRITE_CONTACTS; adb shell pm revoke net.zedge.android android.permission.READ_CONTACTS'
alias resetPermissions='echo Resetting permissions for net.zedge.android; adb shell pm reset-permissions net.zedge.android'

zedge_events() {
	if ! clickhouse-client --port 9000 "$@"; then
		PORT_FORWARD_COMMAND='kubectl --context=env:analytics port-forward clickhousev2-clickhouse-2 9000:9000'
		PID=$(ps aux | grep "$PORT_FORWARD_COMMAND" | grep -v grep | awk '{print $2}' | xargs kill)
		if [ "$PID" != "" ]; then
			kill $PID
		fi
		$PORT_FORWARD_COMMAND 2>/dev/null &
		until clickhouse-client --port 9000 "$@"; do sleep 1; done
	fi
}
