alias grantStorage='echo Granting storage permission for net.zedge.android; adb shell pm grant net.zedge.android android.permission.WRITE_EXTERNAL_STORAGE; adb shell pm grant net.zedge.android android.permission.READ_EXTERNAL_STORAGE'
alias revokeStorage='echo Revoking storage permission for net.zedge.android; adb shell pm revoke net.zedge.android android.permission.WRITE_EXTERNAL_STORAGE; adb shell pm revoke net.zedge.android android.permission.READ_EXTERNAL_STORAGE'
alias grantContacts='echo Granting contacts permission for net.zedge.android; adb shell pm grant net.zedge.android android.permission.WRITE_CONTACTS; adb shell pm grant net.zedge.android android.permission.READ_CONTACTS'
alias revokeContacts='echo Revoking contacts permission for net.zedge.android; adb shell pm revoke net.zedge.android android.permission.WRITE_CONTACTS; adb shell pm revoke net.zedge.android android.permission.READ_CONTACTS'
alias resetPermissions='echo Resetting permissions for net.zedge.android; adb shell pm reset-permissions net.zedge.android'

