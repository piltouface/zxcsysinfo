if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run as Administrator!" -ForegroundColor Red
    exit
}

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class ConsoleHelper {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] public static extern uint QueryDosDevice(string dev, StringBuilder buf, int max);
    [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
    [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
}
"@ -ErrorAction SilentlyContinue
try {
    $zxc1 = [ConsoleHelper]::GetStdHandle(-11)
    $zxc2 = 0
    [ConsoleHelper]::GetConsoleMode($zxc1, [ref]$zxc2) | Out-Null
    [ConsoleHelper]::SetConsoleMode($zxc1, $zxc2 -bor 4) | Out-Null
} catch {}
$zxcpizda  = [char]27 + "[38;2;255;182;193m"
$yiupy = [char]27 + "[0m"
function Write-Pink { param([string]$sweety); Write-Host "${zxcpizda}${sweety}${yiupy}" }

$zxc4 = @(); $zxc5 = @(); $zxc6 = @()
$zxc7 = $false; $zxc8 = @(); $zxc9 = @()

function Get-MC {
    $zxc10 = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $zxc10) { $zxc10 = Get-Process java -ErrorAction SilentlyContinue }
    if ($zxc10 -is [array]) { $zxc10 = $zxc10 | Sort-Object StartTime | Select-Object -First 1 }
    return $zxc10
}
$zxc11 = Get-MC
$zxc12 = "$env:APPDATA\.minecraft\mods"

Write-Pink "Y-sysinfo"
Write-Host ""

$zxc13 = 'vape|liquid.?bounce|meteor.?client|wurst|aristois|novoline|astolfo|tenacity|doomsday|whiteout|pandaware|bleach.?hack|thunder.?hack|konas|phobos|rusher.?hack|kill.?aura|aim.?assist|auto.?click|trigger.?bot|(?<!anti[-_ ]?)cheat(?!sheet)|hack(?!athon)|injector|spoof|hwid|ghost.?client|myau|opai|slinky|rise.?client|entropy|drip.?client|exhibition|azura|click.?gui|raven.?b|dream.?client|sigma.?client|impact.?client|future.?client|nursultan|wexside|akrien|deadcode|catlean|minced'
$zxc14 = 'anydesk|teamviewer|rustdesk|parsec|ammyy|supremo|ultraviewer|tightvnc|tvnserver|winvnc|realvnc|vncviewer|radmin|splashtop|screenconnect|chromeremotedesktop|remoting_host|aeroadmin|rdpwrap'
$zxc15 = 'cheatengine|cheat engine|processhacker|systeminformer|x64dbg|x32dbg|ollydbg|windbg|wireshark|fiddler|dnspy|ilspy|ghidra|idaq|ida64|reshacker|hxd|injector|kdmapper|ksdumper|autohotkey|autoit3|jnativehook|procmon|procexp|apimonitor|scylla|megadumper|de4dot|recaf|bytecodeviewer|jd-gui|luyten'
$zxc16 = 'vmware|vmtoolsd|vboxservice|vboxtray|virtualbox|qemu|vmms|vmcompute|windowssandbox|wsb'
$zxc17 = '^(?:iqvw64e|capcom|gdrv|rtcore64|rtcore32|asrdrv|dbutil|cpuz|winring0|phymem|kprocesshacker|processhacker|ksysteminformer|systeminformer|mhyprot|kdmapper|speedfan|asio|atszio|nvflash|bsmem|gmer|dbk64|dbk32|inpoutx64|physmem)'
$zxc18 = Join-Path ([Environment]::GetFolderPath('Desktop')) 'papa'
$zxc19 = (Get-Date).ToString('yyyyMMdd_HHmmss')
function Redact { param([string]$zxc20); $zxc20 -replace '(--accessToken|--session|--xuid|--clientId)\s+\S+', '$1 <redacted>' }
function Get-Sig { param([string]$zxc10); try { (Get-AuthenticodeSignature -LiteralPath $zxc10 -ErrorAction Stop).Status.ToString() } catch { 'Error' } }

$zxc21 = Get-Date
$zxc22 = (Get-Process -Id $PID).StartTime.AddSeconds(-10)
$zxc23 = Join-Path $env:TEMP ("y_evprobe_" + [guid]::NewGuid().ToString("N") + ".txt")
$zxc24 = Start-Process -FilePath "$env:SystemRoot\System32\wevtutil.exe" -ArgumentList @('qe','System','/c:1','/rd:true','/f:text') -WindowStyle Hidden -PassThru -RedirectStandardOutput $zxc23
$zxc25 = -not $zxc24.WaitForExit(10000)
if ($zxc25) { try { $zxc24.Kill() } catch {} }
Remove-Item -LiteralPath $zxc23 -Force -ErrorAction SilentlyContinue
function Get-WinEvent {
    if ($zxc25) { return }
    Microsoft.PowerShell.Diagnostics\Get-WinEvent @args
}
function Get-CimInstance {
    if ($zxc25 -and "$args" -match 'Win32_Service') { return }
    CimCmdlets\Get-CimInstance @args
}
$zxc26 = [bool]$env:Y_NOSFC
$zxc27 = Get-Date
$zxc28 = $null
if (-not $zxc26) {
    Write-Host "Starting sfc /scannow in background" -ForegroundColor Gray
    $zxc28 = Start-Job -ScriptBlock { & "$env:SystemRoot\System32\sfc.exe" /scannow | Out-Null }
}

try {
    $zxc29 = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $zxc30 = (Get-Date) - $zxc29
    Write-Pink "SYSTEM BOOT TIME"
    Write-Host ("  Last Boot : {0}" -f $zxc29.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    Write-Host ("  Uptime    : {0}d {1:D2}:{2:D2}:{3:D2}" -f $zxc30.Days, $zxc30.Hours, $zxc30.Minutes, $zxc30.Seconds) -ForegroundColor White
} catch { Write-Host "  Unable to retrieve boot time" -ForegroundColor Red }
if ($zxc11) {
    $zxc31 = (Get-Date) - $zxc11.StartTime
    Write-Host ("  MC Start  : {0}" -f $zxc11.StartTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    Write-Host ("  MC Uptime : {0}d {1:D2}:{2:D2}:{3:D2}" -f $zxc31.Days, $zxc31.Hours, $zxc31.Minutes, $zxc31.Seconds) -ForegroundColor White
} else { Write-Host "  MC        : not running" -ForegroundColor Gray }

Write-Pink "`nWINDOWS INSTALLATION"
try {
    $zxc32 = Get-CimInstance Win32_OperatingSystem
    $zxc33 = $zxc32.InstallDate
    $zxc34 = ((Get-Date) - $zxc33).TotalDays
    Write-Host ("  Install Date : {0}" -f $zxc33.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor $(if ($zxc34 -lt 14) { "Red" } else { "White" })
    if ($zxc34 -lt 14) { $zxc6 += "Windows installed {0:N0} days ago" -f $zxc34 }
    Write-Host ("  OS Version   : {0}" -f $zxc32.Caption) -ForegroundColor White
    Write-Host ("  Build        : {0}" -f $zxc32.BuildNumber) -ForegroundColor White
    $zxc35 = ([TimeZoneInfo]::Local.GetUtcOffset([datetime]::Now)).TotalHours - 3
    $zxc36 = if ($zxc35 -eq 0) { "Moscow" } else { "Moscow {0:+0.##;-0.##}" -f $zxc35 }
    Write-Host ("  Time Zone    : {0}" -f $zxc36) -ForegroundColor White
} catch { Write-Host "  Error reading install info" -ForegroundColor Red }

$zxc37 = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($zxc37) {
    Write-Pink "`nCONNECTED DRIVES"
    foreach ($zxc38 in $zxc37) {
        if ($zxc38.DriveType -eq 2) { Write-Host ("  {0} {1} (Removable)" -f $zxc38.DeviceID, $zxc38.FileSystem) -ForegroundColor Red; $zxc6 += "Removable drive connected $($zxc38.DeviceID)" }
        else { Write-Host ("  {0} {1}" -f $zxc38.DeviceID, $zxc38.FileSystem) -ForegroundColor Green }
    }
}

Write-Pink "`nSERVICE STATUS"
$zxc39 = @(
    @{Name="SysMain";    DN="SysMain"},
    @{Name="PcaSvc";     DN="Program Compatibility Assistant"},
    @{Name="DPS";        DN="Diagnostic Policy Service"},
    @{Name="EventLog";   DN="Windows Event Log"},
    @{Name="Schedule";   DN="Task Scheduler"},
    @{Name="Bam";        DN="Background Activity Moderator"},
    @{Name="Dusmsvc";    DN="Data Usage"},
    @{Name="Appinfo";    DN="Application Information"},
    @{Name="CDPSvc";     DN="Connected Devices Platform"},
    @{Name="DcomLaunch"; DN="DCOM Server Process Launcher"},
    @{Name="PlugPlay";   DN="Plug and Play"},
    @{Name="wsearch";    DN="Windows Search"},
    @{Name="DiagTrack";  DN="Connected User Experiences (Telemetry)"},
    @{Name="Power";      DN="Power"},
    @{Name="icssvc";     DN="Mobile Hotspot (icssvc)"}
)
foreach ($zxc40 in $zxc39) {
    $zxc20 = Get-Service -Name $zxc40.Name -ErrorAction SilentlyContinue
    $zxc41 = $false
    if (-not $zxc20) {
        $zxc42 = Get-CimInstance Win32_SystemDriver -Filter "Name='$($zxc40.Name)'" -ErrorAction SilentlyContinue
        if ($zxc42) { $zxc41 = $true; $zxc20 = [PSCustomObject]@{ Status = $(if ($zxc42.State -eq "Running") { "Running" } else { $zxc42.State }) } }
    }
    if ($zxc20) {
        $zxc2 = (Get-CimInstance Win32_Service -Filter "Name='$($zxc40.Name)'" -ErrorAction SilentlyContinue).StartMode
        if ($zxc40.Name -eq "icssvc") {
            $zxc43 = if ($zxc20.Status -eq "Running") { "Red" } else { "Green" }
            Write-Host ("  {0,-12} {1}" -f $zxc40.Name, $zxc20.Status) -ForegroundColor $zxc43
        } elseif ($zxc20.Status -eq "Running" -and $zxc2 -ne "Disabled") {
            Write-Host ("  {0,-12} {1,-8}" -f $zxc40.Name, $zxc20.Status) -ForegroundColor Green -NoNewline
            if ($zxc41 -or $zxc40.Name -eq "Bam") { Write-Host " | Enabled" -ForegroundColor White }
            else {
                try {
                    $zxc44 = Get-CimInstance Win32_Service -Filter "Name='$($zxc40.Name)'" | Select-Object ProcessId
                    if ($zxc44.ProcessId -gt 0) {
                        $zxc10 = Get-Process -Id $zxc44.ProcessId -ErrorAction SilentlyContinue
                        if ($zxc10) { Write-Host (" | {0}" -f $zxc10.StartTime.ToString("HH:mm:ss")) -ForegroundColor White }
                        else { Write-Host " | N/A" -ForegroundColor White }
                    } else { Write-Host " | N/A" -ForegroundColor White }
                } catch { Write-Host " | N/A" -ForegroundColor White }
            }
        } else {
            $zxc45 = if ($zxc2 -eq "Disabled") { "$($zxc20.Status) (Disabled)" } else { "$($zxc20.Status)" }
            Write-Host ("  {0,-12} {1}" -f $zxc40.Name, $zxc45) -ForegroundColor Red
        }
    } else {
        Write-Host ("  {0,-12} N/A" -f $zxc40.Name) -ForegroundColor White
    }
}

function Get-SuspendedServiceHosts {
    param($zxc39)
    $zxc46 = 0
    $zxc47 = 0
    $zxc48 = @()
    $zxc49 = @()
    foreach ($zxc50 in ($zxc39 | Group-Object ProcessId)) {
        $zxc51 = Get-Process -Id ([int]$zxc50.Name) -ErrorAction SilentlyContinue
        if (-not $zxc51) { continue }
        $zxc52 = @($zxc51.Threads)
        if ($zxc52.Count -eq 0) { $zxc47++; continue }
        $zxc46++
        $zxc53 = @($zxc52 | Where-Object { $_.ThreadState -eq 'Wait' -and $_.WaitReason -eq 'Suspended' })
        $zxc54 = [pscustomobject]@{ ProcessId = [int]$zxc50.Name; Names = (($zxc50.Group | ForEach-Object { $_.Name }) -join ', '); Suspended = $zxc53.Count; Total = $zxc52.Count }
        $zxc49 += $zxc54
        if ($zxc53.Count -gt 0) { $zxc48 += $zxc54 }
    }
    [pscustomobject]@{ Checked = $zxc46; Unreadable = $zxc47; Bad = $zxc48; All = $zxc49 }
}

Write-Pink "`nSERVICE THREADS CHECK"
try {
    $zxc55 = @($zxc39 | ForEach-Object { $_.Name })
    $zxc56 = @(& "$env:SystemRoot\System32\tasklist.exe" /svc /fo csv /nh | ConvertFrom-Csv -Header 'Image','Pid','Services')
    $zxc57 = @()
    foreach ($zxc54 in $zxc56) {
        if ($zxc54.Services -eq 'N/A' -or -not ($zxc54.Pid -as [int])) { continue }
        foreach ($zxc58 in ($zxc54.Services -split ',')) {
            if ($zxc55 -contains $zxc58.Trim()) { $zxc57 += [pscustomobject]@{ Name = $zxc58.Trim(); ProcessId = [int]$zxc54.Pid } }
        }
    }
    $zxc59 = Get-SuspendedServiceHosts $zxc57
    foreach ($zxc60 in ($zxc59.All | Sort-Object Names)) {
        if ($zxc60.Suspended -gt 0) {
            Write-Host ("  {0,-26} PID {1}, threads {2}, suspended {3}" -f $zxc60.Names, $zxc60.ProcessId, $zxc60.Total, $zxc60.Suspended) -ForegroundColor Red
            $zxc5 += "Service threads suspended: $($zxc60.Names) ($($zxc60.Suspended) of $($zxc60.Total))"
            if ($zxc60.Suspended -eq $zxc60.Total) { $zxc5 += "Service process is fully frozen: $($zxc60.Names)" }
        } else {
            Write-Host ("  {0,-26} PID {1}, threads {2}, suspended 0" -f $zxc60.Names, $zxc60.ProcessId, $zxc60.Total) -ForegroundColor Green
        }
    }
    if ($zxc59.Unreadable -gt 0) { Write-Host ("  Unreadable : {0}" -f $zxc59.Unreadable) -ForegroundColor Gray }
} catch { Write-Host "  Error during service threads check" -ForegroundColor Red }
Write-Pink "`nREGISTRY"
$zxc61 = @(
    @{Name="CMD";              Path="HKCU:\Software\Policies\Microsoft\Windows\System";                                                                Key="DisableCMD";               W="Disabled"; S="Available"; BadVals=@(1,2)},
    @{Name="Task Manager";     Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System";                                                 Key="DisableTaskMgr";           W="Disabled"; S="Available"; BadVals=@(1)},
    @{Name="Registry Editor";  Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System";                                                 Key="DisableRegistryTools";     W="Disabled"; S="Available"; BadVals=@(1)},
    @{Name="PS Logging";       Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging";                                         Key="EnableScriptBlockLogging"; W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Activities Cache"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                                Key="EnableActivityFeed";       W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Prefetch";         Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key="EnablePrefetcher"; W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Superfetch";       Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key="EnableSuperfetch"; W="Disabled"; S="Enabled"; BadVals=@(0)}
)
foreach ($zxc62 in $zxc61) {
    $zxc63 = Get-ItemProperty -Path $zxc62.Path -Name $zxc62.Key -ErrorAction SilentlyContinue
    Write-Host "  $($zxc62.Name): " -NoNewline -ForegroundColor White
    if ($zxc63 -and ($zxc62.BadVals -contains $zxc63.$($zxc62.Key))) { Write-Host $zxc62.W -ForegroundColor Red; $zxc6 += "$($zxc62.Name) $($zxc62.W)" }
    else { Write-Host $zxc62.S -ForegroundColor Green }
}

Write-Pink "`nWINDOWS DEFENDER"
try {
    $zxc64 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $zxc65 = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $zxc66 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name TamperProtection -ErrorAction SilentlyContinue).TamperProtection
    $zxc67 = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $zxc68 = Get-MpPreference -ErrorAction SilentlyContinue
    $zxc69 = ($zxc67 -and ($zxc67.RealTimeProtectionEnabled -eq $false)) -or ($zxc68 -and $zxc68.DisableRealtimeMonitoring)
    Write-Host "  Real-Time Protection : " -NoNewline -ForegroundColor White
    if ($zxc64 -eq 1 -or $zxc65 -eq 1 -or $zxc69) { Write-Host "DISABLED" -ForegroundColor Red; $zxc5 += "Defender real-time protection is OFF" }
    else { Write-Host "Enabled" -ForegroundColor Green }
    Write-Host "  Tamper Protection    : " -NoNewline -ForegroundColor White
    if ($zxc66 -eq 5) { Write-Host "Enabled" -ForegroundColor Green }
    elseif ($null -eq $zxc66) { Write-Host "Unknown" -ForegroundColor Gray }
    else { Write-Host "DISABLED" -ForegroundColor Red; $zxc6 += "Tamper Protection disabled" }
    if ($zxc65 -eq 1) { Write-Host "  Note: disabled via Group Policy" -ForegroundColor White }
    if ($zxc67 -and $zxc67.AMRunningMode -and $zxc67.AMRunningMode -ne "Normal") { Write-Host "  Running Mode         : $($zxc67.AMRunningMode)" -ForegroundColor Red; $zxc6 += "Defender running mode $($zxc67.AMRunningMode)" }
    $zxc70 = @()
    foreach ($zxc71 in @("ExclusionPath","ExclusionProcess","ExclusionExtension")) { $zxc70 += @($zxc68.$zxc71 | Where-Object { $_ }) }
    if ($zxc70.Count -gt 0) {
        Write-Host "  Exclusions           : $($zxc70.Count)" -ForegroundColor Red
        foreach ($zxc72 in $zxc70) { Write-Host "    $zxc72" -ForegroundColor White }
        $zxc6 += "Defender exclusions ($($zxc70.Count))"
    } else { Write-Host "  Exclusions           : None" -ForegroundColor Green }
    $zxc73 = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 8)
    if ($zxc73.Count -gt 0) {
        Write-Host "  Detections           : $($zxc73.Count)" -ForegroundColor Red
        foreach ($zxc74 in $zxc73) { Write-Host ("    {0}  {1}" -f $zxc74.InitialDetectionTime.ToString("yyyy-MM-dd HH:mm"), ($zxc74.Resources -join '; ')) -ForegroundColor White }
        $zxc6 += "Defender detections in history ($($zxc73.Count))"
    } else { Write-Host "  Detections           : None" -ForegroundColor Green }
    $zxc75 = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Windows Defender/Operational"; Id=5001; StartTime=(Get-Date).AddDays(-14)} -MaxEvents 3 -ErrorAction SilentlyContinue
    foreach ($zxc76 in $zxc75) { Write-Host "  Real-time was turned off at $($zxc76.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
    if ($zxc75 -and -not ($zxc5 -contains "Defender real-time protection is OFF")) { $zxc5 += "Defender real-time was turned off recently" }
} catch { Write-Host "  Error reading Defender status" -ForegroundColor Red }

Write-Pink "`nEVENT LOGS"
function Check-EV { param($zxc77,$zxc78,$zxc79)
    $zxc76 = Get-WinEvent -LogName $zxc77 -FilterXPath "*[System[EventID=$zxc78]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($zxc76) { Write-Host "  $zxc79 at: " -NoNewline -ForegroundColor White; Write-Host $zxc76.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  $zxc79 - No records found" -ForegroundColor Green }
}
function Check-EVMulti { param($zxc77,$zxc80,$zxc79)
    $zxc81 = ($zxc80 | ForEach-Object { "EventID=$_" }) -join " or "
    $zxc76 = Get-WinEvent -LogName $zxc77 -FilterXPath "*[System[$zxc81]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($zxc76) { Write-Host "  $zxc79 (ID:$($zxc76.Id)) at: " -NoNewline -ForegroundColor White; Write-Host $zxc76.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  $zxc79 - No records found" -ForegroundColor Green }
}
Check-EV      "Application" 3079        "USN Journal cleared"
Check-EV      "System"      104         "Event Logs cleared"
Check-EV      "Security"    1102        "Security Log cleared"
Check-EV      "System"      1074        "Last PC Shutdown"
Check-EV      "Security"    4616        "System time changed"
Check-EV      "System"      6005        "Event Log Service started"
try {
    $zxc82 = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -FilterXPath "*[System[EventID=400]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($zxc82) { Write-Host "  Device config changed at: " -NoNewline -ForegroundColor White; Write-Host $zxc82.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  Device changes - No records found" -ForegroundColor Green }
} catch { Write-Host "  Device changes - No records found" -ForegroundColor Green }
$zxc83 = Get-WinEvent -FilterHashtable @{LogName="System"; Id=104} -MaxEvents 1 -ErrorAction SilentlyContinue
$zxc84 = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=1102} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($zxc83 -or $zxc84) { $zxc6 += "Event log was cleared" }

