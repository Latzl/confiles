Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$msg = if ($args[0]) { $args[0] } else { 'Claude Code needs your attention' }

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);
}
"@

[IntPtr]$hwnd = [Win32]::GetForegroundWindow()
$sb = New-Object System.Text.StringBuilder 256
[Win32]::GetClassName($hwnd, $sb, 256) | Out-Null
$className = $sb.ToString().ToLower()

if ($className -match 'cascadia|windowsterminal|conhost') { exit 0 }

$icon = [System.Drawing.SystemIcons]::Information
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $icon
$notify.Visible = $true
$notify.ShowBalloonTip(5000, 'Claude Code', $msg, 'Info')
Start-Sleep 6
$notify.Dispose()
