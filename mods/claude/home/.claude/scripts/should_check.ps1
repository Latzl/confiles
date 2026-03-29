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
Write-Host "notify"