$zxc85 = Get-WinEvent -FilterHashtable @{LogName="System"; ProviderName="Microsoft-Windows-Kernel-General"; Id=1; StartTime=(Get-Date).AddDays(-30)} -MaxEvents 400 -ErrorAction SilentlyContinue
$zxc86 = @()
foreach ($zxc76 in $zxc85) {
    try {
        $zxc87 = [datetime]$zxc76.Properties[0].Value; $zxc88 = [datetime]$zxc76.Properties[1].Value
        if ([int]$zxc76.Properties[3].Value -notin 1,2 -and [math]::Abs(($zxc87 - $zxc88).TotalSeconds) -gt 2) {
            $zxc86 += [PSCustomObject]@{ At=$zxc76.TimeCreated; Old=$zxc88.ToLocalTime(); New=$zxc87.ToLocalTime(); By=(Split-Path ([string]$zxc76.Properties[4].Value) -Leaf) }
        }
    } catch {}
}
if ($zxc86.Count -gt 0) {
    Write-Host "  Clock changed manually : $($zxc86.Count) time(s) in 30 days" -ForegroundColor Red
    foreach ($zxc89 in ($zxc86 | Select-Object -First 8)) { Write-Host ("    {0}  {1} -> {2}  by {3}" -f $zxc89.At.ToString("MM-dd HH:mm"), $zxc89.Old.ToString("yyyy-MM-dd HH:mm:ss"), $zxc89.New.ToString("yyyy-MM-dd HH:mm:ss"), $zxc89.By) -ForegroundColor White }
    $zxc5 += "System clock changed manually ($($zxc86.Count))"
} else { Write-Host "  Clock changes - No manual changes in 30 days" -ForegroundColor Green }

Write-Pink "`nUSN JOURNAL"
try {
    $zxc90 = fsutil usn queryjournal C: 2>&1
    if ($zxc90 -match "Invalid") {
        Write-Host "  Status       : DISABLED" -ForegroundColor Red
        $zxc6 += "USN Journal disabled"
    } elseif ($zxc90 -match "Usn Journal ID") {
        Write-Host "  Status       : Enabled" -ForegroundColor Green
        $zxc91 = Get-WinEvent -LogName "Application" -FilterXPath "*[System[EventID=3079]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($zxc91) { Write-Host "  Last cleared : $($zxc91.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
        else { Write-Host "  Last cleared : Never cleared manually" -ForegroundColor Green }
        $zxc92 = $zxc90 | Select-String "First Usn"
        if ($zxc92) { Write-Host "  $($zxc92.Line.Trim())" -ForegroundColor Gray }
    } else { Write-Host "  Status       : Unknown" -ForegroundColor White }
} catch { Write-Host "  Error reading USN Journal" -ForegroundColor Red }

Write-Pink "`nRECENTLY DELETED FILES (48h)"
try {
    $zxc93 = (Get-Date).AddHours(-48)
    $zxc94 = @{}; $zxc95 = 0
    foreach ($zxc38 in (Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.FileSystem -eq "NTFS" })) {
        $zxc96 = $zxc38.DeviceID
        $zxc97 = (fsutil usn queryjournal $zxc96 2>&1 | Out-String)
        if ($zxc97 -notmatch '(?i)First Usn\s*:\s*(0x[0-9a-f]+)') { continue }
        $zxc98 = [Convert]::ToInt64($Matches[1].Substring(2), 16)
        $zxc99 = cmd /c "fsutil usn readjournal $zxc96 startusn=$zxc98 csv | findstr /i /c:""File delete"" /c:""Rename: old"""
        foreach ($zxc100 in $zxc99) {
            if ($zxc100 -notmatch '^\d+,"(.*?)",\d+,0x[0-9a-fA-F]+,"(.*?)","(.*?)"') { continue }
            $zxc101 = $Matches[1]; $zxc102 = $Matches[2]; $zxc103 = $Matches[3]
            $zxc104 = [datetime]::MinValue
            if (-not [datetime]::TryParse($zxc103, [Globalization.CultureInfo]::CurrentCulture, 'None', [ref]$zxc104)) { continue }
            if ($zxc104 -lt $zxc93) { continue }
            if ($zxc101 -match '^__PSScriptPolicyTest|^tmp[0-9a-f]{6,}\.|\.tmp$') { continue }
            $zxc105 = $zxc101 -match '\.pf$'
            if (-not (($zxc101 -match '\.(exe|jar|bat|cmd|ps1|vbs|zip|rar|7z|msi|sys)$') -or ($zxc101 -match $zxc13) -or $zxc105)) { continue }
            if ($zxc105 -and $zxc102 -match 'delete') { $zxc95++ }
            if ($zxc105) { continue }
            $zxc106 = $zxc101.ToLower()
            $zxc107 = if ($zxc102 -match 'Rename') { "renamed" } else { "deleted" }
            if (-not $zxc94.ContainsKey($zxc106) -or $zxc94[$zxc106].Time -lt $zxc104) { $zxc94[$zxc106] = [PSCustomObject]@{ Name=$zxc101; Time=$zxc104; Kind=$zxc107 } }
        }
    }
    $zxc108 = @($zxc94.Values | Sort-Object Time -Descending)
    $zxc109 = @($zxc108 | Where-Object { $_.Name -match $zxc13 })
    $zxc110 = @($zxc108 | Where-Object { $_.Name -notmatch $zxc13 })
    if ($zxc95 -gt 0) { Write-Host "  Prefetch files deleted : $zxc95" -ForegroundColor Red; $zxc6 += "Prefetch files deleted ($zxc95)" }
    if ($zxc109.Count -gt 0) {
        Write-Host "  Cheat-named files : $($zxc109.Count)" -ForegroundColor Red
        foreach ($zxc111 in ($zxc109 | Select-Object -First 20)) { Write-Host ("    {0}  {1,-8} {2}" -f $zxc111.Time.ToString("yyyy-MM-dd HH:mm:ss"), $zxc111.Kind, $zxc111.Name) -ForegroundColor Red }
        $zxc5 += "Cheat-named files deleted/renamed ($($zxc109.Count))"
    }
    if ($zxc110.Count -gt 0) {
        Write-Host "  Deleted/renamed exe, jar, archives : $($zxc110.Count) (newest 30)" -ForegroundColor White
        foreach ($zxc111 in ($zxc110 | Select-Object -First 30)) { Write-Host ("    {0}  {1,-8} {2}" -f $zxc111.Time.ToString("yyyy-MM-dd HH:mm:ss"), $zxc111.Kind, $zxc111.Name) -ForegroundColor White }
    }
    if ($zxc108.Count -eq 0 -and $zxc95 -eq 0) { Write-Host "  Nothing suspicious in journal" -ForegroundColor Green }
} catch { Write-Host "  Error reading USN records" -ForegroundColor Red }

