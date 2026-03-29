Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$msg = if ($args[0]) { $args[0] } else { 'Claude Code needs your attention' }
$icon = [System.Drawing.SystemIcons]::Information
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $icon
$notify.Visible = $true
$notify.ShowBalloonTip(5000, 'Claude Code', $msg, 'Info')
Start-Sleep 5
$notify.Dispose()