$zxc112 = "$env:SystemRoot\Prefetch"
if (Test-Path $zxc112) {
    Write-Pink "`nPREFETCH INTEGRITY"
    $zxc113 = Get-ChildItem $zxc112 -Filter *.pf -Force -ErrorAction SilentlyContinue
    if (-not $zxc113) { Write-Host "  No prefetch files found" -ForegroundColor White }
    else {
        $zxc114 = $zxc113.Count; $zxc115 = @{}; $zxc116 = @{}; $zxc117 = @(); $zxc118 = @(); $zxc119 = @()
        foreach ($zxc120 in $zxc113) {
            try {
                $zxc121 = $zxc120.Attributes -band [System.IO.FileAttributes]::Hidden
                $zxc122 = $zxc120.Attributes -band [System.IO.FileAttributes]::ReadOnly
                if ($zxc121 -and $zxc122) { $zxc119 += $zxc120; $zxc116[$zxc120.Name] = "Hidden+ReadOnly" }
                elseif ($zxc121)       { $zxc117   += $zxc120; $zxc116[$zxc120.Name] = "Hidden" }
                elseif ($zxc122)       { $zxc118    += $zxc120; $zxc116[$zxc120.Name] = "ReadOnly" }
                if ($zxc120.Length -eq 0) { $zxc116[$zxc120.Name] = "Zero length" }
                else {
                    $zxc123 = [IO.File]::Open($zxc120.FullName, 'Open', 'Read', 'ReadWrite'); $zxc124 = New-Object byte[] 8; [void]$zxc123.Read($zxc124, 0, 8); $zxc123.Close()
                    $zxc125 = ($zxc124[0] -eq 0x4D -and $zxc124[1] -eq 0x41 -and $zxc124[2] -eq 0x4D) -or ($zxc124[4] -eq 0x53 -and $zxc124[5] -eq 0x43 -and $zxc124[6] -eq 0x43 -and $zxc124[7] -eq 0x41)
                    if (-not $zxc125) { $zxc116[$zxc120.Name] = "Invalid header (fake/edited)" }
                }
                $zxc111 = Get-FileHash $zxc120.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($zxc111) {
                    if ($zxc115.ContainsKey($zxc111.Hash)) { $zxc115[$zxc111.Hash].Add($zxc120.Name) }
                    else { $zxc115[$zxc111.Hash] = [System.Collections.Generic.List[string]]::new(); $zxc115[$zxc111.Hash].Add($zxc120.Name) }
                }
            } catch { $zxc116[$zxc120.Name] = "Error" }
        }
        if ($zxc119.Count -gt 0) { Write-Host "  Hidden+ReadOnly: $($zxc119.Count)" -ForegroundColor White; $zxc119 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        if ($zxc117.Count   -gt 0) { Write-Host "  Hidden: $($zxc117.Count)" -ForegroundColor White; $zxc117 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        elseif ($zxc119.Count -eq 0) { Write-Host "  Hidden Files: None" -ForegroundColor Green }
        if ($zxc118.Count    -gt 0) { Write-Host "  ReadOnly: $($zxc118.Count)" -ForegroundColor White; $zxc118 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        else { Write-Host "  ReadOnly Files: None" -ForegroundColor Green }
        $zxc126 = $zxc115.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($zxc126) {
            foreach ($zxc76 in $zxc126) {
                $zxc76.Value | ForEach-Object { if (-not $zxc116.ContainsKey($_)) { $zxc116[$_] = "Duplicate" } }
                Write-Host "  Duplicate: $($zxc76.Value -join ', ')" -ForegroundColor White
            }
        } else { Write-Host "  Duplicates: None" -ForegroundColor Green }
        if ($zxc116.Count -gt 0) {
            Write-Host "`n  SUSPICIOUS: $($zxc116.Count)/$zxc114" -ForegroundColor White
            foreach ($zxc76 in $zxc116.GetEnumerator() | Sort-Object Key) { Write-Host "    $($zxc76.Key) : $($zxc76.Value)" -ForegroundColor White }
            $zxc6 += "Suspicious prefetch files ($($zxc116.Count))"
        } else { Write-Host "`n  Prefetch integrity: Clean ($zxc114 files)" -ForegroundColor Green }
        $zxc127 = $zxc113 | Sort-Object LastWriteTime
        Write-Host ("  Oldest / Newest : {0}  /  {1}" -f $zxc127[0].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), $zxc127[-1].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        if ($zxc127[-1].LastWriteTime -lt $zxc29) { Write-Host "  No prefetch updates since boot" -ForegroundColor Red; $zxc6 += "No prefetch updates since boot" }
        if ($zxc11) {
            $zxc128 = @($zxc113 | Sort-Object LastWriteTime)
            $zxc129 = @($zxc128 | Where-Object { $_.LastWriteTime -lt $zxc11.StartTime } | Select-Object -Last 5)
            $zxc130  = @($zxc128 | Where-Object { $_.LastWriteTime -ge $zxc11.StartTime } | Select-Object -First 15)
            Write-Host "`n  Around Java launch (5 before, 15 after)" -ForegroundColor White
            foreach ($zxc120 in $zxc129) {
                Write-Host ("    {0}  {1}" -f $zxc120.LastWriteTime.ToString("MM-dd HH:mm:ss"), $zxc120.Name) -ForegroundColor $(if ($zxc120.Name -match $zxc13) { "Red" } else { "Gray" })
            }
            Write-Host ("    ---- Java started {0} ----" -f $zxc11.StartTime.ToString("MM-dd HH:mm:ss")) -ForegroundColor White
            foreach ($zxc120 in $zxc130) {
                Write-Host ("    {0}  {1}" -f $zxc120.LastWriteTime.ToString("MM-dd HH:mm:ss"), $zxc120.Name) -ForegroundColor $(if ($zxc120.Name -match $zxc13) { "Red" } else { "Gray" })
            }
        } else {
            Write-Host "`n  Last 20 executed" -ForegroundColor White
            foreach ($zxc120 in ($zxc113 | Sort-Object LastWriteTime -Descending | Select-Object -First 20)) {
                Write-Host ("    {0}  {1}" -f $zxc120.LastWriteTime.ToString("MM-dd HH:mm:ss"), $zxc120.Name) -ForegroundColor $(if ($zxc120.Name -match $zxc13) { "Red" } else { "Gray" })
            }
        }
        $zxc131 = @($zxc113 | Where-Object { $_.Name -match $zxc13 } | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
        foreach ($zxc120 in $zxc131) { Write-Host ("  Cheat name in prefetch : {0}  {1}" -f $zxc120.Name, $zxc120.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Red; $zxc5 += "Prefetch match $($zxc120.Name)" }
    }
} else { Write-Host "`nPREFETCH folder not found" -ForegroundColor Red }

Write-Pink "`nPOWERSHELL HISTORY"
$zxc132 = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $zxc132) {
    $zxc133 = Get-Item $zxc132 -Force
    Write-Host "  Last Modified : $($zxc133.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "  File Size     : $([math]::Round($zxc133.Length/1024,2)) KB" -ForegroundColor White
    $zxc134 = $zxc133.Attributes
    if ($zxc134 -ne "Archive") { Write-Host "  Attributes    : $zxc134" -ForegroundColor White }
    else { Write-Host "  Attributes    : Normal" -ForegroundColor Green }
} else { Write-Host "  History file not found" -ForegroundColor White }

Write-Pink "`nUSB HISTORY"
try {
    $zxc135 = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $zxc135) {
        $zxc136 = Get-ChildItem -Path $zxc135 -ErrorAction SilentlyContinue
        if ($zxc136) {
            foreach ($zxc137 in $zxc136) {
                foreach ($zxc138 in (Get-ChildItem -Path $zxc137.PSPath -ErrorAction SilentlyContinue)) {
                    $zxc139 = Get-ItemProperty -Path $zxc138.PSPath -ErrorAction SilentlyContinue
                    $zxc140 = $zxc139.FriendlyName
                    if (-not $zxc140) { $zxc140 = $zxc137.PSChildName -replace "_", " " }
                    $zxc141 = $null
                    $zxc142 = Join-Path $zxc138.PSPath "Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0065"
                    if (Test-Path $zxc142) {
                        $zxc143 = Get-ItemProperty -Path $zxc142 -ErrorAction SilentlyContinue
                        if ($zxc143.'(default)') { try { $zxc141 = [datetime]::FromFileTime([BitConverter]::ToInt64($zxc143.'(default)',0)) } catch {} }
                    }
                    Write-Host "  $zxc140" -ForegroundColor White -NoNewline
                    if ($zxc141) { Write-Host (" | Last seen: {0}" -f $zxc141.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White }
                    else { Write-Host "" }
                }
            }
        } else { Write-Host "  No USB storage devices found" -ForegroundColor Green }
    } else { Write-Host "  USBSTOR key not accessible" -ForegroundColor White }
} catch { Write-Host "  Error reading USB history" -ForegroundColor Red }

Write-Pink "`nLOGGED-ON USERS"
try {
    $zxc144 = Get-CimInstance Win32_LogonSession -ErrorAction SilentlyContinue | Where-Object { $_.LogonType -in @(2,10,11) }
    $zxc145 = @{ 2="Interactive"; 10="RemoteInteractive"; 11="CachedInteractive" }
    if ($zxc144) {
        $zxc146 = @()
        foreach ($zxc147 in $zxc144) {
            $zxc148 = Get-CimAssociatedInstance -InputObject $zxc147 -ResultClassName Win32_UserAccount -ErrorAction SilentlyContinue
            $zxc149 = if ($zxc148) { "$($zxc148.Domain)\$($zxc148.Name)" } else { (Get-CimInstance Win32_ComputerSystem).UserName }
            $zxc146 += [PSCustomObject]@{ User=$zxc149; Type=$zxc145[[int]$zxc147.LogonType]; Start=$zxc147.StartTime }
        }
        foreach ($zxc50 in ($zxc146 | Group-Object User, Type)) {
            $zxc98 = $zxc50.Group | Sort-Object Start | Select-Object -First 1
            $zxc45 = if ($zxc98.Start) { $zxc98.Start.ToString("yyyy-MM-dd HH:mm:ss") } else { "N/A" }
            Write-Host ("  {0,-30} {1,-18} Since: {2}" -f $zxc98.User, $zxc98.Type, $zxc45) -ForegroundColor White
        }
    } else {
        $zxc150 = (Get-CimInstance Win32_ComputerSystem).UserName
        if ($zxc150) { Write-Host "  $zxc150" -ForegroundColor White } else { Write-Host "  No interactive sessions" -ForegroundColor Green }
    }
} catch { Write-Host "  Error retrieving sessions" -ForegroundColor Red }

Write-Pink "`nHOTSPOT / FAKER DETECTION"
try {
    $zxc151 = netsh wlan show profiles
    $zxc71 = @()
    foreach ($zxc100 in $zxc151) { if ($zxc100 -match '^\s*[^:]*(Profile|profil|\u041f\u0440\u043e\u0444\u0438\u043b\u044c)[^:]*:\s*(.+)$') { $zxc71 += $Matches[2].Trim() } }
    foreach ($zxc10 in $zxc71) {
        if ([string]::IsNullOrWhiteSpace($zxc10)) { continue }
        $zxc152 = $zxc10 -match "Android|iPhone|iPad|Galaxy|Pixel|OnePlus|Xiaomi|DIRECT-|^SM-[A-Z0-9]|^GT-[A-Z0-9]"
        $zxc9 += [PSCustomObject]@{ SSID=$zxc10; IsHotspot=$zxc152 }
    }
    $zxc153 = $zxc9 | Where-Object { $_.IsHotspot }
    if ($zxc153.Count -gt 0) { Write-Host "  Hotspot profiles: $($zxc153.Count)" -ForegroundColor White; $zxc153 | ForEach-Object { Write-Host "    - $($_.SSID)" -ForegroundColor White } }
    else { Write-Host "  WiFi profiles: no mobile hotspots" -ForegroundColor Green }
} catch {}

try {
    $zxc154  = netsh wlan show interfaces
    $zxc155 = $null; $zxc156 = "N/A"; $zxc157 = "N/A"; $zxc158 = "N/A"
    foreach ($zxc100 in $zxc154) {
        if ($zxc100 -match '^\s*SSID\s*:\s*(.+)$') { $zxc155 = $Matches[1].Trim() }
        elseif ($zxc100 -match '^\s*(AP )?BSSID\s*:\s*([0-9a-fA-F:]{17})') { $zxc156 = $Matches[2] }
        elseif ($zxc100 -match '^\s*(Channel|\u041a\u0430\u043d\u0430\u043b)\s*:\s*(\d+)') { $zxc157 = $Matches[2] }
        elseif ($zxc100 -match '^\s*(Signal|\u0421\u0438\u0433\u043d\u0430\u043b)\s*:\s*(\d+%)') { $zxc158 = $Matches[2] }
    }
    if (-not $zxc155) {
        $zxc159 = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -match 'Wi-?Fi|Wireless|WLAN|\u0411\u0435\u0441\u043f\u0440\u043e\u0432\u043e\u0434' } | Select-Object -First 1
        if ($zxc159) { $zxc155 = $zxc159.Name }
    }
    $zxc160 = if ($zxc155) { "connected" } else { "" }
    if ($zxc155) {
        if ($zxc160 -eq "connected") {
            $zxc152 = $false; $zxc161 = @()
            $zxc162 = @("Android","iPhone","iPad","Galaxy","Pixel","OnePlus","Xiaomi","Huawei","Oppo","Vivo","Realme","Nokia","DIRECT-","SM-[A-Z0-9]","GT-[A-Z0-9]","Redmi","'s iPhone","'s Galaxy","'s Pixel")
            foreach ($zxc163 in $zxc162) { if ($zxc155 -match $zxc163) { $zxc152=$true; $zxc161+="SSID matches: $zxc163"; break } }
            if ($zxc156 -ne "N/A") { $zxc164=$zxc156.Substring(1,1); if ($zxc164 -match "[26AEae]") { $zxc152=$true; $zxc161+="BSSID locally administered" } }
            try {
                $zxc165 = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
                if ($zxc165) {
                    if ($zxc165 -like "192.168.137.*") { $zxc152=$true; $zxc7=$true; $zxc8+="Windows PC Hotspot gateway (192.168.137.x)"; $zxc161+="Gateway = Windows Mobile Hotspot - FAKER" }
                    elseif ($zxc165 -in @("192.168.43.1","192.168.49.1","192.168.44.1","192.168.42.129")) { $zxc152=$true; $zxc161+="Gateway = Android hotspot / USB tethering" }
                    elseif ($zxc165 -eq "172.20.10.1") { $zxc152=$true; $zxc161+="Gateway = iPhone hotspot" }
                }
            } catch {}
            Write-Host "  Connected to: $zxc155" -ForegroundColor $(if ($zxc152) { "Red" } else { "Green" })
            Write-Host "    BSSID: $zxc156 | Channel: $zxc157 | Signal: $zxc158" -ForegroundColor Gray
            if ($zxc152) { Write-Host "  WARNING: HOTSPOT DETECTED!" -ForegroundColor Red; $zxc161 | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }; $zxc4+="Connected to hotspot: $zxc155" }
        }
    }
} catch {}

try {
    $zxc166   = netsh wlan show hostednetwork
    $zxc167 = $zxc166 | Select-String "Status\s+:\s+(.+)"
    if ($zxc166 -match '(Started|\u0417\u0430\u043f\u0443\u0449\u0435\u043d)') {
        $zxc168 = $zxc166 | Select-String 'SSID name\s+:\s+"(.+)"'
        $zxc169 = if ($zxc168) { $zxc168.Matches.Groups[1].Value } else { "Unknown" }
        Write-Host "  WARNING: Hosted Network ACTIVE! SSID: $zxc169" -ForegroundColor Red
        $zxc4 += "Hosted network active: $zxc169"
    } else { Write-Host "  Hosted Network: Inactive" -ForegroundColor Green }
} catch {}

$zxc170 = Get-Service -Name "icssvc" -ErrorAction SilentlyContinue
if ($zxc170) {
    if ($zxc170.Status -eq "Running") { Write-Host "  Mobile Hotspot (icssvc): RUNNING" -ForegroundColor Red; $zxc4+="icssvc running" }
    else { Write-Host "  Mobile Hotspot (icssvc): Stopped" -ForegroundColor Green }
}

try {
    $zxc171 = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true -and $_.Description -match "Virtual|Hosted|Wi-Fi Direct|TAP" }
    if ($zxc171) { $zxc171 | ForEach-Object { Write-Host "  Virtual adapter: $($_.Description)" -ForegroundColor White }; $zxc4+="$(@($zxc171).Count) virtual adapter(s)" }
    else { Write-Host "  Virtual adapters: None" -ForegroundColor Green }
    $zxc172 = @(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true -and $_.Description -match "Remote NDIS|RNDIS|Apple Mobile Device|Tether|Mobile Broadband" })
    foreach ($zxc134 in $zxc172) { Write-Host "  USB tethering adapter: $($zxc134.Description)" -ForegroundColor Red; $zxc4 += "USB tethering: $($zxc134.Description)" }
} catch {}

try {
    if (Get-NetIPAddress -AddressFamily IPv4 -IPAddress "192.168.137.1" -ErrorAction SilentlyContinue) {
        Write-Host "  This PC owns 192.168.137.1 (hosting Windows hotspot)" -ForegroundColor Red
        $zxc7 = $true; $zxc8 += "This PC hosts Windows Mobile Hotspot"; $zxc4 += "Hosting Windows hotspot"
    }
    $zxc173 = Get-Service -Name "SharedAccess" -ErrorAction SilentlyContinue
    if ($zxc173 -and $zxc173.Status -eq "Running") { Write-Host "  Internet Connection Sharing: RUNNING" -ForegroundColor Red; $zxc6 += "Internet Connection Sharing running" }
    $zxc174 = Get-NetTCPConnection -LocalPort 3389 -State Established -ErrorAction SilentlyContinue
    if ($zxc174) { Write-Host ("  Active RDP session from: {0}" -f (($zxc174 | Select-Object -ExpandProperty RemoteAddress -Unique) -join ', ')) -ForegroundColor Red; $zxc4 += "Active RDP session" }
    $zxc175 = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
    if ($zxc175.ProxyEnable -eq 1) { Write-Host "  System proxy: $($zxc175.ProxyServer)" -ForegroundColor White; $zxc6 += "System proxy enabled ($($zxc175.ProxyServer))" }
    $zxc176 = @(Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue | Where-Object { $_ -and $_ -notmatch '^\s*#' })
    if ($zxc176.Count -gt 0) { Write-Host "  hosts file entries: $($zxc176.Count)" -ForegroundColor Red; $zxc176 | Select-Object -First 8 | ForEach-Object { Write-Host "    $($_.Trim())" -ForegroundColor White }; $zxc6 += "hosts file has active entries" }
    else { Write-Host "  hosts file: clean" -ForegroundColor Green }
} catch {}

Write-Pink "`nJAVA PROCESSES"
$zxc177 = Get-Process -Name @("java","javaw") -ErrorAction SilentlyContinue
if (-not $zxc177) { Write-Host "  No java/javaw processes running" -ForegroundColor Green }
else {
    Write-Host "  Total java processes: $($zxc177.Count)" -ForegroundColor White
    $zxc178 = netstat -ano | Select-String "LISTENING|ESTABLISHED"
    foreach ($zxc179 in $zxc177) {
        Write-Host ""
        Write-Host ("  PID {0} | Started: {1}" -f $zxc179.Id, $zxc179.StartTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        try {
            $zxc180 = (Get-CimInstance Win32_Process -Filter "ProcessId=$($zxc179.Id)").CommandLine
            if ($zxc180) {
                $zxc181 = [regex]::Replace((Redact $zxc180), '(?<=\s)(-cp|-classpath|--class-path)\s+("[^"]+"|\S+)', { param($zxc182) "{0} ({1} jars)" -f $zxc182.Groups[1].Value, ($zxc182.Groups[2].Value -split ';').Count })
                Write-Host "    CMD: $zxc181" -ForegroundColor Gray
            }
        } catch {}
        $zxc183 = $zxc178 | Where-Object { $_ -match "\s+$($zxc179.Id)\s*$" }
        if ($zxc183) {
            Write-Host "    Ports:" -ForegroundColor White
            $zxc183 | ForEach-Object { Write-Host "      $($_.Line.Trim())" -ForegroundColor White }
        } else { Write-Host "    Ports: none found" -ForegroundColor Gray }
    }
}

Write-Pink "`nJVM ARGUMENTS"
$zxc184 = $false
Get-CimInstance Win32_Process | Where-Object { $_.Name -in @("javaw.exe","java.exe") } | ForEach-Object {
    $zxc185 = $_.CommandLine
    if (-not $zxc185) { return }
    $zxc186 = $zxc185 -split ' (?=-)' | Where-Object {
        $_ -like "-Xmx*" -or $_ -like "-Xms*" -or $_ -like "-javaagent*" -or $_ -like "-Dfabric.addMods*" -or $_ -like "-Dloader.addMods*" -or
        $_ -like "-agentpath*" -or $_ -like "-agentlib*" -or $_ -like "-Xbootclasspath*" -or $_ -like "-noverify*" -or $_ -like "-Xverify:none*" -or $_ -like "-Djava.system.class.loader*"
    }
    if ($zxc186) {
        $zxc184 = $true
        Write-Host "  PID $($_.ProcessId)" -ForegroundColor White
        foreach ($zxc134 in $zxc186) {
            $zxc74 = $zxc134.Trim()
            $zxc48 = ($zxc74 -like "-javaagent*" -or $zxc74 -like "-D*addMods*" -or $zxc74 -like "-agentpath*" -or $zxc74 -like "-agentlib*" -or $zxc74 -like "-Xbootclasspath*" -or $zxc74 -like "-noverify*" -or $zxc74 -like "-Xverify:none*" -or $zxc74 -like "-Djava.system.class.loader*")
            $zxc187 = ($zxc74 -match '\\Temp\\\.tmp[^\\]+\\theseus\.jar$') -and ($zxc185 -match 'com\.modrinth\.theseus')
            if ($zxc187) { Write-Host "    $zxc74 (Modrinth launcher agent, normal)" -ForegroundColor White; continue }
            Write-Host "    $zxc74" -ForegroundColor $(if ($zxc48) { "Red" } else { "White" })
            if ($zxc48) { $zxc5 += "JVM arg: $zxc74" }
        }
    }
}
if (-not $zxc184) { Write-Host "  No relevant JVM/mod arguments" -ForegroundColor Green }

Write-Pink "`nPROCESS TREE"
if (-not $zxc11) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $zxc188 = Get-CimInstance Win32_Process -Filter "ProcessId = $($zxc11.Id)"
        $zxc189 = if ($zxc188.ParentProcessId) { Get-Process -Id $zxc188.ParentProcessId -ErrorAction SilentlyContinue } else { $null }
        $zxc190 = @("cmd","powershell","pwsh","wscript","cscript","rundll32","mshta","regsvr32")
        if ($zxc189) {
            $zxc191 = $zxc190 -contains $zxc189.ProcessName.ToLower()
            Write-Host ("  Parent : {0} (PID {1})" -f $zxc189.ProcessName, $zxc189.Id) -ForegroundColor $(if ($zxc191) { "Red" } else { "White" })
            if ($zxc191) { $zxc5 += "Minecraft launched from $($zxc189.ProcessName)" }
        } else { Write-Host "  Parent : Unknown" -ForegroundColor Gray }
        $zxc192 = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $zxc11.Id }
        if ($zxc192) {
            foreach ($zxc193 in $zxc192) {
                $zxc159 = Get-Process -Id $zxc193.ProcessId -ErrorAction SilentlyContinue
                if ($zxc159) {
                    $zxc191 = $zxc190 -contains $zxc159.ProcessName.ToLower()
                    Write-Host ("  Child  : {0} (PID {1}) {2}" -f $zxc159.ProcessName, $zxc159.Id, $zxc159.StartTime.ToString("HH:mm:ss")) -ForegroundColor $(if ($zxc191) { "Red" } else { "White" })
                    if ($zxc191) { $zxc5 += "Suspicious child of Minecraft: $($zxc159.ProcessName)" }
                }
            }
        } else { Write-Host "  Child  : None" -ForegroundColor Green }
    } catch { Write-Host "  Error during process tree analysis" -ForegroundColor Red }
}

Write-Pink "`nJAVAW LOADED DLLs"
if (-not $zxc11) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $zxc194 = @(
            '\windows\system32\','\windows\syswow64\','\windows\microsoft.net\','\windows\winsxs\',
            '\jre\','\jdk\','\java\','\openjdk\','\zulu\','\graalvm\','\liberica\','\corretto\',
            '\temurin\','\adoptium\','\semeru\','\minecraft launcher\','\.minecraft\','\minecraft\',
            '\multimc\','\prismlauncher\','\atlauncher\',
            'nvidia','nvd3d','nvcuda','nvoglv','ig4icd','igdumd','amdvlk','atig6pxx','d3d','dxgi','opengl',
            'discord','steam','gameoverlayrenderer','msvcp','msvcr','vcruntime','ucrtbase',
            'kernel32','ntdll','user32','gdi32','shell32','advapi32','ole32','oleaut32','comctl32','comdlg32',
            'ws2_32','wininet','winhttp','crypt32','bcrypt','sechost','rpcrt4','shlwapi','wldap32',
            'dwmapi','uxtheme','imm32','msctf','textinputframework','coreclr','clr.dll','clrjit',
            'lwjgl','openal','jinput','jna-','xaudio','audioses','mmdevapi'
        )
        $zxc195 = $zxc11.Modules | Sort-Object FileName
        $zxc48 = @()
        foreach ($zxc182 in $zxc195) {
            $zxc196 = $zxc182.FileName.ToLower()
            $zxc197 = $false
            foreach ($zxc50 in $zxc194) { if ($zxc196 -like "*$zxc50*") { $zxc197 = $true; break } }
            if (-not $zxc197) { $zxc48 += $zxc182 }
        }
        Write-Host "  Total DLLs: $($zxc195.Count)" -ForegroundColor White
        if ($zxc48.Count -eq 0) { Write-Host "  Unexpected: None" -ForegroundColor Green }
        else {
            Write-Host "  Unexpected: $($zxc48.Count) (can false flag)" -ForegroundColor Red
            foreach ($zxc198 in $zxc48) { Write-Host ("    {0,-32} {1}" -f $zxc198.ModuleName, $zxc198.FileName) -ForegroundColor White }
            $zxc5 += "Unexpected DLLs in javaw ($($zxc48.Count))"
        }
    } catch { Write-Host "  Error reading DLL list" -ForegroundColor Red }
}

Write-Pink "`nBAM SINCE MC LAUNCH"
if (-not $zxc11) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $zxc199 = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
        if (-not (Test-Path $zxc199)) { $zxc199 = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings" }
        if (-not (Test-Path $zxc199)) { Write-Host "  BAM registry key not found" -ForegroundColor White }
        else {
            $zxc200 = @()
            foreach ($zxc201 in (Get-ChildItem -Path $zxc199 -ErrorAction SilentlyContinue)) {
                $zxc202 = Get-ItemProperty -Path $zxc201.PSPath -ErrorAction SilentlyContinue
                if (-not $zxc202) { continue }
                foreach ($zxc203 in $zxc202.PSObject.Properties) {
                    if ($zxc203.Name -match '^PS|SequenceNumber|Version') { continue }
                    if ($zxc203.Value -isnot [byte[]] -or $zxc203.Value.Length -lt 8) { continue }
                    try {
                        $zxc204 = [BitConverter]::ToInt64($zxc203.Value, 0)
                        if ($zxc204 -le 0) { continue }
                        $zxc205 = [datetime]::FromFileTime($zxc204)
                        if ($zxc205 -lt $zxc11.StartTime) { continue }
                        $zxc206 = Split-Path ($zxc203.Name -replace '\\Device\\HarddiskVolume\d+','') -Leaf
                        $zxc200 += [PSCustomObject]@{ Name=$zxc206; LastRun=$zxc205 }
                    } catch { continue }
                }
            }
            $zxc200 = $zxc200 | Where-Object { $_.Name -notmatch '^javaw?\.exe$' } | Sort-Object LastRun -Descending
            if (-not $zxc200) { Write-Host "  No other executables ran since MC launch" -ForegroundColor Green }
            else {
                Write-Host "  Executables since MC launch: $($zxc200.Count)" -ForegroundColor White
                foreach ($zxc111 in $zxc200) {
                    $zxc207 = (($zxc111.LastRun - $zxc11.StartTime).TotalSeconds -le 120)
                    $zxc208 = if ($zxc207) { " [within 2min]" } else { "" }
                    Write-Host ("    {0,-34} {1}{2}" -f $zxc111.Name, $zxc111.LastRun.ToString("HH:mm:ss"), $zxc208) -ForegroundColor $(if ($zxc207) { "Red" } else { "White" })
                }
            }
        }
    } catch { Write-Host "  Error reading BAM entries" -ForegroundColor Red }
}

Write-Pink "`nLATE JAR INJECTION"
if (-not $zxc11) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
elseif (-not (Test-Path $zxc12)) { Write-Host "  Mods folder not found" -ForegroundColor Gray }
else {
    try {
        $zxc209 = $zxc11.StartTime.AddMinutes(2)
        $zxc210 = @(Get-ChildItem -Path $zxc12 -Filter *.jar -Recurse -Force -ErrorAction SilentlyContinue)
        $zxc211 = @($zxc210 | Where-Object { $_.LastAccessTime -gt $zxc209 })
        Write-Host ("  MC started: {0} | grace until {1} | JARs: {2}" -f $zxc11.StartTime.ToString("HH:mm:ss"), $zxc209.ToString("HH:mm:ss"), $zxc210.Count) -ForegroundColor White
        if ($zxc211.Count -eq 0) { Write-Host "  No late-loaded JARs" -ForegroundColor Green }
        else {
            Write-Host "  Late-loaded JARs: $($zxc211.Count)" -ForegroundColor Red
            foreach ($zxc89 in ($zxc211 | Sort-Object LastAccessTime -Descending)) {
                Write-Host ("    {0} | Accessed: {1}" -f $zxc89.Name, $zxc89.LastAccessTime.ToString("HH:mm:ss")) -ForegroundColor White
            }
            $zxc5 += "Late-loaded JARs ($($zxc211.Count))"
        }
    } catch { Write-Host "  Error during injection check" -ForegroundColor Red }
}

Write-Pink "`nMODS FOLDER FILES"
if (-not (Test-Path $zxc12)) { Write-Host "  Mods folder not found" -ForegroundColor Gray }
else {
    $zxc212 = @(Get-ChildItem -Path $zxc12 -Recurse -Force -ErrorAction SilentlyContinue)
    $zxc213 = @(); $zxc214 = @(); $zxc215 = @()
    $zxc216 = @(".exe",".bat",".cmd",".scr",".vbs",".js",".ps1",".dll",".com",".pif")
    foreach ($zxc120 in $zxc212) {
        $zxc121 = $zxc120.Attributes -band [System.IO.FileAttributes]::Hidden
        $zxc217 = $zxc120.Attributes -band [System.IO.FileAttributes]::System
        if ($zxc121) { $zxc213 += $zxc120 }
        if ($zxc217) { $zxc214 += $zxc120 }
        if ($zxc216 -contains $zxc120.Extension) { $zxc215 += $zxc120 }
    }
    Write-Host "  Total files: $($zxc212.Count)" -ForegroundColor White
    if ($zxc213.Count -gt 0) { Write-Host "  Hidden: $($zxc213.Count)" -ForegroundColor Red; $zxc213 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $zxc5 += "Hidden files in mods folder ($($zxc213.Count))" }
    else { Write-Host "  Hidden: None" -ForegroundColor Green }
    if ($zxc214.Count -gt 0) { Write-Host "  System: $($zxc214.Count)" -ForegroundColor Red; $zxc214 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $zxc6 += "System files in mods folder ($($zxc214.Count))" }
    else { Write-Host "  System: None" -ForegroundColor Green }
    if ($zxc215.Count -gt 0) { Write-Host "  Executables: $($zxc215.Count)" -ForegroundColor Red; $zxc215 | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $zxc5 += "Executables in mods folder ($($zxc215.Count))" }
    else { Write-Host "  Executables: None" -ForegroundColor Green }
}

Write-Pink "`nBAM EXECUTION HISTORY"
try {
    $zxc218 = @{}
    foreach ($zxc219 in [System.IO.DriveInfo]::GetDrives()) {
        $zxc220 = $zxc219.Name.Substring(0, 2); $zxc221 = New-Object System.Text.StringBuilder 520
        if ([ConsoleHelper]::QueryDosDevice($zxc220, $zxc221, 520) -gt 0) { $zxc218[$zxc221.ToString()] = $zxc220 }
    }
    $zxc222 = @{}; foreach ($zxc219 in [System.IO.DriveInfo]::GetDrives()) { $zxc222[$zxc219.Name.Substring(0, 2).ToUpper()] = $zxc219.DriveType }
    $zxc223 = @()
    foreach ($zxc224 in @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings", "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings")) {
        if (-not (Test-Path $zxc224)) { continue }
        foreach ($zxc225 in (Get-ChildItem $zxc224)) {
            foreach ($zxc140 in $zxc225.GetValueNames()) {
                if ($zxc140 -in @("Version","SequenceNumber")) { continue }
                $zxc226 = $zxc225.GetValue($zxc140)
                if ($zxc226 -is [byte[]] -and $zxc226.Length -ge 8) {
                    $zxc204 = [BitConverter]::ToInt64($zxc226, 0)
                    if ($zxc204 -le 0) { continue }
                    $zxc227 = $zxc140
                    foreach ($zxc228 in $zxc218.Keys) { if ($zxc227.StartsWith($zxc228 + '\', [StringComparison]::OrdinalIgnoreCase)) { $zxc227 = $zxc218[$zxc228] + $zxc227.Substring($zxc228.Length); break } }
                    $zxc223 += [PSCustomObject]@{ Time=[DateTime]::FromFileTimeUtc($zxc204).ToLocalTime(); Path=$zxc227 }
                }
            }
        }
    }
    if ($zxc223.Count -eq 0) { Write-Host "  BAM is empty or unavailable" -ForegroundColor Red; $zxc6 += "BAM empty" }
    else {
        $zxc223 = @($zxc223 | Where-Object { $_.Path -match '^[A-Za-z]:\\' } | Sort-Object Time -Descending)
        Write-Host ("  Entries : {0} (oldest {1})" -f $zxc223.Count, ($zxc223 | Select-Object -Last 1).Time.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        $zxc229 = ($zxc223 | Select-Object -Last 1).Time
        if ($zxc33 -and $zxc229 -gt $zxc33.AddDays(7)) {
            Write-Host ("  BAM looks cleared : oldest entry {0}, Windows installed {1}" -f $zxc229.ToString("yyyy-MM-dd"), $zxc33.ToString("yyyy-MM-dd")) -ForegroundColor Red
            $zxc5 += "BAM looks cleared (oldest entry $($zxc229.ToString('yyyy-MM-dd')), installed $($zxc33.ToString('yyyy-MM-dd')))"
        }
        $zxc230 = @(); $zxc231 = @()
        foreach ($zxc198 in $zxc223) {
            $zxc96 = $zxc198.Path.Substring(0, 2).ToUpper()
            $zxc45 = "ok"
            if (-not (Test-Path -LiteralPath $zxc198.Path)) { $zxc45 = if ($zxc222.ContainsKey($zxc96)) { "DELETED" } else { "DRIVE GONE" } }
            elseif ($zxc222[$zxc96] -eq "Removable") { $zxc45 = "ON USB" }
            $zxc198 | Add-Member -NotePropertyName Status -NotePropertyValue $zxc45 -Force
            if ($zxc45 -in @("DELETED","DRIVE GONE") -and $zxc198.Path -notmatch '\\Windows\\') { $zxc230 += $zxc198 }
            if ($zxc45 -in @("DRIVE GONE","ON USB")) { $zxc231 += $zxc198 }
        }
        Write-Host "  Last 25 executions" -ForegroundColor White
        foreach ($zxc198 in ($zxc223 | Select-Object -First 25)) {
            $zxc43 = if ($zxc198.Path -match $zxc13) { "Red" } elseif ($zxc198.Status -ne "ok") { "Red" } else { "Gray" }
            Write-Host ("    {0}  {1,-10} {2}" -f $zxc198.Time.ToString("MM-dd HH:mm:ss"), $zxc198.Status, $zxc198.Path) -ForegroundColor $zxc43
        }
        foreach ($zxc198 in @($zxc223 | Where-Object { $_.Path -match $zxc13 } | Select-Object -First 10)) { Write-Host ("  Cheat name in BAM : {0}  {1}" -f $zxc198.Time.ToString("MM-dd HH:mm"), $zxc198.Path) -ForegroundColor Red; $zxc5 += "BAM match $($zxc198.Path)" }
        if ($zxc231.Count -gt 0) { Write-Host "  Run from removable/disconnected drive : $($zxc231.Count)" -ForegroundColor Red; $zxc6 += "Programs run from removable drive ($($zxc231.Count))" }
        if ($zxc230.Count -gt 0) {
            Write-Host "  Executed files no longer on disk : $($zxc230.Count)" -ForegroundColor Red
            foreach ($zxc198 in ($zxc230 | Select-Object -First 25)) { Write-Host ("    {0}  {1,-10} {2}" -f $zxc198.Time.ToString("MM-dd HH:mm"), $zxc198.Status, $zxc198.Path) -ForegroundColor White }
        } else { Write-Host "  All executed files still exist" -ForegroundColor Green }
    }
} catch { Write-Host "  Error reading BAM history" -ForegroundColor Red }

Write-Pink "`nSUSPICIOUS PROCESSES"
try {
    $zxc232 = @(Get-CimInstance Win32_Process)
    $zxc233 = $false
    foreach ($zxc51 in $zxc232) {
        $zxc234 = ($zxc51.Name -replace '\.exe$', '')
        $zxc208 = $null
        if ($zxc234 -match $zxc14) { $zxc208 = "Remote access" }
        elseif ($zxc234 -match $zxc15) { $zxc208 = "Debug/inject tool" }
        elseif ($zxc234 -match $zxc16) { $zxc208 = "Virtualization" }
        elseif ($zxc234 -match $zxc13) { $zxc208 = "Cheat name" }
        if ($zxc208) { $zxc233 = $true; Write-Host ("  {0} : {1} (PID {2}) {3}" -f $zxc208, $zxc51.Name, $zxc51.ProcessId, $zxc51.ExecutablePath) -ForegroundColor Red; $zxc5 += "$zxc208 $($zxc51.Name)" }
    }
    foreach ($zxc235 in (Get-Process | Where-Object { $_.MainWindowTitle })) {
        if ($zxc235.MainWindowTitle -match $zxc13 -or $zxc235.MainWindowTitle -match $zxc15) { $zxc233 = $true; Write-Host ("  Window title match : '{0}' ({1})" -f $zxc235.MainWindowTitle, $zxc235.ProcessName) -ForegroundColor Red; $zxc5 += "Window title match $($zxc235.MainWindowTitle)" }
    }
    $zxc236 = '\\(Temp|Downloads|Desktop|Public|\$Recycle\.Bin)\\'
    $zxc237 = @($zxc232 | Where-Object { $_.ExecutablePath -and $_.ExecutablePath -match $zxc236 -and $_.ProcessId -ne $PID })
    if ($zxc237.Count -gt 0) {
        $zxc233 = $true
        Write-Host "  Running from Temp/Downloads/Desktop : $($zxc237.Count)" -ForegroundColor Red
        foreach ($zxc51 in ($zxc237 | Select-Object -First 15)) { Write-Host ("    {0} [{1}] {2}" -f $zxc51.Name, (Get-Sig $zxc51.ExecutablePath), $zxc51.ExecutablePath) -ForegroundColor White }
    }
    if (-not $zxc233) { Write-Host "  No suspicious processes" -ForegroundColor Green }
} catch { Write-Host "  Error reading processes" -ForegroundColor Red }

Write-Pink "`nBOOT SECURITY AND DRIVERS"
try {
    $zxc238 = (bcdedit /enum '{current}' 2>&1 | Out-String)
    if ($zxc238 -match '(?im)^\s*testsigning\s+(Yes|\S*\u0414\u0430)') { Write-Host "  Test Signing : ON" -ForegroundColor Red; $zxc5 += "Test signing is on" } else { Write-Host "  Test Signing : Off" -ForegroundColor Green }
    if ($zxc238 -match '(?im)^\s*nointegritychecks\s+(Yes|\S*\u0414\u0430)') { Write-Host "  Integrity Checks : DISABLED" -ForegroundColor Red; $zxc5 += "Driver integrity checks disabled" }
    try { $zxc239 = Confirm-SecureBootUEFI -ErrorAction Stop; Write-Host "  Secure Boot : $(if ($zxc239) { 'On' } else { 'Off' })" -ForegroundColor $(if ($zxc239) { "Green" } else { "White" }) } catch { Write-Host "  Secure Boot : Not supported" -ForegroundColor Gray }
    $zxc240 = @(Get-CimInstance Win32_SystemDriver)
    $zxc241 = @($zxc240 | Where-Object { $_.Name -match $zxc17 -or ([IO.Path]::GetFileNameWithoutExtension(([string]$_.PathName).Trim('"')) -match $zxc17) })
    if ($zxc241.Count -gt 0) { foreach ($zxc38 in $zxc241) { Write-Host ("  Known cheat/vulnerable driver : {0} [{1}] {2}" -f $zxc38.Name, $zxc38.State, $zxc38.PathName) -ForegroundColor Red; $zxc5 += "Vulnerable driver $($zxc38.Name)" } }
    else { Write-Host "  Vulnerable drivers : None" -ForegroundColor Green }
    $zxc242 = 0
    foreach ($zxc38 in @($zxc240 | Where-Object { $_.State -eq "Running" -and $_.PathName -and $_.PathName -notmatch '(?i)\\system32\\drivers\\|\\DriverStore\\|\\SystemRoot\\system32\\drivers\\' } | Select-Object -First 80)) {
        $zxc183 = ([string]$zxc38.PathName) -replace '^\\\?\?\\', '' -replace '^\\SystemRoot', $env:SystemRoot -replace '^"|"$', ''
        if (-not (Test-Path -LiteralPath $zxc183)) { continue }
        $zxc243 = Get-Sig $zxc183
        if ($zxc243 -ne "Valid") { $zxc242++; Write-Host ("  Driver not validly signed : {0} [{1}] {2}" -f $zxc38.Name, $zxc243, $zxc183) -ForegroundColor Red; $zxc6 += "Unsigned driver $($zxc38.Name)" }
    }
    if ($zxc242 -eq 0) { Write-Host "  Unsigned drivers : None" -ForegroundColor Green }
} catch { Write-Host "  Error reading boot/driver info" -ForegroundColor Red }

Write-Pink "`nCOMMAND HISTORY"
$zxc244 = @(
    "powershell -enc","-encodedcommand","certutil -decode","certutil -urlcache",
    "bitsadmin /transfer","Invoke-WebRequest","irm ","curl -o","wget -O",
    "rundll32","regsvr32","mshta","wscript","cscript",
    "taskkill /f","Stop-Process -Force","LoadLibrary","VirtualAlloc","WriteProcessMemory",
    "reg add","reg delete","wevtutil","bcdedit","attrib +h","attrib +s","cipher /w",
    "inject","bypass","crack","trainer","aimbot","wallhack","autoclicker",
    "IEX","Invoke-Expression","Start-BitsTransfer","DownloadString","DownloadFile","FromBase64String"
)
$zxc245 = if ($zxc11) { $zxc11.StartTime } else { (Get-Date).AddHours(-2) }
Write-Host ("  Window: since {0}" -f $zxc245.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
$zxc246 = @()
if (Test-Path $zxc132) {
    $zxc133 = Get-Item $zxc132 -Force
    if ($zxc133.LastWriteTime -ge $zxc245) {
        $zxc99 = @(Get-Content $zxc132 -ErrorAction SilentlyContinue | Select-Object -Last 40)
        foreach ($zxc100 in $zxc99) {
            if ([string]::IsNullOrWhiteSpace($zxc100)) { continue }
            if ($zxc100 -match "Y-sysinfo|check\.ps1") { continue }
            foreach ($zxc10 in $zxc244) {
                if ($zxc100 -like "*$zxc10*") { $zxc246 += [PSCustomObject]@{ Pattern=$zxc10; Cmd=$zxc100.Trim() }; break }
            }
        }
        if ($zxc246.Count -gt 0) {
            Write-Host "  Suspicious PS commands: $($zxc246.Count)" -ForegroundColor Red
            foreach ($zxc111 in $zxc246) {
                $zxc193 = $zxc111.Cmd
                Write-Host ("    [{0}] {1}" -f $zxc111.Pattern, $zxc193) -ForegroundColor White
            }
            $zxc5 += "Suspicious PowerShell commands ($($zxc246.Count))"
        } else { Write-Host "  PowerShell history: clean" -ForegroundColor Green }
    } else { Write-Host "  PowerShell history: not written since window start" -ForegroundColor Green }
} else { Write-Host "  PowerShell history: file not found" -ForegroundColor White }

$zxc247 = @()
try {
    $zxc248 = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4688; StartTime=$zxc245} -MaxEvents 200 -ErrorAction SilentlyContinue
    if ($zxc248) {
        foreach ($zxc82 in $zxc248) {
            if ($zxc82.TimeCreated -ge $zxc22) { continue }
            $zxc249 = ($zxc82.Message -split "`n" | Select-String "Process Command Line|New Process Name")
            $zxc250 = ($zxc249 -join " ").Trim()
            if (-not $zxc250) { continue }
            if ($zxc250 -match 'bcdedit(\.exe)?"?\s+/enum') { continue }
            foreach ($zxc10 in $zxc244) { if ($zxc250 -like "*$zxc10*") { $zxc247 += $zxc250; break } }
        }
        if ($zxc247.Count -gt 0) {
            Write-Host "  Suspicious process creations: $($zxc247.Count)" -ForegroundColor Red
            $zxc247 | Select-Object -Unique -First 15 | ForEach-Object {
                $zxc193 = $_
                Write-Host "    $zxc193" -ForegroundColor White
            }
            $zxc5 += "Suspicious process creations ($($zxc247.Count))"
        } else { Write-Host "  Process creation events: clean" -ForegroundColor Green }
    } else { Write-Host "  Process creation events: not available (audit off)" -ForegroundColor White }
} catch { Write-Host "  Process creation events: not available" -ForegroundColor White }

try {
    $zxc251 = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-PowerShell/Operational"; Id=4104; StartTime=$zxc245} -MaxEvents 100 -ErrorAction SilentlyContinue
    if ($zxc251) {
        $zxc252 = @()
        foreach ($zxc82 in $zxc251) {
            $zxc182 = $zxc82.Message
            if ($zxc82.TimeCreated -ge $zxc22) { continue }
            if ($zxc182 -match "Y-sysinfo|check\.ps1") { continue }
            foreach ($zxc10 in $zxc244) { if ($zxc182 -like "*$zxc10*") { $zxc252 += $zxc82; break } }
        }
        if ($zxc252.Count -gt 0) {
            Write-Host "  Suspicious script blocks: $($zxc252.Count)" -ForegroundColor Red
            foreach ($zxc82 in ($zxc252 | Select-Object -First 10)) {
                Write-Host ("    {0} | {1}" -f $zxc82.TimeCreated.ToString("HH:mm:ss"), (($zxc82.Message -split "`n")[0]).Trim()) -ForegroundColor White
            }
            $zxc5 += "Suspicious PowerShell script blocks ($($zxc252.Count))"
        } else { Write-Host "  Script block logs: clean" -ForegroundColor Green }
    }
} catch {}

function Invoke-Ps4104Hunt {
$zxc253 = 0
$ErrorActionPreference = 'Stop'
$zxc77 = 'Microsoft-Windows-PowerShell/Operational'
$zxc254 = Join-Path $zxc18 'PWSHOperational.txt'
if (-not (Test-Path -LiteralPath $zxc18)) { New-Item -ItemType Directory -Path $zxc18 -Force | Out-Null }

function _s([int[]]$zxc193) { -join ($zxc193 | ForEach-Object { [char]$_ }) }

function Test-IsDefenderModuleNoise {
  param([string]$zxc255)
  if ([string]::IsNullOrWhiteSpace($zxc255)) { return $false }

  if ($zxc255.Length -lt 6000) {
    if ($zxc255 -match '(?im)^\s*(Set-MpPreference|Add-MpPreference|Remove-MpPreference)\s+') { return $false }
    if ($zxc255 -match '(?i)(Set|Add)-MpPreference[^`{]{0,500}?(-DisableRealtimeMonitoring|-ExclusionPath|-ExclusionProcess)\s+\$?(true|\w|:)') { return $false }
  }

  if ($zxc255 -match '__cmdletization|MSFT_MpPreference|GeneratedTypes\.MpPreference') { return $true }
  if ($zxc255 -match 'function\s+(Set|Remove|Add|Get)-MpPreference\s*\{') { return $true }
  if ($zxc255 -match 'Microsoft\.PowerShell\.Cmdletization\.MethodParameter') { return $true }
  if ($zxc255 -match "Parameter\(ParameterSetName='(Remove2|Set0|Add1)'\)" -and $zxc255 -match '\$\{DisableRealtimeMonitoring\}' -and $zxc255 -match '\[ValidateNotNull') { return $true }

  $zxc256 = ([regex]::Matches($zxc255, '\[Parameter\(')).Count
  if ($zxc256 -ge 6 -and $zxc255 -match 'DisableRealtimeMonitoring' -and $zxc255 -match '(ExclusionPath|DisableScriptScanning)') { return $true }

  return $false
}

function Test-IsWindowsMaintenanceNoise {
  param([string]$zxc255)
  if ($zxc255 -match 'CL_LocalizationData|Get-UserTSHistoryPath|Update-DiagReport|Import-LocalizedData.*CL_Localization') { return $true }
  if ($zxc255 -match 'Copyright \(c\) Microsoft Corporation' -and $zxc255 -match 'Get-FolderSize|Delete-OldFolders') { return $true }
  return $false
}

function Get-BlockVerdict {
  param([string]$zxc255, [int]$zxc257)
  if (Test-IsDefenderModuleNoise -Script $zxc255) { return 'NOISE-DEFENDER' }
  if (Test-IsWindowsMaintenanceNoise -Script $zxc255) { return 'NOISE-WINDOWS' }
  if ($zxc255.Length -lt 150 -and $zxc255 -match '(?i)^\s*(\$[mg]\=|New-Object System\.IO\.(MemoryStream|Compression\.GzipStream))') { return 'NOISE-FRAG' }
  if ($zxc255 -match '(?i)Y-ClipBoard|MemScan::Dump|cbdhsvc|Done sweety') { return 'YOUR-TOOL' }
  if ($zxc255 -match 'amsiInitFailed') {
    $zxc258 = ($zxc255 -match '(?i)EtwEventWrite|EnableScriptBlockLogging|PSEtwLogProvider')
    $zxc259 = ($zxc255 -match '(?i)DownloadData') -or ($zxc255 -match 'Assembly' -and $zxc255 -match '::Load')
    if ($zxc258 -and $zxc259) { return 'CRITICAL-LOADER' }
  }
  if (($zxc255 -match '(?i)-bxor') -and ($zxc255 -match 'GzipStream') -and ($zxc255 -match 'ScriptBlock' -and $zxc255 -match '::Create')) { return 'FILELESS-STAGER' }
  if ($zxc255 -match '(?i)clicker\.exe|Sapphire/raw') { return 'CHEAT-CLICKER' }
  if ($zxc257 -ge 20) { return 'REVIEW-HIGH' }
  if ($zxc257 -ge 10) { return 'REVIEW' }
  return 'LOW'
}

$zxc260 = @(
  @{ W = 5; P = @(
      (_s 70,114,111,109,66,97,115,101,54,52,83,116,114,105,110,103)
      (_s 71,122,105,112,83,116,114,101,97,109)
      (_s 68,101,102,108,97,116,101,83,116,114,101,97,109)
      (_s 98,120,111,114)
      (_s 73,110,118,111,107,101,45,69,120,112,114,101,115,115,105,111,110)
      (_s 92,98,73,69,88,92,98)
      (_s 73,110,118,111,107,101,45,67,111,109,109,97,110,100)
      (_s 69,110,99,111,100,101,100,67,111,109,109,97,110,100)
      (_s 45,101,110,99,92,98)
      (_s 73,79,92,46,77,101,109,111,114,121,83,116,114,101,97,109)
      (_s 67,111,110,118,101,114,116,92,93,58,58,70,114,111,109,66,97,115,101,54,52)
      (_s 73,79,92,46,67,111,109,112,114,101,115,115,105,111,110)
      (_s 45,98,120,111,114)
      (_s 105,99,109,92,98)
      (_s 45,69,110,99,111,100,101,100,67,111,109,109,97,110,100)
      (_s 45,101,92,115,43,91,65,45,90,97,45,122,48,45,57,43,47,61,93,123,52,48,44,125)
    ) }
  @{ W = 5; P = @(
      (_s 78,101,116,92,46,87,101,98,67,108,105,101,110,116)
      (_s 87,101,98,67,108,105,101,110,116)
      (_s 68,111,119,110,108,111,97,100,83,116,114,105,110,103)
      (_s 68,111,119,110,108,111,97,100,70,105,108,101)
      (_s 68,111,119,110,108,111,97,100,68,97,116,97)
      (_s 73,110,118,111,107,101,45,87,101,98,82,101,113,117,101,115,116)
      (_s 73,110,118,111,107,101,45,82,101,115,116,77,101,116,104,111,100)
      (_s 92,98,105,119,114,92,98)
      (_s 92,98,105,114,109,92,98)
      (_s 84,99,112,67,108,105,101,110,116)
      (_s 66,105,116,115,84,114,97,110,115,102,101,114)
      (_s 83,116,97,114,116,45,66,105,116,115,84,114,97,110,115,102,101,114)
      (_s 104,116,116,112,58,47,47)
      (_s 104,116,116,112,115,58,47,47)
      (_s 119,103,101,116,92,98)
      (_s 99,117,114,108,92,98)
      (_s 87,101,98,82,101,113,117,101,115,116)
    ) }
  @{ W = 8; P = @(
      (_s 65,109,115,105,85,116,105,108,115)
      (_s 97,109,115,105,73,110,105,116,70,97,105,108,101,100)
      (_s 97,109,115,105,67,111,110,116,101,120,116)
      (_s 97,109,115,105,83,101,115,115,105,111,110)
      (_s 69,116,119,69,118,101,110,116,87,114,105,116,101)
      (_s 80,83,69,116,119,76,111,103,80,114,111,118,105,100,101,114)
      (_s 82,101,102,108,101,99,116,105,111,110,92,46,69,109,105,116)
      (_s 101,116,119,80,114,111,118,105,100,101,114)
    ) }
  @{ W = 8; P = @(
      (_s 86,105,114,116,117,97,108,65,108,108,111,99)
      (_s 86,105,114,116,117,97,108,80,114,111,116,101,99,116)
      (_s 87,114,105,116,101,80,114,111,99,101,115,115,77,101,109,111,114,121)
      (_s 67,114,101,97,116,101,82,101,109,111,116,101,84,104,114,101,97,100)
      (_s 67,114,101,97,116,101,84,104,114,101,97,100)
      (_s 78,116,67,114,101,97,116,101,84,104,114,101,97,100,69,120)
      (_s 79,112,101,110,80,114,111,99,101,115,115)
      (_s 81,117,101,117,101,85,115,101,114,65,80,67)
      (_s 107,101,114,110,101,108,51,50,92,46,100,108,108)
      (_s 110,116,100,108,108,92,46,100,108,108)
      (_s 68,108,108,73,109,112,111,114,116)
      (_s 85,110,109,97,110,97,103,101,100,70,117,110,99,116,105,111,110,80,111,105,110,116,101,114)
    ) }
  @{ W = 6; P = @(
      (_s 65,100,100,45,84,121,112,101)
      (_s 82,101,102,108,101,99,116,105,111,110,92,46,65,115,115,101,109,98,108,121)
      (_s 65,115,115,101,109,98,108,121,93,58,58,76,111,97,100)
      (_s 76,111,97,100,92,40)
      (_s 76,111,97,100,70,105,108,101)
      (_s 76,111,97,100,70,114,111,109)
      (_s 71,101,116,68,101,108,101,103,97,116,101,70,111,114,70,117,110,99,116,105,111,110,80,111,105,110,116,101,114)
      (_s 68,121,110,97,109,105,99,73,110,118,111,107,101)
      (_s 77,97,114,115,104,97,108,58,58)
    ) }
  @{ W = 6; P = @(
      (_s 78,101,119,45,83,101,114,118,105,99,101)
      (_s 115,99,104,116,97,115,107,115)
      (_s 83,99,104,101,100,117,108,101,100,84,97,115,107)
      (_s 82,101,103,105,115,116,101,114,45,83,99,104,101,100,117,108,101,100,84,97,115,107)
      (_s 67,117,114,114,101,110,116,86,101,114,115,105,111,110,92,92,82,117,110)
      (_s 83,101,116,45,77,80,80,114,101,102,101,114,101,110,99,101)
      (_s 68,105,115,97,98,108,101,82,101,97,108,116,105,109,101,77,111,110,105,116,111,114,105,110,103)
      (_s 69,120,99,108,117,115,105,111,110,80,97,116,104)
      (_s 67,111,109,109,97,110,100,76,105,110,101,69,118,101,110,116,67,111,110,115,117,109,101,114)
      (_s 95,95,69,118,101,110,116,70,105,108,116,101,114)
      (_s 78,101,119,45,78,101,116,70,105,114,101,119,97,108,108,82,117,108,101)
    ) }
  @{ W = 4; P = @(
      (_s 77,105,109,105,107,97,116,122)
      (_s 73,110,118,111,107,101,45,77,105,109,105,107,97,116,122)
      (_s 115,101,107,117,114,108,115,97)
      (_s 108,115,97,100,117,109,112)
      (_s 80,111,119,101,114,86,105,101,119)
      (_s 83,104,97,114,112,72,111,117,110,100)
      (_s 66,108,111,111,100,72,111,117,110,100)
      (_s 82,117,98,101,117,115)
      (_s 83,97,102,101,116,121,75,97,116,122)
      (_s 71,101,116,45,65,68,85,115,101,114)
      (_s 71,101,116,45,68,111,109,97,105,110)
      (_s 119,104,111,97,109,105,92,115,43,47,97,108,108)
    ) }
  @{ W = 5; P = @(
      (_s 109,115,104,116,97)
      (_s 114,117,110,100,108,108,51,50)
      (_s 114,101,103,115,118,114,51,50)
      (_s 99,101,114,116,117,116,105,108)
      (_s 98,105,116,115,97,100,109,105,110)
      (_s 119,109,105,99,92,98)
      (_s 99,109,115,116,112)
      (_s 73,110,115,116,97,108,108,85,116,105,108)
      (_s 77,83,66,117,105,108,100)
      (_s 45,110,111,112,92,98)
      (_s 45,119,92,115,43,104,105,100,100,101,110)
      (_s 45,87,105,110,100,111,119,83,116,121,108,101,92,115,43,72,105,100,100,101,110)
      (_s 83,116,97,114,116,45,80,114,111,99,101,115,115)
      (_s 99,109,100,92,46,101,120,101,92,115,43,47,99)
      (_s 99,109,100,92,115,43,47,99)
    ) }
  @{ W = 4; P = @(
      (_s 92,91,99,104,97,114,92,93,92,115,42,92,100,43)
      (_s 45,106,111,105,110,92,115,42,92,40)
      (_s 66,105,116,67,111,110,118,101,114,116,101,114)
      (_s 84,101,120,116,92,46,69,110,99,111,100,105,110,103)
      (_s 71,101,116,83,116,114,105,110,103,92,40)
      (_s 83,101,99,117,114,101,83,116,114,105,110,103,84,111,66,83,84,82)
      (_s 80,116,114,84,111,83,116,114,105,110,103,65,117,116,111)
      (_s 84,111,66,121,116,101)
      (_s 84,111,73,110,116,49,54)
    ) }
)

$zxc49 = foreach ($zxc62 in $zxc260) { $zxc62.P }
$zxc261 = ($zxc49 | Select-Object -Unique) -join '|'

$zxc262 = Get-WinEvent -ListLog $zxc77 -ErrorAction SilentlyContinue
if ($zxc253 -gt 0) {
  $zxc263 = "*[System[EventID=4104 and TimeCreated[timediff(@SystemTime) <= $([int64]$zxc253 * 86400000)]]]"
  $zxc264 = "last $zxc253 days"
} else {
  $zxc263 = '*[System[EventID=4104]]'
  $zxc264 = 'all days in log'
}

$zxc265 = @(Get-WinEvent -LogName $zxc77 -FilterXPath $zxc263 -ErrorAction SilentlyContinue)

$zxc266 = @()
if ($zxc262) {
  $zxc266 += ("enabled={0} mode={1} size={2} records, max {3:N0} MB" -f $zxc262.IsEnabled, $zxc262.LogMode, $zxc262.RecordCount, ($zxc262.MaximumSizeInBytes / 1MB))
}
if ($zxc265.Count -eq 0) {
  $zxc267 = 'empty ({0})' -f $zxc264
  if ($zxc266.Count -gt 0) { $zxc267 += "`r`nlog: " + ($zxc266 -join ' | ') }
  [IO.File]::WriteAllText($zxc254, $zxc267, [Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{ File = $zxc254; Alerts = 0; Review = 0; Enabled = [bool]$zxc262.IsEnabled; Events = $zxc265.Count }
}
$zxc266 += ("scanned 4104 events: {0}" -f $zxc265.Count)
$zxc268 = @($zxc265 | ForEach-Object { $_.TimeCreated } | Sort-Object)
$zxc266 += ("oldest {0:yyyy-MM-dd HH:mm} .. newest {1:yyyy-MM-dd HH:mm}" -f $zxc268[0], $zxc268[$zxc268.Count - 1])
$zxc269 = 'log: ' + ($zxc266 -join ' | ')

$zxc270 = [Security.Cryptography.SHA256]::Create()
$zxc271 = @{}

foreach ($zxc76 in $zxc265) {
  if ($zxc76.ProcessId -eq $PID) { continue }
  if ($zxc76.Properties.Count -ge 3 -and $zxc76.Properties[2].Value) {
    $zxc255 = [string]$zxc76.Properties[2].Value
  } else {
    $zxc255 = [string]$zxc76.Message
  }
  if ([string]::IsNullOrWhiteSpace($zxc255)) { continue }
  if (Test-IsDefenderModuleNoise -Script $zxc255) { continue }
  if (Test-IsWindowsMaintenanceNoise -Script $zxc255) { continue }
  if ($zxc255 -match '(?i)BypassMagister|PWSHOperational') { continue }
  if ($zxc255 -match '(?i)Get-WinEvent' -and $zxc255 -match '4104' -and $zxc255 -match 'FilterXPath') { continue }
  if ($zxc255 -match '\$pattern\s*=\s*@\(' -and $zxc255 -match 'FromBase64String') { continue }
  if ($zxc255 -match 'function _s' -and $zxc255 -match 'byHash') { continue }
  if ($zxc255 -match '(?i)Y-ClipBoard|MemScan::Dump') { continue }
  if ($zxc255 -notmatch $zxc261) { continue }

  $zxc257 = 0
  foreach ($zxc62 in $zxc260) {
    $zxc272 = ($zxc62.P -join '|')
    if ($zxc255 -match ("(?i){0}" -f $zxc272)) { $zxc257 += [int]$zxc62.W }
  }

  $zxc134 = _s 70,114,111,109,66,97,115,101,54,52,83,116,114,105,110,103
  $zxc198 = (_s 71,122,105,112,83,116,114,101,97,109) + '|' + (_s 68,101,102,108,97,116,101,83,116,114,101,97,109) + '|' + (_s 98,120,111,114) + '|' + (_s 92,98,73,69,88,92,98) + '|' + (_s 73,110,118,111,107,101,45,69,120,112,114,101,115,115,105,111,110)
  if ($zxc255 -match ("(?i){0}" -f $zxc134) -and $zxc255 -match ("(?i){0}" -f $zxc198)) { $zxc257 += 10 }
  $zxc193 = (_s 65,109,115,105,85,116,105,108,115) + '|' + (_s 97,109,115,105,73,110,105,116,70,97,105,108,101,100)
  if ($zxc255 -match ("(?i){0}" -f $zxc193)) { $zxc257 += 10 }
  $zxc38 = (_s 86,105,114,116,117,97,108,65,108,108,111,99) + '|' + (_s 87,114,105,116,101,80,114,111,99,101,115,115,77,101,109,111,114,121) + '|' + (_s 67,114,101,97,116,101,82,101,109,111,116,101,84,104,114,101,97,100)
  if ($zxc255 -match ("(?i){0}" -f $zxc38)) { $zxc257 += 10 }

  $zxc273 = ($zxc255 -replace '\s+', ' ').Trim()
  if ($zxc273.Length -gt 4000) { $zxc273 = $zxc273.Substring(0, 4000) }
  $zxc274 = [BitConverter]::ToString($zxc270.ComputeHash([Text.Encoding]::UTF8.GetBytes($zxc273))).Replace('-', '').Substring(0, 16)

  $zxc275 = @([regex]::Matches($zxc255, $zxc261, 'IgnoreCase') | ForEach-Object { $_.Value } | Sort-Object -Unique)
  $zxc276 = $zxc275 -join ', '
  $zxc277 = Get-BlockVerdict -Script $zxc255 -Score $zxc257
  if ($zxc277 -like 'NOISE*') { continue }

  $zxc278 = [pscustomobject]@{
    TimeCreated = [datetime]$zxc76.TimeCreated
    Score       = [int]$zxc257
    Verdict     = [string]$zxc277
    Hash        = [string]$zxc274
    Hits        = [string]$zxc276
    Script      = [string]$zxc255
  }

  if (-not $zxc271.ContainsKey($zxc274)) {
    $zxc271[$zxc274] = New-Object System.Collections.Generic.List[object]
  }
  $zxc271[$zxc274].Add($zxc278)
}

if ($zxc271.Count -eq 0) {
  [IO.File]::WriteAllText($zxc254, 'no hits', [Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{ File = $zxc254; Alerts = 0; Review = 0; Enabled = [bool]$zxc262.IsEnabled; Events = $zxc265.Count }
}

$zxc279 = New-Object System.Collections.Generic.List[object]
foreach ($zxc106 in $zxc271.Keys) {
  $zxc50 = $zxc271[$zxc106]
  $zxc280 = 0
  $zxc98 = $zxc50[0].TimeCreated
  $zxc141  = $zxc50[0].TimeCreated
  $zxc281 = $zxc50[0].Script
  $zxc282 = $zxc50[0].Hits
  foreach ($zxc278 in $zxc50) {
    if ($zxc278.Score -gt $zxc280) { $zxc280 = $zxc278.Score }
    if ($zxc278.TimeCreated -lt $zxc98) { $zxc98 = $zxc278.TimeCreated }
    if ($zxc278.TimeCreated -gt $zxc141) {
      $zxc141 = $zxc278.TimeCreated
      $zxc281 = $zxc278.Script
      $zxc282 = $zxc278.Hits
    }
  }
  $zxc277 = Get-BlockVerdict -Script $zxc281 -Score $zxc280
  $zxc279.Add([pscustomobject]@{
      Count     = $zxc50.Count
      Score     = $zxc280
      Verdict   = $zxc277
      FirstSeen = $zxc98
      LastSeen  = $zxc141
      Hash      = $zxc106
      Hits      = $zxc282
      Script    = $zxc281
    })
}

$zxc283 = @($zxc279.ToArray() | Sort-Object -Property Score -Descending)
for ($zxc284 = 0; $zxc284 -lt $zxc283.Length; ) {
  $zxc89 = $zxc284
  while ($zxc89 -lt $zxc283.Length -and $zxc283[$zxc89].Score -eq $zxc283[$zxc284].Score) { $zxc89++ }
  if ($zxc89 - $zxc284 -gt 1) {
    $zxc285 = @($zxc283[$zxc284..($zxc89 - 1)] | Sort-Object -Property LastSeen -Descending)
    for ($zxc228 = 0; $zxc228 -lt $zxc285.Length; $zxc228++) { $zxc283[$zxc284 + $zxc228] = $zxc285[$zxc228] }
  }
  $zxc284 = $zxc89
}

$zxc221 = New-Object System.Text.StringBuilder
[void]$zxc221.AppendLine('love bypass by BypassMagister')
[void]$zxc221.AppendLine(("host {0} | {1:yyyy-MM-dd HH:mm:ss} | window {2} | blocks {3}" -f $env:COMPUTERNAME, (Get-Date), $zxc264, $zxc283.Length))
[void]$zxc221.AppendLine($zxc269)
[void]$zxc221.AppendLine('verdict: CRITICAL-LOADER / FILELESS-STAGER / CHEAT-CLICKER = real alert | REVIEW* = check | NOISE* filtered out')
[void]$zxc221.AppendLine('')

[void]$zxc221.AppendLine('=== Alerts (review first) ===')
foreach ($zxc20 in $zxc283) {
  if ($zxc20.Verdict -notmatch '^(CRITICAL|FILELESS|CHEAT|REVIEW)') { continue }
  [void]$zxc221.AppendLine((
      '[{0}] x{1} score={2} | {3:yyyy-MM-dd HH:mm} .. {4:yyyy-MM-dd HH:mm} | {5}' -f
      $zxc20.Verdict, $zxc20.Count, $zxc20.Score, $zxc20.FirstSeen, $zxc20.LastSeen, $zxc20.Hits
    ))
}
[void]$zxc221.AppendLine('')

$zxc286 = @($zxc271.Values | ForEach-Object { $_ })
$zxc287 = @($zxc286 | Group-Object -Property { $_.TimeCreated.ToString('yyyy-MM-dd') } | Sort-Object -Property Name -Descending | ForEach-Object {
    $zxc288 = @($_.Group | Where-Object { $_.Verdict -match '^(CRITICAL|FILELESS|CHEAT|REVIEW)' }).Count
    '{0}  kept {1}  alerts {2}' -f $_.Name, $_.Count, $zxc288
  })
[void]$zxc221.AppendLine('=== By day (kept blocks / alerts) ===')
foreach ($zxc54 in $zxc287) { [void]$zxc221.AppendLine($zxc54) }
[void]$zxc221.AppendLine('')
[void]$zxc221.AppendLine('=== All kept blocks ===')
foreach ($zxc20 in $zxc283) {
  [void]$zxc221.AppendLine((
      '[{0}] x{1} score={2} | {3:yyyy-MM-dd HH:mm} .. {4:yyyy-MM-dd HH:mm} | {5}' -f
      $zxc20.Verdict, $zxc20.Count, $zxc20.Score, $zxc20.FirstSeen, $zxc20.LastSeen, $zxc20.Hits
    ))
}
[void]$zxc221.AppendLine('')
[void]$zxc221.AppendLine('=== Full script blocks (alerts + stagers only) ===')
[void]$zxc221.AppendLine('')

foreach ($zxc20 in $zxc283) {
  if ($zxc20.Verdict -notmatch '^(CRITICAL|FILELESS|CHEAT|REVIEW-HIGH)') { continue }
  [void]$zxc221.AppendLine(('=' * 72))
  [void]$zxc221.AppendLine(("verdict {0} | score {1} | x{2} | {3:yyyy-MM-dd HH:mm:ss} .. {4:yyyy-MM-dd HH:mm:ss} | {5}" -f $zxc20.Verdict, $zxc20.Score, $zxc20.Count, $zxc20.FirstSeen, $zxc20.LastSeen, $zxc20.Hash))
  [void]$zxc221.AppendLine($zxc20.Script)
  [void]$zxc221.AppendLine('')
}

[IO.File]::WriteAllText($zxc254, $zxc221.ToString(), [Text.UTF8Encoding]::new($false))
return [pscustomobject]@{ File = $zxc254; Alerts = @($zxc283 | Where-Object { $_.Verdict -match '^(CRITICAL|FILELESS|CHEAT)' }).Count; Review = @($zxc283 | Where-Object { $_.Verdict -match '^REVIEW' }).Count; Enabled = [bool]$zxc262.IsEnabled; Events = $zxc265.Count }
}

Write-Pink "`nLOGGING INTEGRITY"
try {
    if ($zxc25) {
        Write-Host "  EventLog query test : No response in 10 s (service frozen)" -ForegroundColor Red
        $zxc5 += "EventLog does not answer queries (service Running but frozen)"
    } else {
        Write-Host "  EventLog query test : Answered" -ForegroundColor Green
    }
    

    $zxc289 = [guid]::NewGuid().ToString()
    $zxc290 = Get-Date
    $zxc291 = Start-Process -FilePath "$env:SystemRoot\System32\eventcreate.exe" -ArgumentList @('/L','APPLICATION','/T','INFORMATION','/ID','999','/D',('"Y-sysinfo logging canary {0}"' -f $zxc289)) -WindowStyle Hidden -PassThru
    $zxc292 = -not $zxc291.WaitForExit(6000)
    if ($zxc292) { try { $zxc291.Kill() } catch {} }
    if ($zxc292) { Write-Host "  EventLog write test : eventcreate did not return in 6 s (service frozen)" -ForegroundColor Red ; $zxc5 += "EventLog does not accept events (eventcreate hangs)" } else {
        $zxc293 = $false
        for ($zxc284 = 0; $zxc284 -lt 8 -and -not $zxc293; $zxc284++) {
            Start-Sleep -Milliseconds 500
            $zxc294 = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='eventcreate'; Id=999; StartTime=$zxc290.AddSeconds(-2)} -MaxEvents 20 -ErrorAction SilentlyContinue
            foreach ($zxc295 in @($zxc294)) { if ($zxc295 -and $zxc295.Message -like "*$zxc289*") { $zxc293 = $true; break } }
        }
        if ($zxc293) { Write-Host "  EventLog write test : Event written and read back" -ForegroundColor Green }
        else {
            Write-Host "  EventLog write test : Event NOT written (service Running but not logging)" -ForegroundColor Red
            $zxc5 += "EventLog is Running but does not write events"
        }
    }

    $zxc296 = @(Get-ChildItem "$env:SystemRoot\Prefetch" -Filter *.pf -Force -ErrorAction SilentlyContinue)
    $zxc297 = @($zxc296 | Where-Object { $_.Name -match '^(FSUTIL|NETSH|FINDSTR|BCDEDIT|CMD|POWERSHELL)\.EXE-' -and $_.LastWriteTime -ge $zxc21 } | Sort-Object LastWriteTime -Descending)
    if ($zxc297.Count -gt 0) {
        Write-Host ("  Prefetch write test : {0} updated {1}" -f $zxc297[0].Name, $zxc297[0].LastWriteTime.ToString("HH:mm:ss")) -ForegroundColor Green
    } else {
        Write-Host "  Prefetch write test : No .pf updated since script start" -ForegroundColor Red
        $zxc5 += "Prefetch is not updating (SysMain bypass or disabled)"
    }

    $zxc298 = ($null -ne $zxc223) -and @($zxc223).Count -gt 0
    if (-not $zxc298) { Write-Host "  BAM write test : BAM data unavailable" -ForegroundColor Gray }
    else {
        $zxc299 = Get-Process -Id $PID
        $zxc300 = $zxc299.Path
        $zxc301 = @($zxc223 | Where-Object { $_.Path -ieq $zxc300 } | Sort-Object Time -Descending | Select-Object -First 1)
        if ($zxc301.Count -gt 0 -and $zxc301[0].Time -ge $zxc299.StartTime.AddSeconds(-15)) {
            Write-Host ("  BAM write test : {0} recorded {1}" -f (Split-Path $zxc300 -Leaf), $zxc301[0].Time.ToString("HH:mm:ss")) -ForegroundColor Green
        } else {
            Write-Host "  BAM write test : No fresh BAM entry for this PowerShell process" -ForegroundColor Red
            $zxc5 += "BAM is not recording new executions"
        }
    }

    $zxc302 = 'systeminformer|processhacker'
    $zxc303 = 0
    foreach ($zxc120 in @($zxc296 | Where-Object { $_.Name -match $zxc302 })) {
        Write-Host ("  System Informer / Process Hacker trace : {0} {1}" -f $zxc120.LastWriteTime.ToString("MM-dd HH:mm"), $zxc120.Name) -ForegroundColor Red
        $zxc303++
    }
    if ($zxc298) {
        foreach ($zxc198 in @($zxc223 | Where-Object { $_.Path -match $zxc302 })) {
            Write-Host ("  System Informer / Process Hacker trace : {0} {1}" -f $zxc198.Time.ToString("MM-dd HH:mm"), $zxc198.Path) -ForegroundColor Red
            $zxc303++
        }
    }
    if ($zxc303 -gt 0) { $zxc5 += "System Informer / Process Hacker was run on this PC" }
    else { Write-Host "  System Informer / Process Hacker traces : None" -ForegroundColor Green }
} catch { Write-Host "  Error during logging integrity check" -ForegroundColor Red }

$zxc304 = $null
try { $zxc304 = Invoke-Ps4104Hunt } catch { $zxc304 = $null }
if ($zxc304 -and $zxc304.Alerts -gt 0) { $zxc5 += "PowerShell 4104 alerts ($($zxc304.Alerts))" }
if ($zxc304 -and $zxc304.Review -gt 0) { $zxc6 += "PowerShell 4104 blocks to review ($($zxc304.Review))" }

Write-Pink "`nSFC SCANNOW"
if (-not $zxc28 -or $zxc25) { Write-Host "  Skipped" -ForegroundColor Gray }
else {
    Write-Host "  Waiting for sfc to finish" -ForegroundColor White
    Wait-Job $zxc28 | Out-Null
    Receive-Job $zxc28 | Out-Null
    Remove-Job $zxc28
    try {
        if (-not (Test-Path -LiteralPath $zxc18)) { New-Item -ItemType Directory -Path $zxc18 -Force | Out-Null }
        $zxc305 = "$env:SystemRoot\Logs\CBS\CBS.log"
        $zxc306 = Join-Path $zxc18 "CBS_$zxc19.log"
        $zxc307  = Join-Path $zxc18 "CBS_SFC_lines_$zxc19.txt"
        $zxc308 = [IO.File]::Open($zxc305, 'Open', 'Read', 'ReadWrite')
        $zxc309 = [IO.File]::Create($zxc306)
        $zxc308.CopyTo($zxc309); $zxc309.Close(); $zxc308.Close()
        Write-Host ("  CBS.log saved : {0} ({1:N1} MB)" -f $zxc306, ((Get-Item $zxc306).Length / 1MB)) -ForegroundColor White
        $zxc310 = $zxc27.AddMinutes(-1).ToString('yyyy-MM-dd HH:mm:ss')
        $zxc60 = New-Object System.Collections.Generic.List[string]
        foreach ($zxc182 in (Select-String -Path $zxc306 -Pattern '\[SR\]')) {
            $zxc100 = $zxc182.Line
            if ($zxc100.Length -ge 19 -and [string]::CompareOrdinal($zxc100.Substring(0, 19), $zxc310) -ge 0) { $zxc60.Add($zxc100) }
        }
        [IO.File]::WriteAllLines($zxc307, $zxc60, (New-Object Text.UTF8Encoding($true)))
        Write-Host "  SFC lines saved : $zxc307" -ForegroundColor White
        $zxc311 = @($zxc60 | Where-Object { $_ -match 'Cannot repair' })
        $zxc312 = @($zxc60 | Where-Object { $_ -match 'Repairing corrupted file|Repaired file|Repairing \d+ components' })
        $zxc313  = @($zxc60 | Where-Object { $_ -match 'Verify complete|Verification \d+% complete' })
        if ($zxc311.Count -gt 0) { Write-Host "  Result: SFC could not repair $($zxc311.Count) corrupted file(s)" -ForegroundColor Red; foreach ($zxc220 in ($zxc311 | Select-Object -First 6)) { Write-Host "    $($zxc220.Trim())" -ForegroundColor White } }
        elseif ($zxc312.Count -gt 0) { Write-Host "  Result: SFC repaired $($zxc312.Count) item(s)" -ForegroundColor White }
        elseif ($zxc313.Count -gt 0) { Write-Host "  Result: Windows Resource Protection did not find any integrity violations" -ForegroundColor Green }
        else { Write-Host "  Result: completed (check CBS.log)" -ForegroundColor White }
    } catch { Write-Host "  Result: completed (could not save CBS.log: $($_.Exception.Message))" -ForegroundColor White }
}

Write-Pink "`nPS OPERATIONAL (4104)"
if ($zxc304) {
    Write-Host ("  Log saved : {0}" -f $zxc304.File) -ForegroundColor White
    if ($zxc304.Alerts -gt 0) { Write-Host ("  Alerts : {0}" -f $zxc304.Alerts) -ForegroundColor Red }
    elseif ($zxc304.Review -gt 0) { Write-Host ("  Review : {0}" -f $zxc304.Review) -ForegroundColor White }
    else { Write-Host "  Alerts : None" -ForegroundColor Green }
    if (-not $zxc304.Enabled) { Write-Host "  Script Block Logging is off, 4104 log has no new data" -ForegroundColor Gray }
} else {
    Write-Host "  Error during 4104 scan" -ForegroundColor Red
}
Write-Host "`nzxc allah made it" -ForegroundColor DarkGray
Write-Host ""
