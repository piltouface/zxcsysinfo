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
    $handle = [ConsoleHelper]::GetStdHandle(-11)
    $mode = 0
    [ConsoleHelper]::GetConsoleMode($handle, [ref]$mode) | Out-Null
    [ConsoleHelper]::SetConsoleMode($handle, $mode -bor 4) | Out-Null
} catch {}
$pink  = [char]27 + "[38;2;255;182;193m"
$reset = [char]27 + "[0m"
function Write-Pink { param([string]$Text); Write-Host "${pink}${Text}${reset}" }

$suspAct = @(); $flags = @(); $warns = @()
$fakerDetected = $false; $fakerIndicators = @(); $networkProfiles = @()

function Get-MC {
    $p = Get-Process javaw -ErrorAction SilentlyContinue
    if (-not $p) { $p = Get-Process java -ErrorAction SilentlyContinue }
    if ($p -is [array]) { $p = $p | Sort-Object StartTime | Select-Object -First 1 }
    return $p
}
$mc = Get-MC
$modsPath = "$env:APPDATA\.minecraft\mods"

$cheatRx  = 'vape|liquid.?bounce|meteor.?client|wurst|aristois|novoline|astolfo|tenacity|doomsday|whiteout|pandaware|bleach.?hack|thunder.?hack|konas|phobos|rusher.?hack|kill.?aura|aim.?assist|auto.?click|trigger.?bot|(?<!anti[-_ ]?)cheat(?!sheet)|hack(?!athon)|injector|spoof|hwid|ghost.?client|myau|opai|slinky|rise.?client|entropy|drip.?client|exhibition|azura|click.?gui|raven.?b|dream.?client|sigma.?client|impact.?client|future.?client|nursultan|wexside|akrien|deadcode|catlean|minced'
$remoteRx = 'anydesk|teamviewer|rustdesk|parsec|ammyy|supremo|ultraviewer|tightvnc|tvnserver|winvnc|realvnc|vncviewer|radmin|splashtop|screenconnect|chromeremotedesktop|remoting_host|aeroadmin|rdpwrap'
$debugRx  = 'cheatengine|cheat engine|processhacker|systeminformer|x64dbg|x32dbg|ollydbg|windbg|wireshark|fiddler|dnspy|ilspy|ghidra|idaq|ida64|reshacker|hxd|injector|kdmapper|ksdumper|autohotkey|autoit3|jnativehook|procmon|procexp|apimonitor|scylla|megadumper|de4dot|recaf|bytecodeviewer|jd-gui|luyten'
$vmProcRx = 'vmware|vmtoolsd|vboxservice|vboxtray|virtualbox|qemu|vmms|vmcompute|windowssandbox|wsb'
$badDrvRx = '^(?:iqvw64e|capcom|gdrv|rtcore64|rtcore32|asrdrv|dbutil|cpuz|winring0|phymem|kprocesshacker|processhacker|ksysteminformer|systeminformer|mhyprot|kdmapper|speedfan|asio|atszio|nvflash|bsmem|gmer|dbk64|dbk32|inpoutx64|physmem)'
$scriptStart = Get-Date
$papaDir = Join-Path ([Environment]::GetFolderPath('Desktop')) 'papa'
$selfStart = (Get-Process -Id $PID).StartTime.AddSeconds(-10)

function Redact { param([string]$Text); $Text -replace '(--accessToken|--session|--xuid|--clientId)\s+\S+', '$1 <redacted>' }
function Get-Sig { param([string]$Path); try { (Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop).Status.ToString() } catch { 'Error' } }

$probeFile = Join-Path $env:TEMP ("y_evprobe_" + [guid]::NewGuid().ToString("N") + ".txt")
$probe = Start-Process -FilePath "$env:SystemRoot\System32\wevtutil.exe" -ArgumentList @('qe','System','/c:1','/rd:true','/f:text') -WindowStyle Hidden -PassThru -RedirectStandardOutput $probeFile
$evFrozen = -not $probe.WaitForExit(10000)
if ($evFrozen) { try { $probe.Kill() } catch {} }
Remove-Item -LiteralPath $probeFile -Force -ErrorAction SilentlyContinue
function Get-WinEvent {
    if ($evFrozen) { return }
    Microsoft.PowerShell.Diagnostics\Get-WinEvent @args
}
function Get-CimInstance {
    if ($evFrozen -and "$args" -match 'Win32_Service') { return }
    CimCmdlets\Get-CimInstance @args
}

Write-Pink "Y-sysinfo"
Write-Host ""

$sfcJob = $null
if (-not $env:Y_NOSFC) {
    Write-Host "Starting sfc /scannow in background..." -ForegroundColor Gray
    $sfcJob = Start-Job -ScriptBlock { & "$env:SystemRoot\System32\sfc.exe" /scannow | Out-Null }
}

# BOOT TIME
try {
    $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Pink "SYSTEM BOOT TIME"
    Write-Host ("  Last Boot : {0}" -f $bootTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    Write-Host ("  Uptime    : {0}d {1:D2}:{2:D2}:{3:D2}" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds) -ForegroundColor White
} catch { Write-Host "  Unable to retrieve boot time" -ForegroundColor Red }
if ($mc) {
    $mcUp = (Get-Date) - $mc.StartTime
    Write-Host ("  MC Start  : {0}" -f $mc.StartTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    Write-Host ("  MC Uptime : {0}d {1:D2}:{2:D2}:{3:D2}" -f $mcUp.Days, $mcUp.Hours, $mcUp.Minutes, $mcUp.Seconds) -ForegroundColor White
} else { Write-Host "  MC        : not running" -ForegroundColor Gray }

# WINDOWS INSTALLATION
Write-Pink "`nWINDOWS INSTALLATION"
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $installDate = $os.InstallDate
    $installAge = ((Get-Date) - $installDate).TotalDays
    Write-Host ("  Install Date : {0}" -f $installDate.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor $(if ($installAge -lt 14) { "Red" } else { "White" })
    if ($installAge -lt 14) { $warns += "Windows installed {0:N0} days ago" -f $installAge }
    Write-Host ("  OS Version   : {0}" -f $os.Caption) -ForegroundColor White
    Write-Host ("  Build        : {0}" -f $os.BuildNumber) -ForegroundColor White
    $tzShift = ([TimeZoneInfo]::Local.GetUtcOffset([datetime]::Now)).TotalHours - 3
    $tzName = if ($tzShift -eq 0) { "Moscow" } else { "Moscow {0:+0.##;-0.##}" -f $tzShift }
    Write-Host ("  Time Zone    : {0}" -f $tzName) -ForegroundColor White
} catch { Write-Host "  Error reading install info" -ForegroundColor Red }

# DRIVES
$drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Pink "`nCONNECTED DRIVES"
    foreach ($d in $drives) {
        if ($d.DriveType -eq 2) { Write-Host ("  {0} {1} (Removable)" -f $d.DeviceID, $d.FileSystem) -ForegroundColor Red; $warns += "Removable drive connected $($d.DeviceID)" }
        else { Write-Host ("  {0} {1}" -f $d.DeviceID, $d.FileSystem) -ForegroundColor Green }
    }
}

# SERVICES
Write-Pink "`nSERVICE STATUS"
$services = @(
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
foreach ($svc in $services) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    $isDriver = $false
    if (-not $s) {
        $drv = Get-CimInstance Win32_SystemDriver -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
        if ($drv) { $isDriver = $true; $s = [PSCustomObject]@{ Status = $(if ($drv.State -eq "Running") { "Running" } else { $drv.State }) } }
    }
    if ($s) {
        $startMode = (Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue).StartMode
        if ($svc.Name -eq "icssvc") {
            $col = if ($s.Status -eq "Running") { "Red" } else { "Green" }
            Write-Host ("  {0,-12} {1}" -f $svc.Name, $s.Status) -ForegroundColor $col
        } elseif ($s.Status -eq "Running" -and $startMode -ne "Disabled") {
            Write-Host ("  {0,-12} {1,-8}" -f $svc.Name, $s.Status) -ForegroundColor Green -NoNewline
            if ($isDriver -or $svc.Name -eq "Bam") { Write-Host " | Enabled" -ForegroundColor White }
            else {
                try {
                    $proc = Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'" | Select-Object ProcessId
                    if ($proc.ProcessId -gt 0) {
                        $p = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue
                        if ($p) { Write-Host (" | {0}" -f $p.StartTime.ToString("HH:mm:ss")) -ForegroundColor White }
                        else { Write-Host " | N/A" -ForegroundColor White }
                    } else { Write-Host " | N/A" -ForegroundColor White }
                } catch { Write-Host " | N/A" -ForegroundColor White }
            }
        } else {
            $st = if ($startMode -eq "Disabled") { "$($s.Status) (Disabled)" } else { "$($s.Status)" }
            Write-Host ("  {0,-12} {1}" -f $svc.Name, $st) -ForegroundColor Red
        }
    } else {
        Write-Host ("  {0,-12} N/A" -f $svc.Name) -ForegroundColor White
    }
}

function Get-SuspendedServiceHosts {
    param($Services)
    $checked = 0
    $unreadable = 0
    $bad = @()
    $all = @()
    foreach ($grp in ($Services | Group-Object ProcessId)) {
        $proc = Get-Process -Id ([int]$grp.Name) -ErrorAction SilentlyContinue
        if (-not $proc) { continue }
        $threads = @($proc.Threads)
        if ($threads.Count -eq 0) { $unreadable++; continue }
        $checked++
        $susp = @($threads | Where-Object { $_.ThreadState -eq 'Wait' -and $_.WaitReason -eq 'Suspended' })
        $row = [pscustomobject]@{ ProcessId = [int]$grp.Name; Names = (($grp.Group | ForEach-Object { $_.Name }) -join ', '); Suspended = $susp.Count; Total = $threads.Count }
        $all += $row
        if ($susp.Count -gt 0) { $bad += $row }
    }
    [pscustomobject]@{ Checked = $checked; Unreadable = $unreadable; Bad = $bad; All = $all }
}

Write-Pink "`nSERVICE THREADS CHECK"
try {
    $svcNames = @($services | ForEach-Object { $_.Name })
    $taskRows = @(& "$env:SystemRoot\System32\tasklist.exe" /svc /fo csv /nh | ConvertFrom-Csv -Header 'Image','Pid','Services')
    $svcPids = @()
    foreach ($row in $taskRows) {
        if ($row.Services -eq 'N/A' -or -not ($row.Pid -as [int])) { continue }
        foreach ($sn in ($row.Services -split ',')) {
            if ($svcNames -contains $sn.Trim()) { $svcPids += [pscustomobject]@{ Name = $sn.Trim(); ProcessId = [int]$row.Pid } }
        }
    }
    $hosts = Get-SuspendedServiceHosts $svcPids
    foreach ($h in ($hosts.All | Sort-Object Names)) {
        if ($h.Suspended -gt 0) {
            Write-Host ("  {0,-26} PID {1}, threads {2}, suspended {3}" -f $h.Names, $h.ProcessId, $h.Total, $h.Suspended) -ForegroundColor Red
            $flags += "Service threads suspended: $($h.Names) ($($h.Suspended) of $($h.Total))"
            if ($h.Suspended -eq $h.Total) { $flags += "Service process is fully frozen: $($h.Names)" }
        } else {
            Write-Host ("  {0,-26} PID {1}, threads {2}, suspended 0" -f $h.Names, $h.ProcessId, $h.Total) -ForegroundColor Green
        }
    }
    if ($hosts.Unreadable -gt 0) { Write-Host ("  Unreadable : {0}" -f $hosts.Unreadable) -ForegroundColor Gray }
} catch { Write-Host "  Error during service threads check" -ForegroundColor Red }

# REGISTRY
Write-Pink "`nREGISTRY"
$regs = @(
    @{Name="CMD";              Path="HKCU:\Software\Policies\Microsoft\Windows\System";                                                                Key="DisableCMD";               W="Disabled"; S="Available"; BadVals=@(1,2)},
    @{Name="Task Manager";     Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System";                                                 Key="DisableTaskMgr";           W="Disabled"; S="Available"; BadVals=@(1)},
    @{Name="Registry Editor";  Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System";                                                 Key="DisableRegistryTools";     W="Disabled"; S="Available"; BadVals=@(1)},
    @{Name="PS Logging";       Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging";                                        Key="EnableScriptBlockLogging"; W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Activities Cache"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                                Key="EnableActivityFeed";       W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Prefetch";         Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key="EnablePrefetcher"; W="Disabled"; S="Enabled"; BadVals=@(0)},
    @{Name="Superfetch";       Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key="EnableSuperfetch"; W="Disabled"; S="Enabled"; BadVals=@(0)}
)
foreach ($r in $regs) {
    $val = Get-ItemProperty -Path $r.Path -Name $r.Key -ErrorAction SilentlyContinue
    Write-Host "  $($r.Name): " -NoNewline -ForegroundColor White
    if ($val -and ($r.BadVals -contains $val.$($r.Key))) { Write-Host $r.W -ForegroundColor Red; $warns += "$($r.Name) $($r.W)" }
    else { Write-Host $r.S -ForegroundColor Green }
}

# DEFENDER
Write-Pink "`nWINDOWS DEFENDER"
try {
    $rtp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $pol = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $tmp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name TamperProtection -ErrorAction SilentlyContinue).TamperProtection
    Write-Host "  Real-Time Protection : " -NoNewline -ForegroundColor White
    $mpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $mpPref = Get-MpPreference -ErrorAction SilentlyContinue
    $rtpOff = ($mpStatus -and ($mpStatus.RealTimeProtectionEnabled -eq $false)) -or ($mpPref -and $mpPref.DisableRealtimeMonitoring)
    if ($rtp -eq 1 -or $pol -eq 1 -or $rtpOff) { Write-Host "DISABLED" -ForegroundColor Red; $flags += "Defender real-time protection is OFF" }
    else { Write-Host "Enabled" -ForegroundColor Green }
    Write-Host "  Tamper Protection    : " -NoNewline -ForegroundColor White
    if ($tmp -eq 5) { Write-Host "Enabled" -ForegroundColor Green }
    elseif ($null -eq $tmp) { Write-Host "Unknown" -ForegroundColor Gray }
    else { Write-Host "DISABLED" -ForegroundColor Red; $warns += "Tamper Protection disabled" }
    if ($pol -eq 1) { Write-Host "  Note: disabled via Group Policy" -ForegroundColor White }
    if ($mpStatus -and $mpStatus.AMRunningMode -and $mpStatus.AMRunningMode -ne "Normal") { Write-Host "  Running Mode         : $($mpStatus.AMRunningMode)" -ForegroundColor Red; $warns += "Defender running mode $($mpStatus.AMRunningMode)" }
    $excl = @()
    foreach ($ek in @("ExclusionPath","ExclusionProcess","ExclusionExtension")) { $excl += @($mpPref.$ek | Where-Object { $_ }) }
    if ($excl.Count -gt 0) {
        Write-Host "  Exclusions           : $($excl.Count)" -ForegroundColor Red
        foreach ($x in $excl) { Write-Host "    $x" -ForegroundColor White }
        $warns += "Defender exclusions ($($excl.Count))"
    } else { Write-Host "  Exclusions           : None" -ForegroundColor Green }
    $threats = @(Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 8)
    if ($threats.Count -gt 0) {
        Write-Host "  Detections           : $($threats.Count)" -ForegroundColor Red
        foreach ($t in $threats) { Write-Host ("    {0}  {1}" -f $t.InitialDetectionTime.ToString("yyyy-MM-dd HH:mm"), ($t.Resources -join '; ')) -ForegroundColor White }
        $warns += "Defender detections in history ($($threats.Count))"
    } else { Write-Host "  Detections           : None" -ForegroundColor Green }
    $rtpEvents = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Windows Defender/Operational"; Id=5001; StartTime=(Get-Date).AddDays(-14)} -MaxEvents 3 -ErrorAction SilentlyContinue
    foreach ($re in $rtpEvents) { Write-Host "  Real-time was turned off at $($re.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
    if ($rtpEvents -and -not ($flags -contains "Defender real-time protection is OFF")) { $flags += "Defender real-time was turned off recently" }
} catch { Write-Host "  Error reading Defender status" -ForegroundColor Red }

# EVENT LOGS
Write-Pink "`nEVENT LOGS"
function Check-EV { param($log,$id,$msg)
    $e = Get-WinEvent -LogName $log -FilterXPath "*[System[EventID=$id]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($e) { Write-Host "  $msg at: " -NoNewline -ForegroundColor White; Write-Host $e.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  $msg - No records found" -ForegroundColor Green }
}
function Check-EVMulti { param($log,$ids,$msg)
    $xp = ($ids | ForEach-Object { "EventID=$_" }) -join " or "
    $e = Get-WinEvent -LogName $log -FilterXPath "*[System[$xp]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($e) { Write-Host "  $msg (ID:$($e.Id)) at: " -NoNewline -ForegroundColor White; Write-Host $e.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  $msg - No records found" -ForegroundColor Green }
}
Check-EV      "Application" 3079        "USN Journal cleared"
Check-EV      "System"      104         "Event Logs cleared"
Check-EV      "Security"    1102        "Security Log cleared"
Check-EV      "System"      1074        "Last PC Shutdown"
Check-EV      "Security"    4616        "System time changed"
Check-EV      "System"      6005        "Event Log Service started"
try {
    $ev = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -FilterXPath "*[System[EventID=400]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($ev) { Write-Host "  Device config changed at: " -NoNewline -ForegroundColor White; Write-Host $ev.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  Device changes - No records found" -ForegroundColor Green }
} catch { Write-Host "  Device changes - No records found" -ForegroundColor Green }
$logCleared = Get-WinEvent -FilterHashtable @{LogName="System"; Id=104} -MaxEvents 1 -ErrorAction SilentlyContinue
$secCleared = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=1102} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($logCleared -or $secCleared) { $warns += "Event log was cleared" }

$clockEvents = Get-WinEvent -FilterHashtable @{LogName="System"; ProviderName="Microsoft-Windows-Kernel-General"; Id=1; StartTime=(Get-Date).AddDays(-30)} -MaxEvents 400 -ErrorAction SilentlyContinue
$clockChanges = @()
foreach ($ce in $clockEvents) {
    try {
        $newTime = [datetime]$ce.Properties[0].Value; $oldTime = [datetime]$ce.Properties[1].Value
        if ([int]$ce.Properties[3].Value -notin 1,2 -and [math]::Abs(($newTime - $oldTime).TotalSeconds) -gt 2) {
            $clockChanges += [PSCustomObject]@{ At=$ce.TimeCreated; Old=$oldTime.ToLocalTime(); New=$newTime.ToLocalTime(); By=(Split-Path ([string]$ce.Properties[4].Value) -Leaf) }
        }
    } catch {}
}
if ($clockChanges.Count -gt 0) {
    Write-Host "  Clock changed manually : $($clockChanges.Count) time(s) in 30 days" -ForegroundColor Red
    foreach ($cc in ($clockChanges | Select-Object -First 8)) { Write-Host ("    {0}  {1} -> {2}  by {3}" -f $cc.At.ToString("MM-dd HH:mm"), $cc.Old.ToString("yyyy-MM-dd HH:mm:ss"), $cc.New.ToString("yyyy-MM-dd HH:mm:ss"), $cc.By) -ForegroundColor White }
    $flags += "System clock changed manually ($($clockChanges.Count))"
} else { Write-Host "  Clock changes - No manual changes in 30 days" -ForegroundColor Green }

# USN JOURNAL
Write-Pink "`nUSN JOURNAL"
try {
    $usn = fsutil usn queryjournal $env:SystemDrive 2>&1
    if ($usn -notmatch "Usn Journal ID" -and ($usn -match "Invalid|not active")) {
        Write-Host "  Status       : DISABLED" -ForegroundColor Red
        $warns += "USN Journal disabled"
    } elseif ($usn -match "Usn Journal ID") {
        Write-Host "  Status       : Enabled" -ForegroundColor Green
        $usnClear = Get-WinEvent -LogName "Application" -FilterXPath "*[System[EventID=3079]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        $jCreated = $null
        if (($usn | Out-String) -match "Usn Journal ID\s*:\s*0x([0-9a-fA-F]+)") {
            try { $jCreated = [datetime]::FromFileTime([Convert]::ToInt64($Matches[1], 16)) } catch {}
        }
        $osInst = (Get-CimInstance Win32_OperatingSystem).InstallDate
        $jRecreated = $jCreated -and $osInst -and (($jCreated - $osInst).TotalDays -gt 1)
        if ($jCreated) { Write-Host "  Journal created : $($jCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor $(if ($jRecreated) { "Red" } else { "White" }) }
        if ($usnClear) { Write-Host "  Last cleared : $($usnClear.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red; $warns += "USN Journal cleared" }
        elseif ($jRecreated) { Write-Host "  Last cleared : journal was recreated after Windows install" -ForegroundColor Red; $warns += "USN Journal recreated ($($jCreated.ToString('yyyy-MM-dd HH:mm')))" }
        else { Write-Host "  Last cleared : No signs of clearing" -ForegroundColor Green }
        $fu = $usn | Select-String "First Usn"
        if ($fu) { Write-Host "  $($fu.Line.Trim())" -ForegroundColor Gray }
    } else { Write-Host "  Status       : Unknown" -ForegroundColor White }
} catch { Write-Host "  Error reading USN Journal" -ForegroundColor Red }

Write-Pink "`nRECENTLY DELETED FILES (48h)"
try {
    $delSince = (Get-Date).AddHours(-48)
    $delFiles = @{}; $pfDeleted = 0
    foreach ($vol in (Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.FileSystem -eq "NTFS" })) {
        $letter = $vol.DeviceID
        $jinfo = (fsutil usn queryjournal $letter 2>&1 | Out-String)
        if ($jinfo -notmatch '(?i)First Usn\s*:\s*(0x[0-9a-f]+)') { continue }
        $firstUsn = [Convert]::ToInt64($Matches[1].Substring(2), 16)
        $records = cmd /c "fsutil usn readjournal $letter startusn=$firstUsn csv | findstr /i /c:""File delete"" /c:""Rename: old"""
        foreach ($rec in $records) {
            if ($rec -notmatch '^\d+,"(.*?)",\d+,0x[0-9a-fA-F]+,"(.*?)","(.*?)"') { continue }
            $fname = $Matches[1]; $reason = $Matches[2]; $stamp = $Matches[3]
            $when = [datetime]::MinValue
            if (-not [datetime]::TryParse($stamp, [Globalization.CultureInfo]::CurrentCulture, 'None', [ref]$when)) { continue }
            if ($when -lt $delSince) { continue }
            if ($fname -match '^__PSScriptPolicyTest|^tmp[0-9a-f]{6,}\.|\.tmp$') { continue }
            $isPf = $fname -match '\.pf$'
            if (-not (($fname -match '\.(exe|jar|bat|cmd|ps1|vbs|zip|rar|7z|msi|sys)$') -or ($fname -match $cheatRx) -or $isPf)) { continue }
            if ($isPf -and $reason -match 'delete') { $pfDeleted++ }
            if ($isPf) { continue }
            $key = $fname.ToLower()
            $kind = if ($reason -match 'Rename') { "renamed" } else { "deleted" }
            if (-not $delFiles.ContainsKey($key) -or $delFiles[$key].Time -lt $when) { $delFiles[$key] = [PSCustomObject]@{ Name=$fname; Time=$when; Kind=$kind } }
        }
    }
    $delAll = @($delFiles.Values | Sort-Object Time -Descending)
    $delCheat = @($delAll | Where-Object { $_.Name -match $cheatRx })
    $delOther = @($delAll | Where-Object { $_.Name -notmatch $cheatRx })
    if ($pfDeleted -gt 0) { Write-Host "  Prefetch files deleted : $pfDeleted" -ForegroundColor Red; $flags += "Prefetch files deleted ($pfDeleted)" }
    if ($delCheat.Count -gt 0) {
        Write-Host "  Cheat-named files : $($delCheat.Count)" -ForegroundColor Red
        foreach ($d in ($delCheat | Select-Object -First 20)) { Write-Host ("    {0}  {1,-8} {2}" -f $d.Time.ToString("yyyy-MM-dd HH:mm:ss"), $d.Kind, $d.Name) -ForegroundColor Red }
        $flags += "Cheat-named files deleted/renamed ($($delCheat.Count))"
    }
    if ($delOther.Count -gt 0) {
        Write-Host "  Deleted/renamed exe, jar, archives : $($delOther.Count) (newest 30)" -ForegroundColor White
        foreach ($d in ($delOther | Select-Object -First 30)) { Write-Host ("    {0}  {1,-8} {2}" -f $d.Time.ToString("yyyy-MM-dd HH:mm:ss"), $d.Kind, $d.Name) -ForegroundColor White }
    }
    if ($delAll.Count -eq 0 -and $pfDeleted -eq 0) { Write-Host "  Nothing suspicious in journal" -ForegroundColor Green }
} catch { Write-Host "  Error reading USN records" -ForegroundColor Red }

# PREFETCH
$pfPath = "$env:SystemRoot\Prefetch"
if (Test-Path $pfPath) {
    Write-Pink "`nPREFETCH INTEGRITY"
    $files = Get-ChildItem $pfPath -Filter *.pf -Force -ErrorAction SilentlyContinue
    if (-not $files) { Write-Host "  No prefetch files found" -ForegroundColor White }
    else {
        $total = $files.Count; $ht = @{}; $sus = @{}; $hid = @(); $ro = @(); $hidro = @()
        foreach ($f in $files) {
            try {
                $isH = $f.Attributes -band [System.IO.FileAttributes]::Hidden
                $isR = $f.Attributes -band [System.IO.FileAttributes]::ReadOnly
                if ($isH -and $isR) { $hidro += $f; $sus[$f.Name] = "Hidden+ReadOnly" }
                elseif ($isH)       { $hid   += $f; $sus[$f.Name] = "Hidden" }
                elseif ($isR)       { $ro    += $f; $sus[$f.Name] = "ReadOnly" }
                if ($f.Length -eq 0) { $sus[$f.Name] = "Zero length" }
                else {
                    $fs = [IO.File]::Open($f.FullName, 'Open', 'Read', 'ReadWrite'); $hdr = New-Object byte[] 8; [void]$fs.Read($hdr, 0, 8); $fs.Close()
                    $okHdr = ($hdr[0] -eq 0x4D -and $hdr[1] -eq 0x41 -and $hdr[2] -eq 0x4D) -or ($hdr[4] -eq 0x53 -and $hdr[5] -eq 0x43 -and $hdr[6] -eq 0x43 -and $hdr[7] -eq 0x41)
                    if (-not $okHdr) { $sus[$f.Name] = "Invalid header (fake/edited)" }
                }
                $h = Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($h) {
                    if ($ht.ContainsKey($h.Hash)) { $ht[$h.Hash].Add($f.Name) }
                    else { $ht[$h.Hash] = [System.Collections.Generic.List[string]]::new(); $ht[$h.Hash].Add($f.Name) }
                }
            } catch { $sus[$f.Name] = "Error" }
        }
        if ($hidro.Count -gt 0) { Write-Host "  Hidden+ReadOnly: $($hidro.Count)" -ForegroundColor White; $hidro | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        if ($hid.Count   -gt 0) { Write-Host "  Hidden: $($hid.Count)" -ForegroundColor White; $hid | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        elseif ($hidro.Count -eq 0) { Write-Host "  Hidden Files: None" -ForegroundColor Green }
        if ($ro.Count    -gt 0) { Write-Host "  ReadOnly: $($ro.Count)" -ForegroundColor White; $ro | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        else { Write-Host "  ReadOnly Files: None" -ForegroundColor Green }
        $dupes = $ht.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
        if ($dupes) {
            foreach ($e in $dupes) {
                $e.Value | ForEach-Object { if (-not $sus.ContainsKey($_)) { $sus[$_] = "Duplicate" } }
                Write-Host "  Duplicate: $($e.Value -join ', ')" -ForegroundColor White
            }
        } else { Write-Host "  Duplicates: None" -ForegroundColor Green }
        if ($sus.Count -gt 0) {
            Write-Host "`n  SUSPICIOUS: $($sus.Count)/$total" -ForegroundColor White
            foreach ($e in $sus.GetEnumerator() | Sort-Object Key) { Write-Host "    $($e.Key) : $($e.Value)" -ForegroundColor White }
            $warns += "Suspicious prefetch files ($($sus.Count))"
        } else { Write-Host "`n  Prefetch integrity: Clean ($total files)" -ForegroundColor Green }
        $pfSorted = @($files | Sort-Object LastWriteTime)
        Write-Host ("  Oldest / Newest : {0}  /  {1}" -f $pfSorted[0].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), $pfSorted[-1].LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        if ($pfSorted[-1].LastWriteTime -lt $bootTime) { Write-Host "  No prefetch updates since boot" -ForegroundColor Red; $warns += "No prefetch updates since boot" }
        if ($mc) {
            $pfBefore = @($pfSorted | Where-Object { $_.LastWriteTime -lt $mc.StartTime } | Select-Object -Last 5)
            $pfAfter  = @($pfSorted | Where-Object { $_.LastWriteTime -ge $mc.StartTime } | Select-Object -First 15)
            Write-Host "`n  Around Java launch (5 before, 15 after)" -ForegroundColor White
            foreach ($pf in $pfBefore) { Write-Host ("    {0}  {1}" -f $pf.LastWriteTime.ToString("MM-dd HH:mm:ss"), $pf.Name) -ForegroundColor $(if ($pf.Name -match $cheatRx) { "Red" } else { "Gray" }) }
            Write-Host ("    ---- Java started {0} ----" -f $mc.StartTime.ToString("MM-dd HH:mm:ss")) -ForegroundColor White
            foreach ($pf in $pfAfter) { Write-Host ("    {0}  {1}" -f $pf.LastWriteTime.ToString("MM-dd HH:mm:ss"), $pf.Name) -ForegroundColor $(if ($pf.Name -match $cheatRx) { "Red" } else { "Gray" }) }
        } else {
            Write-Host "`n  Last 20 executed" -ForegroundColor White
            foreach ($pf in ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 20)) { Write-Host ("    {0}  {1}" -f $pf.LastWriteTime.ToString("MM-dd HH:mm:ss"), $pf.Name) -ForegroundColor $(if ($pf.Name -match $cheatRx) { "Red" } else { "Gray" }) }
        }
        foreach ($pf in @($files | Where-Object { $_.Name -match $cheatRx } | Sort-Object LastWriteTime -Descending | Select-Object -First 10)) {
            Write-Host ("  Cheat name in prefetch : {0}  {1}" -f $pf.Name, $pf.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Red
            $flags += "Prefetch match $($pf.Name)"
        }
    }
} else { Write-Host "`nPREFETCH folder not found" -ForegroundColor Red }

# RECYCLE BIN
Write-Pink "`nRECYCLE BIN"
try {
    $rbPath = "$env:SystemDrive\`$Recycle.Bin"
    if (Test-Path $rbPath) {
        $rbF = Get-Item -LiteralPath $rbPath -Force
        $ufs = Get-ChildItem -LiteralPath $rbPath -Directory -Force -ErrorAction SilentlyContinue
        $all = @(); $lat = $rbF.LastWriteTime
        foreach ($uf in $ufs) {
            if ($uf.LastWriteTime -gt $lat) { $lat = $uf.LastWriteTime }
            $ui = Get-ChildItem -LiteralPath $uf.FullName -File -Force -ErrorAction SilentlyContinue
            if ($ui) {
                $all += $ui
                $lf = $ui | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($lf -and $lf.LastWriteTime -gt $lat) { $lat = $lf.LastWriteTime }
            }
        }
        Write-Host "  Last Modified: $($lat.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        if ($all.Count -gt 0) {
            Write-Host "  Total Items: $($all.Count)" -ForegroundColor White
            $lt = $all | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Write-Host "  Latest Item: $($lt.Name)" -ForegroundColor Gray
        } else { Write-Host "  Status: Empty" -ForegroundColor Green }
        $mySid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $myRb = Get-Item -LiteralPath (Join-Path $rbPath $mySid) -Force -ErrorAction SilentlyContinue
        if ($myRb) {
            if ($all.Count -eq 0) { Write-Host "  Last Cleared : $($myRb.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
            else { Write-Host "  Last Cleared : unknown (bin not empty)" -ForegroundColor Gray }
        }
    } else { Write-Host "  Recycle Bin not found" -ForegroundColor White }
} catch { Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red }

# POWERSHELL HISTORY
Write-Pink "`nPOWERSHELL HISTORY"
$hPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $hPath) {
    $hf = Get-Item $hPath -Force
    Write-Host "  Last Modified : $($hf.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "  File Size     : $([math]::Round($hf.Length/1024,2)) KB" -ForegroundColor White
    $a = $hf.Attributes
    if ($a -ne "Archive") { Write-Host "  Attributes    : $a" -ForegroundColor White }
    else { Write-Host "  Attributes    : Normal" -ForegroundColor Green }
} else { Write-Host "  History file not found" -ForegroundColor White }

# USB HISTORY
Write-Pink "`nUSB HISTORY"
try {
    $usbReg = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $usbReg) {
        $devs = Get-ChildItem -Path $usbReg -ErrorAction SilentlyContinue
        if ($devs) {
            foreach ($dev in $devs) {
                foreach ($inst in (Get-ChildItem -Path $dev.PSPath -ErrorAction SilentlyContinue)) {
                    $props = Get-ItemProperty -Path $inst.PSPath -ErrorAction SilentlyContinue
                    $name = $props.FriendlyName
                    if (-not $name) { $name = $dev.PSChildName -replace "_", " " }
                    $last = $null
                    $pk = Join-Path $inst.PSPath "Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0066"
                    if (Test-Path $pk) {
                        $rawp = Get-ItemProperty -Path $pk -ErrorAction SilentlyContinue
                        if ($rawp.'(default)') { try { $last = [datetime]::FromFileTime([BitConverter]::ToInt64($rawp.'(default)',0)) } catch {} }
                    }
                    Write-Host "  $name" -ForegroundColor White -NoNewline
                    if ($last) { Write-Host (" | Last seen: {0}" -f $last.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White }
                    else { Write-Host "" }
                }
            }
        } else { Write-Host "  No USB storage devices found" -ForegroundColor Green }
    } else { Write-Host "  No USB storage devices found" -ForegroundColor Green }
} catch { Write-Host "  Error reading USB history" -ForegroundColor Red }

# LOGGED-ON USERS
Write-Pink "`nLOGGED-ON USERS"
try {
    $sessions = Get-CimInstance Win32_LogonSession -ErrorAction SilentlyContinue | Where-Object { $_.LogonType -in @(2,10,11) }
    $map = @{ 2="Interactive"; 10="RemoteInteractive"; 11="CachedInteractive" }
    if ($sessions) {
        $rows = @()
        foreach ($ses in $sessions) {
            $acc = Get-CimAssociatedInstance -InputObject $ses -ResultClassName Win32_UserAccount -ErrorAction SilentlyContinue
            $un = if ($acc) { "$($acc.Domain)\$($acc.Name)" } else { (Get-CimInstance Win32_ComputerSystem).UserName }
            $rows += [PSCustomObject]@{ User=$un; Type=$map[[int]$ses.LogonType]; Start=$ses.StartTime }
        }
        foreach ($g in ($rows | Group-Object User, Type)) {
            $first = $g.Group | Sort-Object Start | Select-Object -First 1
            $st = if ($first.Start) { $first.Start.ToString("yyyy-MM-dd HH:mm:ss") } else { "N/A" }
            Write-Host ("  {0,-30} {1,-18} Since: {2}" -f $first.User, $first.Type, $st) -ForegroundColor White
        }
    } else {
        $cu = (Get-CimInstance Win32_ComputerSystem).UserName
        if ($cu) { Write-Host "  $cu" -ForegroundColor White } else { Write-Host "  No interactive sessions" -ForegroundColor Green }
    }
} catch { Write-Host "  Error retrieving sessions" -ForegroundColor Red }

# HOTSPOT / FAKER DETECTION
Write-Pink "`nHOTSPOT / FAKER DETECTION"
$tunRx = "Wintun|WireGuard|TAP-Windows|TAP-Win|OpenVPN|sing-tun|Tunnel|VPN|NordLynx|Tailscale|ZeroTier|Hamachi|AnyConnect|Fortinet|Proton|Mullvad|(^|\W)TUN(\W|$)"
try {
    $po = netsh wlan show profiles
    $pn = $po | Select-String "All User Profile\s+:\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    foreach ($p in $pn) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $isHs = $p -match "Android|iPhone|iPad|Galaxy|Pixel|OnePlus|Xiaomi|DIRECT-|SM-|GT-"
        $networkProfiles += [PSCustomObject]@{ SSID=$p; IsHotspot=$isHs }
    }
    $hsp = $networkProfiles | Where-Object { $_.IsHotspot }
    if ($hsp.Count -gt 0) { Write-Host "  Hotspot profiles: $($hsp.Count)" -ForegroundColor White; $hsp | ForEach-Object { Write-Host "    - $($_.SSID)" -ForegroundColor White } }
    else { Write-Host "  WiFi profiles: no mobile hotspots" -ForegroundColor Green }
} catch {}

try {
    $iface  = netsh wlan show interfaces
    $ssidM  = $iface | Select-String "^\s+SSID\s+:\s+(.+)$"
    $stateM = $iface | Select-String "^\s+State\s+:\s+(.+)$"
    $bssidM = $iface | Select-String "^\s+(AP )?BSSID\s+:\s+(.+)$"
    $chanM  = $iface | Select-String "^\s+Channel\s+:\s+(.+)$"
    $sigM   = $iface | Select-String "^\s+Signal\s+:\s+(.+)$"
    if ($ssidM -and $stateM) {
        $curSSID  = $ssidM.Matches.Groups[1].Value.Trim()
        $curState = $stateM.Matches.Groups[1].Value.Trim()
        $bssid    = if ($bssidM) { $bssidM.Matches.Groups[2].Value.Trim() } else { "N/A" }
        $chan     = if ($chanM)  { $chanM.Matches.Groups[1].Value.Trim() }  else { "N/A" }
        $sig      = if ($sigM)   { $sigM.Matches.Groups[1].Value.Trim() }   else { "N/A" }
        if ($curState -eq "connected") {
            $isHs = $false; $hsInd = @()
            $pats = @("Android","iPhone","iPad","Galaxy","Pixel","OnePlus","Xiaomi","Huawei","Oppo","Vivo","Realme","Nokia","DIRECT-","SM-[A-Z0-9]","GT-[A-Z0-9]","Redmi","'s iPhone","'s Galaxy","'s Pixel")
            foreach ($pat in $pats) { if ($curSSID -match $pat) { $isHs=$true; $hsInd+="SSID matches: $pat"; break } }
            if ($bssid -ne "N/A") { $sc=$bssid.Substring(1,1); if ($sc -match "[26AEae]") { $isHs=$true; $hsInd+="BSSID locally administered" } }
            try {
                $gws = @(Get-NetIPConfiguration -All -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway -and $_.InterfaceDescription -notmatch $tunRx -and $_.InterfaceDescription -notmatch "VirtualBox|VMware|Hyper-V" } | ForEach-Object { [string]$_.IPv4DefaultGateway.NextHop })
                foreach ($gw in $gws) {
                    if ($gw -like "192.168.137.*") { $isHs=$true; $fakerDetected=$true; $fakerIndicators+="Windows PC Hotspot gateway (192.168.137.x)"; $hsInd+="Gateway = Windows Mobile Hotspot - FAKER" }
                    elseif ($gw -eq "192.168.43.1") { $isHs=$true; $hsInd+="Gateway = Android hotspot" }
                    elseif ($gw -eq "192.168.49.1") { $isHs=$true; $hsInd+="Gateway = Android hotspot" }
                    elseif ($gw -like "172.20.10.*") { $isHs=$true; $hsInd+="Gateway = iPhone hotspot" }
                }
            } catch {}
            Write-Host "  Connected to: $curSSID" -ForegroundColor $(if ($isHs) { "Red" } else { "Green" })
            Write-Host "    BSSID: $bssid | Channel: $chan | Signal: $sig" -ForegroundColor Gray
            if ($isHs) { Write-Host "  WARNING: HOTSPOT DETECTED!" -ForegroundColor Red; $hsInd | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }; $suspAct+="Connected to hotspot: $curSSID" }
        }
    }
} catch {}

try {
    $hn   = netsh wlan show hostednetwork
    $hnSt = $hn | Select-String "Status\s+:\s+(.+)"
    if ($hnSt -and $hnSt.Matches.Groups[1].Value.Trim() -eq "Started") {
        $hnSM = $hn | Select-String 'SSID name\s+:\s+"(.+)"'
        $hnSSID = if ($hnSM) { $hnSM.Matches.Groups[1].Value } else { "Unknown" }
        Write-Host "  WARNING: Hosted Network ACTIVE! SSID: $hnSSID" -ForegroundColor Red
        $suspAct += "Hosted network active: $hnSSID"
    } else { Write-Host "  Hosted Network: Inactive" -ForegroundColor Green }
} catch {}

$ics = Get-Service -Name "icssvc" -ErrorAction SilentlyContinue
if ($ics) {
    if ($ics.Status -eq "Running") { Write-Host "  Mobile Hotspot (icssvc): RUNNING" -ForegroundColor Red; $suspAct+="icssvc running" }
    else { Write-Host "  Mobile Hotspot (icssvc): Stopped" -ForegroundColor Green }
}

try {
    $en = @(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true })
    $va = @($en | Where-Object { $_.Description -match "Hosted Network|Wi-Fi Direct" })
    $vm = @($en | Where-Object { $_.Description -match "VirtualBox|VMware|Hyper-V|TAP-|Wintun|WireGuard|OpenVPN|vEthernet" -and $_.Description -notmatch "Hosted Network|Wi-Fi Direct" })
    if ($va.Count -gt 0) { $va | ForEach-Object { Write-Host "  Hotspot adapter: $($_.Description)" -ForegroundColor Red }; $suspAct+="$($va.Count) hotspot adapter(s)" }
    else { Write-Host "  Hotspot adapters: None" -ForegroundColor Green }
    if ($vm.Count -gt 0) { $vm | ForEach-Object { Write-Host "  VM/VPN adapter (info): $($_.Description)" -ForegroundColor Gray } }
} catch {}

Write-Pink "`nVPN / TUNNEL"
try {
    $tunUp = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -match $tunRx })
    $vpnConn = @(Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq "Connected" })
    $vpnConn += @(Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq "Connected" })
    $vpnProcRx = "^(happ|happd|v2ray|v2rayn|xray|sing-box|wireguard|openvpn|openvpn-gui|nordvpn|protonvpn|clash|clash-verge|mihomo|hiddify|tailscaled|zerotier-one|outline|windscribe|expressvpn|surfshark|psiphon|lantern|amnezia.*)$"
    $vpnProcs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $vpnProcRx } | Select-Object -ExpandProperty Name -Unique)
    $defRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object { $_.RouteMetric + $_.InterfaceMetric } | Select-Object -First 1
    $defAd = if ($defRoute) { Get-NetAdapter -InterfaceIndex $defRoute.ifIndex -ErrorAction SilentlyContinue } else { $null }
    $viaTun = $defAd -and ($defAd.InterfaceDescription -match $tunRx)
    if ($tunUp.Count -eq 0 -and $vpnConn.Count -eq 0 -and $vpnProcs.Count -eq 0) {
        Write-Host "  VPN/proxy: not detected" -ForegroundColor Green
    } else {
        foreach ($t in $tunUp) { Write-Host ("  Tunnel adapter : {0} ({1})" -f $t.Name, $t.InterfaceDescription) -ForegroundColor Red }
        foreach ($c in $vpnConn) { Write-Host "  VPN connection : $($c.Name)" -ForegroundColor Red }
        if ($vpnProcs.Count -gt 0) { Write-Host "  VPN/proxy processes : $($vpnProcs -join ', ')" -ForegroundColor Red }
        $warns += "VPN/tunnel active"
    }
    if ($defAd) {
        Write-Host ("  Default route  : {0} -> {1}" -f $defAd.Name, $defRoute.NextHop) -ForegroundColor $(if ($viaTun) { "Red" } else { "White" })
        if ($viaTun) { Write-Host "  All traffic goes through the tunnel, real gateway is hidden" -ForegroundColor White }
    }
    $phys = @(Get-NetIPConfiguration -All -ErrorAction SilentlyContinue | Where-Object { $_.IPv4DefaultGateway -and $_.InterfaceDescription -notmatch $tunRx -and $_.InterfaceDescription -notmatch "VirtualBox|VMware|Hyper-V" })
    foreach ($pc in $phys) { Write-Host ("  Real uplink    : {0} via {1} ({2})" -f $pc.InterfaceAlias, $pc.IPv4DefaultGateway.NextHop, $pc.IPv4Address.IPAddress) -ForegroundColor White }
    if ($vpnProcs.Count -gt 0 -and $tunUp.Count -eq 0) { Write-Host "  Proxy-only client: traffic may be redirected without a tunnel adapter" -ForegroundColor Gray }
} catch { Write-Host "  Error reading VPN state" -ForegroundColor Red }

Write-Pink "`nVIRTUAL MACHINE (HARDWARE)"
try {
    $cs   = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $bb   = Get-CimInstance Win32_BaseBoard
    $vmRx = "VMware|VirtualBox|VBOX|QEMU|KVM|Xen|Hyper-V|Virtual Machine|Parallels|Bochs|innotek|Red Hat|oVirt|Proxmox|BHYVE|Google Compute|Amazon EC2|SeaBIOS|Microsoft Corporation.*Virtual|BXPC|VRTUAL|Alibaba Cloud|DigitalOcean|OpenStack"
    $strong = @(); $weak = @()
    $hw = [ordered]@{ "Manufacturer"=$cs.Manufacturer; "Model"=$cs.Model; "BIOS vendor"=$bios.Manufacturer; "BIOS version"=$bios.SMBIOSBIOSVersion; "Board"=("{0} {1}" -f $bb.Manufacturer, $bb.Product) }
    foreach ($k in $hw.Keys) { if ([string]$hw[$k] -match $vmRx) { $strong += "SMBIOS $k : $($hw[$k])" } }
    $sysBios = (Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System" -ErrorAction SilentlyContinue)
    foreach ($v in @($sysBios.SystemBiosVersion) + @($sysBios.VideoBiosVersion)) { if ([string]$v -match $vmRx) { $strong += "Registry BIOS : $v" } }
    foreach ($t in "DSDT","FADT","RSDT") {
        foreach ($k in @(Get-ChildItem "HKLM:\HARDWARE\ACPI\$t" -ErrorAction SilentlyContinue)) { if ($k.PSChildName -match "VBOX|VMWARE|BXPC|XEN|QEMU|PTLTD|Parallels|VRTUAL|BOCHS|AMAZON|GOOGLE") { $strong += "ACPI $t OEM : $($k.PSChildName)" } }
    }
    $gpu = @(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name)
    foreach ($g in $gpu) { if ($g -match "VMware SVGA|VirtualBox Graphics|VBoxVideo|QXL|Hyper-V Video|Parallels|Virtio|Microsoft Basic Render|Bochs|Cirrus") { $strong += "GPU : $g" } }
    $dsk = @(Get-CimInstance Win32_DiskDrive | Select-Object -ExpandProperty Model)
    foreach ($d in $dsk) { if ($d -match "VBOX|VMware|Virtual|QEMU|Msft|Red Hat|Xen|Google PersistentDisk|Amazon Elastic") { $strong += "Disk : $d" } }
    $vmOui = "^(00[:-]05[:-]69|00[:-]0C[:-]29|00[:-]1C[:-]14|00[:-]50[:-]56|08[:-]00[:-]27|52[:-]54[:-]00|00[:-]15[:-]5D|00[:-]1C[:-]42|00[:-]16[:-]3E)"
    foreach ($n in @(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.MACAddress -and $_.PNPDeviceID -like "PCI*" })) { if ($n.MACAddress -match $vmOui) { $strong += "NIC MAC : $($n.MACAddress) ($($n.Name))" } }
    $pnp = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "VEN_15AD|VEN_80EE|VEN_1AF4|VEN_1B36|VEN_5853|VEN_1AB8|VMBUS|VEN_1414&DEV_0008" })
    foreach ($p in ($pnp | Select-Object -First 5)) { $strong += "Virtual device : $($p.FriendlyName) [$($p.InstanceId)]" }
    $drvRx = "^(vboxguest|vboxsf|vboxmouse|vboxvideo|vmci|vmhgfs|vmmouse|vm3dmp|vmxnet3|vmware.*|viostor|netkvm|vioscsi|balloon|xenbus|xennet|qxl.*)$"
    foreach ($dr in @(Get-CimInstance Win32_SystemDriver | Where-Object { $_.Name -match $drvRx -and $_.State -eq "Running" })) { $strong += "Guest driver : $($dr.Name)" }
    foreach ($dr in @(Get-CimInstance Win32_SystemDriver | Where-Object { $_.Name -match "^(hv_vmbus|vmbus|storvsc|netvsc|vmgid)$" -and $_.State -eq "Running" })) { $strong += "Hyper-V guest driver : $($dr.Name)" }
    foreach ($rk in "HKLM:\SOFTWARE\VMware, Inc.\VMware Tools","HKLM:\SOFTWARE\Oracle\VirtualBox Guest Additions","HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters","HKLM:\SOFTWARE\Red Hat\VirtIO") { if (Test-Path $rk) { $strong += "Guest tools key : $rk" } }
    $guestSvc = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^(VMTools|VBoxService|vmicheartbeat|vmicshutdown|vmicvss|QEMU-GA|qemu-ga|xensvc|prl_tools_service)$" -and $_.Status -eq "Running" } | Select-Object -ExpandProperty Name)
    $guestProc = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^(vmtoolsd|vmwaretray|vmwareuser|VBoxService|VBoxTray|qemu-ga|prl_cc|prl_tools)$" } | Select-Object -ExpandProperty Name -Unique)
    if ($guestSvc.Count -gt 0) { $strong += "Guest services : $($guestSvc -join ', ')" }
    if ($guestProc.Count -gt 0) { $strong += "Guest processes : $($guestProc -join ', ')" }
    $hvHost = (Get-Service vmms,vmcompute -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }).Count -gt 0
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
    $vbsOn = $dg -and ($dg.VirtualizationBasedSecurityStatus -ge 1 -or @($dg.SecurityServicesRunning).Count -gt 0)
    $wslOn = (Get-Service WslService,LxssManager -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }).Count -gt 0 -or [bool](Get-Process wslservice,vmmem,vmmemWSL -ErrorAction SilentlyContinue)
    $hvExplained = $hvHost -or $vbsOn -or $wslOn
    if ($cs.HypervisorPresent -and -not $hvExplained) { $weak += "Hypervisor is running, but no Hyper-V host role, VBS or WSL explains it (hidden VM or cloaked hypervisor)" }
    $therm = @(Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue).Count
    if ($therm -eq 0 -and $cs.HypervisorPresent) { $weak += "No ACPI thermal zones with hypervisor present" }
    $cpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
    $ramGb = [math]::Round($cs.TotalPhysicalMemory/1GB, 1)
    Write-Host ("  System : {0} {1}" -f $cs.Manufacturer, $cs.Model) -ForegroundColor White
    Write-Host ("  BIOS   : {0} {1}" -f $bios.Manufacturer, $bios.SMBIOSBIOSVersion) -ForegroundColor White
    Write-Host ("  CPU    : {0} | RAM {1} GB" -f $cpuName.Trim(), $ramGb) -ForegroundColor White
    Write-Host ("  GPU    : {0}" -f ($gpu -join ', ')) -ForegroundColor White
    if ($strong.Count -gt 0) {
        Write-Host "  VERDICT: VIRTUAL MACHINE (confirmed, $($strong.Count) hard indicators)" -ForegroundColor Red
        $strong | Select-Object -Unique | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
        $flags += "Running inside a virtual machine ($($strong.Count) indicators)"
    } elseif ($weak.Count -gt 0) {
        Write-Host "  VERDICT: SUSPICIOUS (no hard VM markers, but the hypervisor is unexplained)" -ForegroundColor Red
        $weak | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
        $warns += "Possible hidden virtual machine"
    } else {
        Write-Host "  VERDICT: physical machine (no VM markers)" -ForegroundColor Green
        if ($cs.HypervisorPresent) {
            $why = @(); if ($hvHost) { $why += "Hyper-V host" }; if ($vbsOn) { $why += "VBS/Core isolation" }; if ($wslOn) { $why += "WSL" }
            Write-Host ("  Hypervisor layer present, explained by: {0}" -f ($why -join ', ')) -ForegroundColor Gray
        }
    }
} catch { Write-Host "  Error reading hardware info" -ForegroundColor Red }

Write-Pink "`nINSTALLED VM / VPN SOFTWARE"
try {
    $vmSoftRx  = "VMware|VirtualBox|Hyper-V|QEMU|Parallels|BlueStacks|Genymotion|Sandboxie|Windows Sandbox|LDPlayer|NoxPlayer|MEmu|Docker|Vagrant|Multipass|WSL|Windows Subsystem for Linux"
    $vpnSoftRx = "VPN|WireGuard|OpenVPN|NordVPN|Proton|ExpressVPN|Surfshark|Mullvad|Windscribe|Hiddify|v2ray|Xray|sing-box|Clash|Happ|Outline|Psiphon|Lantern|Tailscale|ZeroTier|Hamachi|Amnezia|WARP|TunnelBear|CyberGhost|Hotspot Shield|Shadowsocks|Nekoray|Throne|Netch"
    $uninstKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $apps = @(Get-ItemProperty $uninstKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion, InstallDate | Sort-Object DisplayName -Unique)
    $vmApps = @($apps | Where-Object { $_.DisplayName -match $vmSoftRx })
    $vpnApps = @($apps | Where-Object { $_.DisplayName -match $vpnSoftRx -and $_.DisplayName -notmatch $vmSoftRx })
    $svcHit = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^(vmms|vmcompute|VBoxSDS|VMAuthdService|VMnetDHCP|VMware NAT Service|WslService|LxssManager|docker|com\.docker\.service|WireGuardTunnel.*|OpenVPNService|Tailscale|ZeroTierOneService|WinTun.*)$" })
    $vmFeat = @()
    foreach ($fn in "Microsoft-Hyper-V-All","VirtualMachinePlatform","HypervisorPlatform","Containers-DisposableClientVM","Microsoft-Windows-Subsystem-Linux") {
        $ft = Get-CimInstance Win32_OptionalFeature -Filter "Name='$fn'" -ErrorAction SilentlyContinue
        if ($ft -and $ft.InstallState -eq 1) { $vmFeat += $fn }
    }
    if ($vmApps.Count -eq 0 -and $vmFeat.Count -eq 0) { Write-Host "  VM software : None found" -ForegroundColor Green }
    else {
        foreach ($a in $vmApps) { Write-Host ("  VM software : {0} {1}" -f $a.DisplayName, $a.DisplayVersion) -ForegroundColor Gray }
        foreach ($ft in $vmFeat) { Write-Host "  Windows feature on : $ft" -ForegroundColor Gray }
    }
    if ($vpnApps.Count -eq 0) { Write-Host "  VPN software : None found" -ForegroundColor Green }
    else { foreach ($a in $vpnApps) { Write-Host ("  VPN software : {0} {1}" -f $a.DisplayName, $a.DisplayVersion) -ForegroundColor Gray } }
    foreach ($sv in $svcHit) { Write-Host ("  Service : {0} [{1}]" -f $sv.Name, $sv.Status) -ForegroundColor $(if ($sv.Status -eq "Running") { "White" } else { "Gray" }) }
    $dirs = @("$env:ProgramFiles","${env:ProgramFiles(x86)}","$env:LOCALAPPDATA\Programs","$env:APPDATA","$env:LOCALAPPDATA")
    $dirRx = "^(Oracle|VirtualBox|VMware|Parallels|BlueStacks.*|Genymobile|WireGuard|OpenVPN|NordVPN|Proton.*|ExpressVPN|Surfshark|Mullvad.*|Windscribe|Hiddify.*|v2rayN|Xray|sing-box|Clash.*|Happ|FlyFrogLLC|Outline|Psiphon.*|Tailscale|ZeroTier|Amnezia.*|Cloudflare|TunnelBear|CyberGhost.*|nekoray|Throne)$"
    $dirHits = @()
    foreach ($d in $dirs) { if ($d -and (Test-Path -LiteralPath $d)) { $dirHits += @(Get-ChildItem -LiteralPath $d -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $dirRx } | ForEach-Object { $_.FullName }) } }
    foreach ($h in ($dirHits | Select-Object -Unique)) { Write-Host "  Folder : $h" -ForegroundColor Gray }
} catch { Write-Host "  Error searching installed software" -ForegroundColor Red }

# JAVA PROCESSES
Write-Pink "`nJAVA PROCESSES"
$jProcs = Get-Process -Name @("java","javaw") -ErrorAction SilentlyContinue
if (-not $jProcs) { Write-Host "  No java/javaw processes running" -ForegroundColor Green }
else {
    Write-Host "  Total java processes: $($jProcs.Count)" -ForegroundColor White
    $nsLines = netstat -ano | Select-String "LISTENING|ESTABLISHED"
    foreach ($jp in $jProcs) {
        Write-Host ""
        Write-Host ("  PID {0} | Started: {1}" -f $jp.Id, $jp.StartTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        try {
            $cl = (Get-WmiObject Win32_Process -Filter "ProcessId=$($jp.Id)").CommandLine
            if ($cl) {
                $sh = [regex]::Replace((Redact $cl), '(?<=\s)(-cp|-classpath|--class-path)\s+("[^"]+"|\S+)', { param($m) "{0} ({1} jars)" -f $m.Groups[1].Value, ($m.Groups[2].Value -split ';').Count })
                Write-Host "    CMD: $sh" -ForegroundColor Gray
            }
        } catch {}
        $pp = $nsLines | Where-Object { $_ -match "\s+$($jp.Id)\s*$" }
        if ($pp) {
            Write-Host "    Ports:" -ForegroundColor White
            $pp | ForEach-Object { Write-Host "      $($_.Line.Trim())" -ForegroundColor White }
        } else { Write-Host "    Ports: none found" -ForegroundColor Gray }
    }
}

# JVM ARGUMENTS
Write-Pink "`nJVM ARGUMENTS"
$jvmAny = $false
Get-CimInstance Win32_Process | Where-Object { $_.Name -in @("javaw.exe","java.exe") } | ForEach-Object {
    $cmd = $_.CommandLine
    if (-not $cmd) { return }
    $jvmArgs = $cmd -split ' (?=-)' | Where-Object {
        $_ -like "-Xmx*" -or $_ -like "-Xms*" -or $_ -like "-javaagent*" -or $_ -like "-Dfabric.addMods*" -or $_ -like "-Dloader.addMods*" -or
        $_ -like "-agentpath*" -or $_ -like "-agentlib*" -or $_ -like "-Xbootclasspath*" -or $_ -like "-noverify*" -or $_ -like "-Xverify:none*" -or $_ -like "-Djava.system.class.loader*"
    }
    if ($jvmArgs) {
        $jvmAny = $true
        Write-Host "  PID $($_.ProcessId)" -ForegroundColor White
        foreach ($a in $jvmArgs) {
            $t = $a.Trim()
            $bad = ($t -like "-javaagent*" -or $t -like "-D*addMods*" -or $t -like "-agentpath*" -or $t -like "-agentlib*" -or $t -like "-Xbootclasspath*" -or $t -like "-noverify*" -or $t -like "-Xverify:none*" -or $t -like "-Djava.system.class.loader*")
            $modrinthAgent = ($t -match '\\Temp\\\.tmp[^\\]+\\theseus\.jar$') -and ($cmd -match 'com\.modrinth\.theseus')
            if ($modrinthAgent) { Write-Host "    $t (Modrinth launcher agent, normal)" -ForegroundColor White; continue }
            Write-Host "    $t" -ForegroundColor $(if ($bad) { "Red" } else { "White" })
            if ($bad) { $flags += "JVM arg: $t" }
        }
    }
}
if (-not $jvmAny) { Write-Host "  No relevant JVM/mod arguments" -ForegroundColor Green }

# PROCESS TREE
Write-Pink "`nPROCESS TREE"
if (-not $mc) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $wmiMc = Get-CimInstance Win32_Process -Filter "ProcessId = $($mc.Id)"
        $parent = if ($wmiMc.ParentProcessId) { Get-Process -Id $wmiMc.ParentProcessId -ErrorAction SilentlyContinue } else { $null }
        $badNames = @("cmd","powershell","pwsh","wscript","cscript","rundll32","mshta","regsvr32")
        if ($parent) {
            $isBad = $badNames -contains $parent.ProcessName.ToLower()
            Write-Host ("  Parent : {0} (PID {1})" -f $parent.ProcessName, $parent.Id) -ForegroundColor $(if ($isBad) { "Red" } else { "White" })
            if ($isBad) { $flags += "Minecraft launched from $($parent.ProcessName)" }
        } else { Write-Host "  Parent : Unknown" -ForegroundColor Gray }
        $childs = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $mc.Id }
        if ($childs) {
            foreach ($c in $childs) {
                $cp = Get-Process -Id $c.ProcessId -ErrorAction SilentlyContinue
                if ($cp) {
                    $isBad = $badNames -contains $cp.ProcessName.ToLower()
                    Write-Host ("  Child  : {0} (PID {1}) {2}" -f $cp.ProcessName, $cp.Id, $cp.StartTime.ToString("HH:mm:ss")) -ForegroundColor $(if ($isBad) { "Red" } else { "White" })
                    if ($isBad) { $flags += "Suspicious child of Minecraft: $($cp.ProcessName)" }
                }
            }
        } else { Write-Host "  Child  : None" -ForegroundColor Green }
    } catch { Write-Host "  Error during process tree analysis" -ForegroundColor Red }
}

# LOADED DLLs
Write-Pink "`nJAVAW LOADED DLLs"
if (-not $mc) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $good = @(
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
        $mods = $mc.Modules | Sort-Object FileName
        $bad = @()
        foreach ($m in $mods) {
            $lp = $m.FileName.ToLower()
            $known = $false
            foreach ($g in $good) { if ($lp -like "*$g*") { $known = $true; break } }
            if (-not $known) { $bad += $m }
        }
        Write-Host "  Total DLLs: $($mods.Count)" -ForegroundColor White
        if ($bad.Count -eq 0) { Write-Host "  Unexpected: None" -ForegroundColor Green }
        else {
            Write-Host "  Unexpected: $($bad.Count) (can false flag)" -ForegroundColor Red
            foreach ($b in $bad) { Write-Host ("    {0,-32} {1}" -f $b.ModuleName, $b.FileName) -ForegroundColor White }
            $flags += "Unexpected DLLs in javaw ($($bad.Count))"
        }
    } catch { Write-Host "  Error reading DLL list" -ForegroundColor Red }
}

# BAM SINCE MC LAUNCH
Write-Pink "`nBAM SINCE MC LAUNCH"
if (-not $mc) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
else {
    try {
        $bamRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
        if (-not (Test-Path $bamRoot)) { $bamRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings" }
        if (-not (Test-Path $bamRoot)) { Write-Host "  BAM registry key not found" -ForegroundColor White }
        else {
            $hits = @()
            foreach ($sid in (Get-ChildItem -Path $bamRoot -ErrorAction SilentlyContinue)) {
                $entries = Get-ItemProperty -Path $sid.PSPath -ErrorAction SilentlyContinue
                if (-not $entries) { continue }
                foreach ($prop in $entries.PSObject.Properties) {
                    if ($prop.Name -match '^PS|SequenceNumber|Version') { continue }
                    if ($prop.Value -isnot [byte[]] -or $prop.Value.Length -lt 8) { continue }
                    try {
                        $ft = [BitConverter]::ToInt64($prop.Value, 0)
                        if ($ft -le 0) { continue }
                        $lastRun = [datetime]::FromFileTime($ft)
                        if ($lastRun -lt $mc.StartTime) { continue }
                        $exe = Split-Path ($prop.Name -replace '\\Device\\HarddiskVolume\d+','') -Leaf
                        $hits += [PSCustomObject]@{ Name=$exe; LastRun=$lastRun }
                    } catch { continue }
                }
            }
            $hits = $hits | Where-Object { $_.Name -notmatch '^javaw?\.exe$' } | Sort-Object LastRun -Descending
            if (-not $hits) { Write-Host "  No other executables ran since MC launch" -ForegroundColor Green }
            else {
                Write-Host "  Executables since MC launch: $($hits.Count)" -ForegroundColor White
                foreach ($h in $hits) {
                    $near = (($h.LastRun - $mc.StartTime).TotalSeconds -le 120)
                    $tag = if ($near) { " [within 2min]" } else { "" }
                    Write-Host ("    {0,-34} {1}{2}" -f $h.Name, $h.LastRun.ToString("HH:mm:ss"), $tag) -ForegroundColor $(if ($near) { "Red" } else { "White" })
                }
            }
        }
    } catch { Write-Host "  Error reading BAM entries" -ForegroundColor Red }
}

# LATE JAR INJECTION
Write-Pink "`nLATE JAR INJECTION"
if (-not $mc) { Write-Host "  Minecraft is not running" -ForegroundColor Gray }
elseif (-not (Test-Path $modsPath)) { Write-Host "  Mods folder not found" -ForegroundColor Gray }
else {
    try {
        $win = $mc.StartTime.AddMinutes(2)
        $jars = @(Get-ChildItem -Path $modsPath -Filter *.jar -Recurse -Force -ErrorAction SilentlyContinue)
        $laq = (fsutil behavior query disablelastaccess 2>&1 | Out-String)
        $laOff = ($laq -match '=\s*(\d)') -and ([int]$Matches[1] -in 1,3)
        if ($laOff) {
            $late = @($jars | Where-Object { $_.LastWriteTime -gt $win -or $_.CreationTime -gt $win })
            Write-Host "  Note: NTFS last-access updates are off, checking write/creation time instead" -ForegroundColor Gray
        } else {
            $late = @($jars | Where-Object { $_.LastAccessTime -gt $win })
        }
        Write-Host ("  MC started: {0} | grace until {1} | JARs: {2}" -f $mc.StartTime.ToString("HH:mm:ss"), $win.ToString("HH:mm:ss"), $jars.Count) -ForegroundColor White
        if ($late.Count -eq 0) { Write-Host "  No late-loaded JARs" -ForegroundColor Green }
        else {
            Write-Host "  Late-loaded JARs: $($late.Count)" -ForegroundColor Red
            foreach ($j in ($late | Sort-Object LastAccessTime -Descending)) {
                Write-Host ("    {0} | Accessed: {1}" -f $j.Name, $j.LastAccessTime.ToString("HH:mm:ss")) -ForegroundColor White
            }
            $flags += "Late-loaded JARs ($($late.Count))"
        }
    } catch { Write-Host "  Error during injection check" -ForegroundColor Red }
}

# MODS FOLDER FILES
Write-Pink "`nMODS FOLDER FILES"
if (-not (Test-Path $modsPath)) { Write-Host "  Mods folder not found" -ForegroundColor Gray }
else {
    $allF = @(Get-ChildItem -Path $modsPath -Recurse -Force -ErrorAction SilentlyContinue)
    $hidF = @(); $sysF = @(); $exeF = @()
    $badExt = @(".exe",".bat",".cmd",".scr",".vbs",".js",".ps1",".dll",".com",".pif")
    foreach ($f in $allF) {
        $isH = $f.Attributes -band [System.IO.FileAttributes]::Hidden
        $isS = $f.Attributes -band [System.IO.FileAttributes]::System
        if ($isH) { $hidF += $f }
        if ($isS) { $sysF += $f }
        if ($badExt -contains $f.Extension) { $exeF += $f }
    }
    Write-Host "  Total files: $($allF.Count)" -ForegroundColor White
    if ($hidF.Count -gt 0) { Write-Host "  Hidden: $($hidF.Count)" -ForegroundColor Red; $hidF | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $flags += "Hidden files in mods folder ($($hidF.Count))" }
    else { Write-Host "  Hidden: None" -ForegroundColor Green }
    if ($sysF.Count -gt 0) { Write-Host "  System: $($sysF.Count)" -ForegroundColor Red; $sysF | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $warns += "System files in mods folder ($($sysF.Count))" }
    else { Write-Host "  System: None" -ForegroundColor Green }
    if ($exeF.Count -gt 0) { Write-Host "  Executables: $($exeF.Count)" -ForegroundColor Red; $exeF | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White }; $flags += "Executables in mods folder ($($exeF.Count))" }
    else { Write-Host "  Executables: None" -ForegroundColor Green }
}

Write-Pink "`nBAM EXECUTION HISTORY"
$bamEntries = @()
try {
    $dosMap = @{}
    $driveTypes = @{}
    foreach ($dv in [System.IO.DriveInfo]::GetDrives()) {
        $letter = $dv.Name.Substring(0, 2)
        $driveTypes[$letter.ToUpper()] = $dv.DriveType
        $sb = New-Object System.Text.StringBuilder 520
        if ([ConsoleHelper]::QueryDosDevice($letter, $sb, 520) -gt 0) { $dosMap[$sb.ToString()] = $letter }
    }
    foreach ($root in @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings", "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings")) {
        if (-not (Test-Path $root)) { continue }
        foreach ($usr in (Get-ChildItem $root)) {
            foreach ($vn in $usr.GetValueNames()) {
                if ($vn -in @("Version","SequenceNumber")) { continue }
                $raw = $usr.GetValue($vn)
                if ($raw -is [byte[]] -and $raw.Length -ge 8) {
                    $ft = [BitConverter]::ToInt64($raw, 0)
                    if ($ft -le 0) { continue }
                    $path = $vn
                    foreach ($dk in $dosMap.Keys) { if ($path.StartsWith($dk + '\', [StringComparison]::OrdinalIgnoreCase)) { $path = $dosMap[$dk] + $path.Substring($dk.Length); break } }
                    $bamEntries += [PSCustomObject]@{ Time=[DateTime]::FromFileTimeUtc($ft).ToLocalTime(); Path=$path }
                }
            }
        }
    }
    if ($bamEntries.Count -eq 0) { Write-Host "  BAM is empty or unavailable" -ForegroundColor Red; $warns += "BAM empty" }
    else {
        $bamEntries = @($bamEntries | Where-Object { $_.Path -match '^[A-Za-z]:\\' } | Sort-Object Time -Descending)
        $oldest = ($bamEntries | Select-Object -Last 1).Time
        Write-Host ("  Entries : {0} (oldest {1})" -f $bamEntries.Count, $oldest.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
        if ($installDate -and $installDate -lt (Get-Date).AddDays(-7) -and $oldest -gt (Get-Date).AddDays(-2)) {
            Write-Host ("  BAM looks cleared : oldest entry {0}, Windows installed {1}" -f $oldest.ToString("yyyy-MM-dd"), $installDate.ToString("yyyy-MM-dd")) -ForegroundColor Red
            $flags += "BAM looks cleared (oldest entry $($oldest.ToString('yyyy-MM-dd')), installed $($installDate.ToString('yyyy-MM-dd')))"
        }
        $gone = @(); $offDrive = @()
        foreach ($be in $bamEntries) {
            $dl = $be.Path.Substring(0, 2).ToUpper()
            $state = "ok"
            if (-not (Test-Path -LiteralPath $be.Path)) { $state = if ($driveTypes.ContainsKey($dl)) { "DELETED" } else { "DRIVE GONE" } }
            elseif ($driveTypes[$dl] -eq "Removable") { $state = "ON USB" }
            $be | Add-Member -NotePropertyName Status -NotePropertyValue $state -Force
            if ($state -in @("DELETED","DRIVE GONE") -and $be.Path -notmatch '\\Windows\\') { $gone += $be }
            if ($state -in @("DRIVE GONE","ON USB")) { $offDrive += $be }
        }
        Write-Host "  Last 25 executions" -ForegroundColor White
        foreach ($be in ($bamEntries | Select-Object -First 25)) {
            $col = if ($be.Path -match $cheatRx -or $be.Status -ne "ok") { "Red" } else { "Gray" }
            Write-Host ("    {0}  {1,-10} {2}" -f $be.Time.ToString("MM-dd HH:mm:ss"), $be.Status, $be.Path) -ForegroundColor $col
        }
        foreach ($be in @($bamEntries | Where-Object { $_.Path -match $cheatRx } | Select-Object -First 10)) { Write-Host ("  Cheat name in BAM : {0}  {1}" -f $be.Time.ToString("MM-dd HH:mm"), $be.Path) -ForegroundColor Red; $flags += "BAM match $($be.Path)" }
        if ($offDrive.Count -gt 0) { Write-Host "  Run from removable/disconnected drive : $($offDrive.Count)" -ForegroundColor Red; $warns += "Programs run from removable drive ($($offDrive.Count))" }
        if ($gone.Count -gt 0) {
            Write-Host "  Executed files no longer on disk : $($gone.Count)" -ForegroundColor Red
            foreach ($be in ($gone | Select-Object -First 25)) { Write-Host ("    {0}  {1,-10} {2}" -f $be.Time.ToString("MM-dd HH:mm"), $be.Status, $be.Path) -ForegroundColor White }
        } else { Write-Host "  All executed files still exist" -ForegroundColor Green }
    }
} catch { Write-Host "  Error reading BAM history" -ForegroundColor Red }

Write-Pink "`nSUSPICIOUS PROCESSES"
try {
    $procList = @(Get-CimInstance Win32_Process)
    $procHit = $false
    foreach ($pr in $procList) {
        $pn = ($pr.Name -replace '\.exe$', '')
        $cat = $null; $isFlag = $true
        if ($pn -match $remoteRx) { $cat = "Remote access" }
        elseif ($pn -match $debugRx) { $cat = "Debug/inject tool" }
        elseif ($pn -match $vmProcRx) { $cat = "Virtualization"; $isFlag = $false }
        elseif ($pn -match $cheatRx) { $cat = "Cheat name" }
        if ($cat) {
            $procHit = $true
            Write-Host ("  {0} : {1} (PID {2}) {3}" -f $cat, $pr.Name, $pr.ProcessId, $pr.ExecutablePath) -ForegroundColor $(if ($isFlag) { "Red" } else { "Gray" })
            if ($isFlag) { $flags += "$cat $($pr.Name)" }
        }
    }
    foreach ($wp in (Get-Process | Where-Object { $_.MainWindowTitle })) {
        if ($wp.MainWindowTitle -match $cheatRx -or $wp.MainWindowTitle -match $debugRx) { $procHit = $true; Write-Host ("  Window title match : '{0}' ({1})" -f $wp.MainWindowTitle, $wp.ProcessName) -ForegroundColor Red; $flags += "Window title match $($wp.MainWindowTitle)" }
    }
    $riskDirs = '\\(Temp|Downloads|Desktop|Public|\$Recycle\.Bin)\\'
    $riskProcs = @($procList | Where-Object { $_.ExecutablePath -and $_.ExecutablePath -match $riskDirs -and $_.ProcessId -ne $PID })
    if ($riskProcs.Count -gt 0) {
        $procHit = $true
        Write-Host "  Running from Temp/Downloads/Desktop : $($riskProcs.Count)" -ForegroundColor Red
        foreach ($pr in ($riskProcs | Select-Object -First 15)) { Write-Host ("    {0} [{1}] {2}" -f $pr.Name, (Get-Sig $pr.ExecutablePath), $pr.ExecutablePath) -ForegroundColor White }
    }
    if (-not $procHit) { Write-Host "  No suspicious processes" -ForegroundColor Green }
} catch { Write-Host "  Error reading processes" -ForegroundColor Red }

Write-Pink "`nBOOT SECURITY AND DRIVERS"
try {
    $bcd = (bcdedit /enum '{current}' 2>&1 | Out-String)
    if ($bcd -match '(?im)^\s*testsigning\s+(Yes|\S*\u0414\u0430)') { Write-Host "  Test Signing : ON" -ForegroundColor Red; $flags += "Test signing is on" } else { Write-Host "  Test Signing : Off" -ForegroundColor Green }
    if ($bcd -match '(?im)^\s*nointegritychecks\s+(Yes|\S*\u0414\u0430)') { Write-Host "  Integrity Checks : DISABLED" -ForegroundColor Red; $flags += "Driver integrity checks disabled" }
    try { $sbOn = Confirm-SecureBootUEFI -ErrorAction Stop; Write-Host "  Secure Boot : $(if ($sbOn) { 'On' } else { 'Off' })" -ForegroundColor $(if ($sbOn) { "Green" } else { "White" }) } catch { Write-Host "  Secure Boot : Not supported" -ForegroundColor Gray }
    $sysDrivers = @(Get-CimInstance Win32_SystemDriver)
    $badDrivers = @($sysDrivers | Where-Object { $_.Name -match $badDrvRx -or ([IO.Path]::GetFileNameWithoutExtension(([string]$_.PathName).Trim('"')) -match $badDrvRx) })
    if ($badDrivers.Count -gt 0) { foreach ($bd in $badDrivers) { Write-Host ("  Known cheat/vulnerable driver : {0} [{1}] {2}" -f $bd.Name, $bd.State, $bd.PathName) -ForegroundColor Red; $flags += "Vulnerable driver $($bd.Name)" } }
    else { Write-Host "  Vulnerable drivers : None" -ForegroundColor Green }
    $unsigned = 0
    foreach ($sd in @($sysDrivers | Where-Object { $_.State -eq "Running" -and $_.PathName -and $_.PathName -notmatch '(?i)\\system32\\drivers\\|\\DriverStore\\|\\SystemRoot\\system32\\drivers\\' } | Select-Object -First 80)) {
        $dpath = ([string]$sd.PathName) -replace '^\\\?\?\\', '' -replace '^\\SystemRoot', $env:SystemRoot -replace '^"|"$', ''
        if (-not (Test-Path -LiteralPath $dpath)) { continue }
        $sig = Get-Sig $dpath
        if ($sig -ne "Valid") { $unsigned++; Write-Host ("  Driver not validly signed : {0} [{1}] {2}" -f $sd.Name, $sig, $dpath) -ForegroundColor Red; $warns += "Unsigned driver $($sd.Name)" }
    }
    if ($unsigned -eq 0) { Write-Host "  Unsigned drivers : None" -ForegroundColor Green }
} catch { Write-Host "  Error reading boot/driver info" -ForegroundColor Red }

# MOD ANALYZER
$suspiciousPatterns = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand",
    "AutoHitCrystal","AutoPot","AutoTotem","AutoArmor","InventoryTotem",
    "Hitboxes","JumpReset","LegitTotem","PingSpoof","SelfDestruct",
    "ShieldBreaker","TriggerBot","Velocity","AxeSpam","WebMacro",
    "FastPlace","WalskyOptimizer","WalksyOptimizer","walsky.optimizer",
    "WalksyCrystalOptimizerMod","Donut","Reach","ShieldDisabler","SilentAim",
    "Wtap","FakeLag","BlockESP","dev.krypton","AntiMissClick",
    "LagReach","PopSwitch","SprintReset","ChestSteal","AntiBot",
    "ElytraSwap","FastXP","FastExp","NoJumpDelay","AirAnchor",
    "jnativehook","FakeInv","HoverTotem","AutoClicker","AutoFirework",
    "PackSpoof","Antiknockback","scrim","catlean","Argon",
    "AuthBypass","Asteria","Prestige","AutoEat","AutoMine",
    "MaceSwap","DoubleAnchor","AutoTPA","BaseFinder","Xenon",
    "imgui.gl3","imgui.glfw","BowAim","Criticals","Flight","Fakenick","FakeItem",
    "invsee","ItemExploit","Hellion","LicenseCheckMixin",
    "ClientPlayerInteractionManagerAccessor","ClientPlayerEntityMixim",
    "dev.gambleclient","obfuscatedAuth","phantom-refmap.json","xyz.greaj"
)
$cheatStrings = @(
    "AutoCrystal","autocrystal","auto crystal","dontPlaceCrystal","dontBreakCrystal",
    "AutoHitCrystal","canPlaceCrystalServer","healPotSlot",
    "AutoAnchor","autoanchor","DoubleAnchor","hasGlowstone","HasAnchor","anchortweaks","safeanchor",
    "AutoTotem","autototem","InventoryTotem","HoverTotem","legittotem",
    "AutoPot","autopot","speedPotSlot","strengthPotSlot","AutoArmor","autoarmor",
    "preventSwordBlockBreaking","preventSwordBlockAttack","AutoDoubleHand","autodoublehand",
    "AutoClicker","Failed to switch to mace after axe!","Breaking shield with axe...",
    "JumpReset","axespam","shieldbreaker","EndCrystalItemMixin",
    "findKnockbackSword","attackRegisteredThisClick","AimAssist","aimassist",
    "triggerbot","FakeInv","swapBackToOriginalSlot","FakeLag","pingspoof",
    "webmacro","selfdestruct","AutoMace","AutoFirework","MaceSwap","AirAnchor",
    "ElytraSwap","FastXP","FastExp","NoJumpDelay","PackSpoof","Antiknockback",
    "AuthBypass","obfuscatedAuth","LicenseCheckMixin","BaseFinder","invsee",
    "ItemExploit","NoFall","nofall","WalksyCrystalOptimizerMod","WalksyOptimizer",
    "autoCrystalPlaceClock","setBlockBreakingCooldown","getBlockBreakingCooldown",
    "onBlockBreaking","setItemUseCooldown","setSelectedSlot","invokeDoAttack",
    "invokeDoItemUse","invokeOnMouseButton","onTickMovement","onPushOutOfBlocks",
    "onIsGlowing","POT_CHEATS","Entity.isGlowing"
)

function Get-Source {
    param([string]$Path)
    $z = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($z -match "HostUrl=(.+)") {
        $u = $matches[1].Trim()
        if ($u -match "mediafire\.com") { return "MediaFire" }
        elseif ($u -match "discord") { return "Discord" }
        elseif ($u -match "dropbox\.com") { return "Dropbox" }
        elseif ($u -match "drive\.google\.com") { return "Google Drive" }
        elseif ($u -match "mega\.(nz|co\.nz)") { return "MEGA" }
        elseif ($u -match "github\.com") { return "GitHub" }
        elseif ($u -match "modrinth\.com") { return "Modrinth" }
        elseif ($u -match "curseforge\.com") { return "CurseForge" }
        elseif ($u -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
        else { return $u }
    }
    return $null
}
function Query-Modrinth {
    param([string]$Hash)
    try {
        $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -UseBasicParsing -ErrorAction Stop
        if ($v.project_id) {
            $p = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($v.project_id)" -UseBasicParsing -ErrorAction Stop
            return $p.title
        }
    } catch {}
    return $null
}
function Query-Megabase {
    param([string]$Hash)
    try {
        $r = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -UseBasicParsing -ErrorAction Stop
        if (-not $r.error) { return $r.data.name }
    } catch {}
    return $null
}
function Invoke-ModScan {
    param([string]$FilePath, $Rx)
    $pat = [System.Collections.Generic.HashSet[string]]::new()
    $str = [System.Collections.Generic.HashSet[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($e in $zip.Entries) {
            foreach ($m in $Rx.Matches($e.FullName)) { [void]$pat.Add($m.Value) }
            if ($e.FullName -match '\.(class|json)$' -or $e.FullName -match 'MANIFEST\.MF') {
                try {
                    $s = $e.Open(); $r = New-Object System.IO.StreamReader($s)
                    $c = $r.ReadToEnd(); $r.Close(); $s.Close()
                    foreach ($m in $Rx.Matches($c)) { [void]$pat.Add($m.Value) }
                    foreach ($cs in $cheatStrings) { if ($c -match [regex]::Escape($cs)) { [void]$str.Add($cs) } }
                } catch {}
            }
        }
        $zip.Dispose()
    } catch {}
    return @{ Patterns = $pat; Strings = $str }
}
function Invoke-BypassScan {
    param([string]$FilePath)
    $f = @()
    $mavenPfx = @("com_","org_","net_","io_","dev_","gs_","xyz_","app_","me_","tv_","uk_","be_","fr_","de_")
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $nested = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outer  = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })
        foreach ($nj in $nested) {
            $b = [System.IO.Path]::GetFileNameWithoutExtension($nj.FullName)
            if ($b -match '\d') { continue }
            if ($b.Length -gt 20) { continue }
            $skip = $false
            foreach ($p in $mavenPfx) { if ($b.ToLower().StartsWith($p)) { $skip = $true; break } }
            if (-not $skip) { $f += "Suspicious nested JAR: $b.jar" }
        }
        if ($nested.Count -eq 1 -and $outer.Count -lt 3) {
            $f += "Hollow shell - $($outer.Count) own class(es), wraps $([System.IO.Path]::GetFileName($nested[0].FullName))"
        }
        $modId = ""
        $fmj = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
        if ($fmj) {
            try {
                $s = $fmj.Open(); $r = New-Object System.IO.StreamReader($s)
                $t = $r.ReadToEnd(); $r.Close(); $s.Close()
                if ($t -match '"id"\s*:\s*"([^"]+)"') { $modId = $matches[1] }
            } catch {}
        }
        $all = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $all.Add($e) }
        $inner = [System.Collections.Generic.List[object]]::new()
        foreach ($nj in $nested) {
            try {
                $ns = $nj.Open(); $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $inner.Add($iz)
                foreach ($ie in $iz.Entries) { $all.Add($ie) }
            } catch {}
        }
        $exec = $false; $dl = $false; $exfil = $false; $obf = 0; $cnt = 0
        foreach ($e in $all) {
            if ($e.FullName -notmatch "\.class$") { continue }
            $cnt++
            $segs = ($e.FullName -replace "\.class$","") -split "/"
            $run = 0; $max = 0
            foreach ($sg in $segs) {
                if ($sg.Length -eq 1) { $run++; if ($run -gt $max) { $max = $run } } else { $run = 0 }
            }
            if ($max -ge 3) { $obf++ }
            try {
                $st = $e.Open(); $ms2 = New-Object System.IO.MemoryStream
                $st.CopyTo($ms2); $st.Close()
                $ct = [System.Text.Encoding]::ASCII.GetString($ms2.ToArray()); $ms2.Dispose()
                if ($ct -match "java/lang/Runtime" -and $ct -match "getRuntime" -and $ct -match "exec") { $exec = $true }
                if ($ct -match "openConnection" -and $ct -match "HttpURLConnection" -and $ct -match "FileOutputStream") { $dl = $true }
                if ($ct -match "openConnection" -and $ct -match "setDoOutput" -and $ct -match "getOutputStream" -and $ct -match "getProperty") { $exfil = $true }
            } catch {}
        }
        foreach ($iz in $inner) { try { $iz.Dispose() } catch {} }
        $zip.Dispose()
        $pct = if ($cnt -ge 10) { [math]::Round(($obf / $cnt) * 100) } else { 0 }
        if ($exec -and $pct -ge 40) { $f += "Runtime.exec() inside obfuscated code" }
        if ($dl)    { $f += "HTTP file download at runtime" }
        if ($exfil) { $f += "HTTP POST exfiltration (system properties sent out)" }
        if ($pct -ge 40) { $f += "Heavy obfuscation ($pct% of classes)" }
        $legit = @("vmp-fabric","vmp","lithium","sodium","iris","fabric-api","modmenu","ferrite-core","lazydfu","starlight","entityculling","memoryleakfix","krypton","c2me-fabric","smoothboot-fabric","immediatelyfast","noisium","threadtweak")
        if ($modId -and ($legit -contains $modId) -and $f.Count -gt 0) { $f += "Fake identity - claims to be '$modId'" }
    } catch {}
    return $f
}

Write-Pink "`nMOD ANALYZER"
$verified = @(); $unknown = @(); $suspMods = @(); $bypassMods = @()
if (-not (Test-Path $modsPath)) { Write-Host "  Mods folder not found" -ForegroundColor Gray }
else {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $jarFiles = @(Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction SilentlyContinue)
    if ($jarFiles.Count -eq 0) { Write-Host "  No JAR files found" -ForegroundColor Green }
    else {
        $rx = [regex]::new('(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $i = 0
        foreach ($jar in $jarFiles) {
            $i++
            Write-Host ("`r  Scanning {0}/{1} ..." -f $i, $jarFiles.Count) -NoNewline -ForegroundColor Gray
            $hash = (Get-FileHash -Path $jar.FullName -Algorithm SHA1).Hash
            $name = Query-Modrinth $hash
            if (-not $name) { $name = Query-Megabase $hash }

            $scan = Invoke-ModScan -FilePath $jar.FullName -Rx $rx
            $byp  = Invoke-BypassScan -FilePath $jar.FullName

            if ($byp.Count -gt 0) { $bypassMods += [PSCustomObject]@{ File=$jar.Name; Flags=$byp } }
            elseif ($scan.Patterns.Count -gt 0 -or $scan.Strings.Count -gt 0) { $suspMods += [PSCustomObject]@{ File=$jar.Name; Patterns=$scan.Patterns; Strings=$scan.Strings } }
            elseif ($name) { $verified += [PSCustomObject]@{ Mod=$name; File=$jar.Name } }
            else { $unknown += [PSCustomObject]@{ File=$jar.Name; Source=(Get-Source $jar.FullName) } }
        }
        Write-Host ("`r{0}`r" -f (' ' * 40)) -NoNewline

        Write-Host "  Scanned: $($jarFiles.Count)" -ForegroundColor White
        if ($verified.Count -gt 0) {
            Write-Host "  Verified: $($verified.Count)" -ForegroundColor Green
            foreach ($m in $verified) { Write-Host ("    {0} -> {1}" -f $m.Mod, $m.File) -ForegroundColor Gray }
        }
        if ($unknown.Count -gt 0) {
            Write-Host "  Unknown: $($unknown.Count)" -ForegroundColor White
            foreach ($m in $unknown) {
                $src = if ($m.Source) { $m.Source } else { "?" }
                Write-Host ("    {0} | src: {1}" -f $m.File, $src) -ForegroundColor White
            }
            $warns += "Unknown mods ($($unknown.Count))"
        }
        if ($suspMods.Count -gt 0) {
            Write-Host "  Suspicious: $($suspMods.Count)" -ForegroundColor Red
            foreach ($m in $suspMods) {
                Write-Host "    $($m.File)" -ForegroundColor Red
                if ($m.Patterns.Count -gt 0) { Write-Host ("      patterns: {0}" -f (($m.Patterns | Sort-Object) -join ', ')) -ForegroundColor White }
                $uniq = $m.Strings | Where-Object { $m.Patterns -notcontains $_ } | Sort-Object
                if ($uniq.Count -gt 0) { Write-Host ("      strings : {0}" -f ($uniq -join ', ')) -ForegroundColor White }
            }
            $flags += "Suspicious mods ($($suspMods.Count))"
        }
        if ($bypassMods.Count -gt 0) {
            Write-Host "  Bypass/Injection: $($bypassMods.Count)" -ForegroundColor Red
            foreach ($m in $bypassMods) {
                Write-Host "    $($m.File)" -ForegroundColor Red
                foreach ($fl in $m.Flags) { Write-Host "      $fl" -ForegroundColor White }
            }
            $flags += "Bypass/injected mods ($($bypassMods.Count))"
        }
        if ($suspMods.Count -eq 0 -and $bypassMods.Count -eq 0) { Write-Host "  No suspicious mods detected" -ForegroundColor Green }
    }
}

# COMMAND HISTORY
Write-Pink "`nCOMMAND HISTORY"
$badCmds = @(
    "powershell -enc","-encodedcommand","certutil -decode","certutil -urlcache",
    "bitsadmin /transfer","Invoke-WebRequest","irm ","curl -o","wget -O",
    "rundll32","regsvr32","mshta","wscript","cscript",
    "taskkill /f","Stop-Process -Force","LoadLibrary","VirtualAlloc","WriteProcessMemory",
    "reg add","reg delete","wevtutil","bcdedit","attrib +h","attrib +s","cipher /w",
    "inject","bypass","crack","trainer","aimbot","wallhack","autoclicker",
    "IEX","Invoke-Expression","Start-BitsTransfer","DownloadString","DownloadFile","FromBase64String"
)
$since = if ($mc) { $mc.StartTime } else { (Get-Date).AddHours(-2) }
Write-Host ("  Window: since {0}" -f $since.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
$psHits = @()
if (Test-Path $hPath) {
    $hf = Get-Item $hPath -Force
    if ($hf.LastWriteTime -ge $since) {
        $lines = @(Get-Content $hPath -ErrorAction SilentlyContinue | Select-Object -Last 40)
        foreach ($ln in $lines) {
            if ([string]::IsNullOrWhiteSpace($ln)) { continue }
            if ($ln -match "Y-sysinfo|check\.ps1") { continue }
            foreach ($p in $badCmds) {
                if ($ln -like "*$p*") { $psHits += [PSCustomObject]@{ Pattern=$p; Cmd=$ln.Trim() }; break }
            }
        }
        if ($psHits.Count -gt 0) {
            Write-Host "  Suspicious PS commands: $($psHits.Count)" -ForegroundColor Red
            foreach ($h in $psHits) {
                $c = if ($h.Cmd.Length -gt 110) { $h.Cmd.Substring(0,107)+"..." } else { $h.Cmd }
                Write-Host ("    [{0}] {1}" -f $h.Pattern, $c) -ForegroundColor White
            }
            $flags += "Suspicious PowerShell commands ($($psHits.Count))"
        } else { Write-Host "  PowerShell history: clean" -ForegroundColor Green }
    } else { Write-Host "  PowerShell history: not written since window start" -ForegroundColor Green }
} else { Write-Host "  PowerShell history: file not found" -ForegroundColor White }

$cmdHits = @()
try {
    $pcEvents = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4688; StartTime=$since} -MaxEvents 200 -ErrorAction SilentlyContinue
    if ($pcEvents) {
        foreach ($ev in $pcEvents) {
            if ($ev.TimeCreated -ge $selfStart) { continue }
            $line = ($ev.Message -split "`n" | Select-String "Process Command Line|New Process Name")
            $txt = ($line -join " ").Trim()
            if (-not $txt) { continue }
            if ($txt -match 'bcdedit(\.exe)?"?\s+/enum') { continue }
            foreach ($p in $badCmds) { if ($txt -like "*$p*") { $cmdHits += $txt; break } }
        }
        if ($cmdHits.Count -gt 0) {
            Write-Host "  Suspicious process creations: $($cmdHits.Count)" -ForegroundColor Red
            $cmdHits | Select-Object -Unique -First 15 | ForEach-Object {
                $c = if ($_.Length -gt 110) { $_.Substring(0,107)+"..." } else { $_ }
                Write-Host "    $c" -ForegroundColor White
            }
            $flags += "Suspicious process creations ($($cmdHits.Count))"
        } else { Write-Host "  Process creation events: clean" -ForegroundColor Green }
    } else { Write-Host "  Process creation events: not available (audit off)" -ForegroundColor White }
} catch { Write-Host "  Process creation events: not available" -ForegroundColor White }

try {
    $sbEvents = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-PowerShell/Operational"; Id=4104; StartTime=$since} -MaxEvents 100 -ErrorAction SilentlyContinue
    if ($sbEvents) {
        $sbHits = @()
        foreach ($ev in $sbEvents) {
            $m = $ev.Message
            if ($ev.TimeCreated -ge $selfStart) { continue }
            if ($m -match "Y-sysinfo|check\.ps1") { continue }
            foreach ($p in $badCmds) { if ($m -like "*$p*") { $sbHits += $ev; break } }
        }
        if ($sbHits.Count -gt 0) {
            Write-Host "  Suspicious script blocks: $($sbHits.Count)" -ForegroundColor Red
            foreach ($ev in ($sbHits | Select-Object -First 10)) {
                Write-Host ("    {0} | {1}" -f $ev.TimeCreated.ToString("HH:mm:ss"), (($ev.Message -split "`n")[0]).Trim()) -ForegroundColor White
            }
            $flags += "Suspicious PowerShell script blocks ($($sbHits.Count))"
        } else { Write-Host "  Script block logs: clean" -ForegroundColor Green }
    }
} catch {}

Write-Pink "`nLOGGING INTEGRITY"
try {
    if ($evFrozen) {
        Write-Host "  EventLog query test : No response in 10 s (service frozen)" -ForegroundColor Red
        $flags += "EventLog does not answer queries (service Running but frozen)"
    } else {
        Write-Host "  EventLog query test : Answered" -ForegroundColor Green
    }
    $canary = [guid]::NewGuid().ToString()
    $canaryAt = Get-Date
    $ecProc = Start-Process -FilePath "$env:SystemRoot\System32\eventcreate.exe" -ArgumentList @('/L','APPLICATION','/T','INFORMATION','/ID','999','/D',('"Y-sysinfo logging canary {0}"' -f $canary)) -WindowStyle Hidden -PassThru
    $ecHung = -not $ecProc.WaitForExit(6000)
    if ($ecHung) { try { $ecProc.Kill() } catch {} }
    if ($ecHung) { Write-Host "  EventLog write test : eventcreate did not return in 6 s (service frozen)" -ForegroundColor Red; $flags += "EventLog does not accept events (eventcreate hangs)" }
    else {
        $seen = $false
        for ($attempt = 0; $attempt -lt 8 -and -not $seen; $attempt++) {
            Start-Sleep -Milliseconds 500
            $back = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='eventcreate'; Id=999; StartTime=$canaryAt.AddSeconds(-2)} -MaxEvents 20 -ErrorAction SilentlyContinue
            foreach ($be in @($back)) { if ($be -and $be.Message -like "*$canary*") { $seen = $true; break } }
        }
        if ($seen) { Write-Host "  EventLog write test : Event written and read back" -ForegroundColor Green }
        else {
            Write-Host "  EventLog write test : Event NOT written (service Running but not logging)" -ForegroundColor Red
            $flags += "EventLog is Running but does not write events"
        }
    }
    $pfAll = @(Get-ChildItem "$env:SystemRoot\Prefetch" -Filter *.pf -Force -ErrorAction SilentlyContinue)
    $pfFresh = @($pfAll | Where-Object { $_.Name -match '^(FSUTIL|NETSH|FINDSTR|BCDEDIT|CMD|POWERSHELL)\.EXE-' -and $_.LastWriteTime -ge $scriptStart } | Sort-Object LastWriteTime -Descending)
    if ($pfFresh.Count -gt 0) {
        Write-Host ("  Prefetch write test : {0} updated {1}" -f $pfFresh[0].Name, $pfFresh[0].LastWriteTime.ToString("HH:mm:ss")) -ForegroundColor Green
    } else {
        Write-Host "  Prefetch write test : No .pf updated since script start" -ForegroundColor Red
        $flags += "Prefetch is not updating (SysMain bypass or disabled)"
    }
    if (@($bamEntries).Count -eq 0) { Write-Host "  BAM write test : BAM data unavailable" -ForegroundColor Gray }
    else {
        $self = Get-Process -Id $PID
        $selfExe = $self.Path
        $selfBam = @($bamEntries | Where-Object { $_.Path -ieq $selfExe } | Sort-Object Time -Descending | Select-Object -First 1)
        if ($selfBam.Count -gt 0 -and $selfBam[0].Time -ge $self.StartTime.AddSeconds(-15)) {
            Write-Host ("  BAM write test : {0} recorded {1}" -f (Split-Path $selfExe -Leaf), $selfBam[0].Time.ToString("HH:mm:ss")) -ForegroundColor Green
        } else {
            Write-Host "  BAM write test : No fresh BAM entry for this PowerShell process" -ForegroundColor Red
            $flags += "BAM is not recording new executions"
        }
    }
    $infoRx = 'systeminformer|processhacker'
    $infoTraces = 0
    foreach ($pf in @($pfAll | Where-Object { $_.Name -match $infoRx })) {
        Write-Host ("  System Informer / Process Hacker trace : {0} {1}" -f $pf.LastWriteTime.ToString("MM-dd HH:mm"), $pf.Name) -ForegroundColor Red
        $infoTraces++
    }
    foreach ($be in @($bamEntries | Where-Object { $_.Path -match $infoRx })) {
        Write-Host ("  System Informer / Process Hacker trace : {0} {1}" -f $be.Time.ToString("MM-dd HH:mm"), $be.Path) -ForegroundColor Red
        $infoTraces++
    }
    if ($infoTraces -gt 0) { $flags += "System Informer / Process Hacker was run on this PC" }
    else { Write-Host "  System Informer / Process Hacker traces : None" -ForegroundColor Green }
} catch { Write-Host "  Error during logging integrity check" -ForegroundColor Red }

function Invoke-Ps4104Hunt {
$days = 0
$ErrorActionPreference = 'Stop'
$logName = 'Microsoft-Windows-PowerShell/Operational'
$reportFile = Join-Path $papaDir 'PWSHOperational.txt'
if (-not (Test-Path -LiteralPath $papaDir)) { New-Item -ItemType Directory -Path $papaDir -Force | Out-Null }

function _s([int[]]$Codes) { -join ($Codes | ForEach-Object { [char]$_ }) }

function Test-IsDefenderModuleNoise {
  param([string]$Code)
  if ([string]::IsNullOrWhiteSpace($Code)) { return $false }

  if ($Code.Length -lt 6000) {
    if ($Code -match '(?im)^\s*(Set-MpPreference|Add-MpPreference|Remove-MpPreference)\s+') { return $false }
    if ($Code -match '(?i)(Set|Add)-MpPreference[^`{]{0,500}?(-DisableRealtimeMonitoring|-ExclusionPath|-ExclusionProcess)\s+\$?(true|\w|:)') { return $false }
  }

  if ($Code -match '__cmdletization|MSFT_MpPreference|GeneratedTypes\.MpPreference') { return $true }
  if ($Code -match 'function\s+(Set|Remove|Add|Get)-MpPreference\s*\{') { return $true }
  if ($Code -match 'Microsoft\.PowerShell\.Cmdletization\.MethodParameter') { return $true }
  if ($Code -match "Parameter\(ParameterSetName='(Remove2|Set0|Add1)'\)" -and $Code -match '\$\{DisableRealtimeMonitoring\}' -and $Code -match '\[ValidateNotNull') { return $true }

  $paramCount = ([regex]::Matches($Code, '\[Parameter\(')).Count
  if ($paramCount -ge 6 -and $Code -match 'DisableRealtimeMonitoring' -and $Code -match '(ExclusionPath|DisableScriptScanning)') { return $true }

  return $false
}

function Test-IsWindowsMaintenanceNoise {
  param([string]$Code)
  if ($Code -match 'CL_LocalizationData|Get-UserTSHistoryPath|Update-DiagReport|Import-LocalizedData.*CL_Localization') { return $true }
  if ($Code -match 'Copyright \(c\) Microsoft Corporation' -and $Code -match 'Get-FolderSize|Delete-OldFolders') { return $true }
  return $false
}

function Get-BlockVerdict {
  param([string]$Code, [int]$Score)
  if (Test-IsDefenderModuleNoise -Code $Code) { return 'NOISE-DEFENDER' }
  if (Test-IsWindowsMaintenanceNoise -Code $Code) { return 'NOISE-WINDOWS' }
  if ($Code.Length -lt 150 -and $Code -match '(?i)^\s*(\$[mg]\=|New-Object System\.IO\.(MemoryStream|Compression\.GzipStream))') { return 'NOISE-FRAG' }
  if ($Code -match '(?i)Y-ClipBoard|MemScan::Dump|cbdhsvc|Done sweety') { return 'YOUR-TOOL' }
  if ($Code -match 'amsiInitFailed') {
    $etwKill = ($Code -match '(?i)EtwEventWrite|EnableScriptBlockLogging|PSEtwLogProvider')
    $loader = ($Code -match '(?i)DownloadData') -or ($Code -match 'Assembly' -and $Code -match '::Load')
    if ($etwKill -and $loader) { return 'CRITICAL-LOADER' }
  }
  if (($Code -match '(?i)-bxor') -and ($Code -match 'GzipStream') -and ($Code -match 'ScriptBlock' -and $Code -match '::Create')) { return 'FILELESS-STAGER' }
  if ($Code -match '(?i)clicker\.exe|Sapphire/raw') { return 'CHEAT-CLICKER' }
  if ($Score -ge 20) { return 'REVIEW-HIGH' }
  if ($Score -ge 10) { return 'REVIEW' }
  return 'LOW'
}

$patterns = @(
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

$allPats = foreach ($pg in $patterns) { $pg.P }
$patRx = ($allPats | Select-Object -Unique) -join '|'

$logInfo = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
if ($days -gt 0) {
  $xpath = "*[System[EventID=4104 and TimeCreated[timediff(@SystemTime) <= $([int64]$days * 86400000)]]]"
  $windowDesc = "last $days days"
} else {
  $xpath = '*[System[EventID=4104]]'
  $windowDesc = 'all days in log'
}

$events = @(Get-WinEvent -LogName $logName -FilterXPath $xpath -ErrorAction SilentlyContinue)

$info = @()
if ($logInfo) {
  $info += ("enabled={0} mode={1} size={2} records, max {3:N0} MB" -f $logInfo.IsEnabled, $logInfo.LogMode, $logInfo.RecordCount, ($logInfo.MaximumSizeInBytes / 1MB))
}
if ($events.Count -eq 0) {
  $emptyText = 'empty ({0})' -f $windowDesc
  if ($info.Count -gt 0) { $emptyText += "`r`nlog: " + ($info -join ' | ') }
  [IO.File]::WriteAllText($reportFile, $emptyText, [Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{ File = $reportFile; Alerts = 0; Review = 0; Enabled = [bool]$logInfo.IsEnabled; Events = $events.Count }
}
$info += ("scanned 4104 events: {0}" -f $events.Count)
$times = @($events | ForEach-Object { $_.TimeCreated } | Sort-Object)
$info += ("oldest {0:yyyy-MM-dd HH:mm} .. newest {1:yyyy-MM-dd HH:mm}" -f $times[0], $times[$times.Count - 1])
$logLine = 'log: ' + ($info -join ' | ')

$sha = [Security.Cryptography.SHA256]::Create()
$groups = @{}

foreach ($evt in $events) {
  if ($evt.ProcessId -eq $PID) { continue }
  if ($evt.Properties.Count -ge 3 -and $evt.Properties[2].Value) {
    $code = [string]$evt.Properties[2].Value
  } else {
    $code = [string]$evt.Message
  }
  if ([string]::IsNullOrWhiteSpace($code)) { continue }
  if (Test-IsDefenderModuleNoise -Code $code) { continue }
  if (Test-IsWindowsMaintenanceNoise -Code $code) { continue }
  if ($code -match '(?i)BypassMagister|PWSHOperational') { continue }
  if ($code -match '(?i)Get-WinEvent' -and $code -match '4104' -and $code -match 'FilterXPath') { continue }
  if ($code -match '\$pattern\s*=\s*@\(' -and $code -match 'FromBase64String') { continue }
  if ($code -match 'function _s' -and $code -match 'byHash') { continue }
  if ($code -match '(?i)Y-ClipBoard|MemScan::Dump') { continue }
  if ($code -notmatch $patRx) { continue }

  $score = 0
  foreach ($pg in $patterns) {
    $pgRx = ($pg.P -join '|')
    if ($code -match ("(?i){0}" -f $pgRx)) { $score += [int]$pg.W }
  }

  $b64Rx = _s 70,114,111,109,66,97,115,101,54,52,83,116,114,105,110,103
  $obfRx = (_s 71,122,105,112,83,116,114,101,97,109) + '|' + (_s 68,101,102,108,97,116,101,83,116,114,101,97,109) + '|' + (_s 98,120,111,114) + '|' + (_s 92,98,73,69,88,92,98) + '|' + (_s 73,110,118,111,107,101,45,69,120,112,114,101,115,115,105,111,110)
  if ($code -match ("(?i){0}" -f $b64Rx) -and $code -match ("(?i){0}" -f $obfRx)) { $score += 10 }
  $amsiRx = (_s 65,109,115,105,85,116,105,108,115) + '|' + (_s 97,109,115,105,73,110,105,116,70,97,105,108,101,100)
  if ($code -match ("(?i){0}" -f $amsiRx)) { $score += 10 }
  $memRx = (_s 86,105,114,116,117,97,108,65,108,108,111,99) + '|' + (_s 87,114,105,116,101,80,114,111,99,101,115,115,77,101,109,111,114,121) + '|' + (_s 67,114,101,97,116,101,82,101,109,111,116,101,84,104,114,101,97,100)
  if ($code -match ("(?i){0}" -f $memRx)) { $score += 10 }

  $norm = ($code -replace '\s+', ' ').Trim()
  if ($norm.Length -gt 4000) { $norm = $norm.Substring(0, 4000) }
  $hash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($norm))).Replace('-', '').Substring(0, 16)

  $hitList = @([regex]::Matches($code, $patRx, 'IgnoreCase') | ForEach-Object { $_.Value } | Sort-Object -Unique)
  $hits = $hitList -join ', '
  $verdict = Get-BlockVerdict -Code $code -Score $score
  if ($verdict -like 'NOISE*') { continue }

  $rec = [pscustomobject]@{
    TimeCreated = [datetime]$evt.TimeCreated
    Score       = [int]$score
    Verdict     = [string]$verdict
    Hash        = [string]$hash
    Hits        = [string]$hits
    Script      = [string]$code
  }

  if (-not $groups.ContainsKey($hash)) {
    $groups[$hash] = New-Object System.Collections.Generic.List[object]
  }
  $groups[$hash].Add($rec)
}

if ($groups.Count -eq 0) {
  [IO.File]::WriteAllText($reportFile, 'no hits', [Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{ File = $reportFile; Alerts = 0; Review = 0; Enabled = [bool]$logInfo.IsEnabled; Events = $events.Count }
}

$merged = New-Object System.Collections.Generic.List[object]
foreach ($key in $groups.Keys) {
  $list = $groups[$key]
  $maxScore = 0
  $first = $list[0].TimeCreated
  $last  = $list[0].TimeCreated
  $lastCode = $list[0].Script
  $lastHits = $list[0].Hits
  foreach ($rec in $list) {
    if ($rec.Score -gt $maxScore) { $maxScore = $rec.Score }
    if ($rec.TimeCreated -lt $first) { $first = $rec.TimeCreated }
    if ($rec.TimeCreated -gt $last) {
      $last = $rec.TimeCreated
      $lastCode = $rec.Script
      $lastHits = $rec.Hits
    }
  }
  $verdict = Get-BlockVerdict -Code $lastCode -Score $maxScore
  $merged.Add([pscustomobject]@{
      Count     = $list.Count
      Score     = $maxScore
      Verdict   = $verdict
      FirstSeen = $first
      LastSeen  = $last
      Hash      = $key
      Hits      = $lastHits
      Script    = $lastCode
    })
}

$sorted = @($merged.ToArray() | Sort-Object -Property Score -Descending)
for ($i = 0; $i -lt $sorted.Length; ) {
  $j = $i
  while ($j -lt $sorted.Length -and $sorted[$j].Score -eq $sorted[$i].Score) { $j++ }
  if ($j - $i -gt 1) {
    $tie = @($sorted[$i..($j - 1)] | Sort-Object -Property LastSeen -Descending)
    for ($k = 0; $k -lt $tie.Length; $k++) { $sorted[$i + $k] = $tie[$k] }
  }
  $i = $j
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('love bypass by BypassMagister')
[void]$sb.AppendLine(("host {0} | {1:yyyy-MM-dd HH:mm:ss} | window {2} | blocks {3}" -f $env:COMPUTERNAME, (Get-Date), $windowDesc, $sorted.Length))
[void]$sb.AppendLine($logLine)
[void]$sb.AppendLine('verdict: CRITICAL-LOADER / FILELESS-STAGER / CHEAT-CLICKER = real alert | REVIEW* = check | NOISE* filtered out')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('=== Alerts (review first) ===')
foreach ($b in $sorted) {
  if ($b.Verdict -notmatch '^(CRITICAL|FILELESS|CHEAT|REVIEW)') { continue }
  [void]$sb.AppendLine((
      '[{0}] x{1} score={2} | {3:yyyy-MM-dd HH:mm} .. {4:yyyy-MM-dd HH:mm} | {5}' -f
      $b.Verdict, $b.Count, $b.Score, $b.FirstSeen, $b.LastSeen, $b.Hits
    ))
}
[void]$sb.AppendLine('')

$kept = @($groups.Values | ForEach-Object { $_ })
$byDay = @($kept | Group-Object -Property { $_.TimeCreated.ToString('yyyy-MM-dd') } | Sort-Object -Property Name -Descending | ForEach-Object {
    $alertCount = @($_.Group | Where-Object { $_.Verdict -match '^(CRITICAL|FILELESS|CHEAT|REVIEW)' }).Count
    '{0}  kept {1}  alerts {2}' -f $_.Name, $_.Count, $alertCount
  })
[void]$sb.AppendLine('=== By day (kept blocks / alerts) ===')
foreach ($line in $byDay) { [void]$sb.AppendLine($line) }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('=== All kept blocks ===')
foreach ($b in $sorted) {
  [void]$sb.AppendLine((
      '[{0}] x{1} score={2} | {3:yyyy-MM-dd HH:mm} .. {4:yyyy-MM-dd HH:mm} | {5}' -f
      $b.Verdict, $b.Count, $b.Score, $b.FirstSeen, $b.LastSeen, $b.Hits
    ))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('=== Full script blocks (alerts + stagers only) ===')
[void]$sb.AppendLine('')

foreach ($b in $sorted) {
  if ($b.Verdict -notmatch '^(CRITICAL|FILELESS|CHEAT|REVIEW-HIGH)') { continue }
  [void]$sb.AppendLine(('=' * 72))
  [void]$sb.AppendLine(("verdict {0} | score {1} | x{2} | {3:yyyy-MM-dd HH:mm:ss} .. {4:yyyy-MM-dd HH:mm:ss} | {5}" -f $b.Verdict, $b.Score, $b.Count, $b.FirstSeen, $b.LastSeen, $b.Hash))
  [void]$sb.AppendLine($b.Script)
  [void]$sb.AppendLine('')
}

[IO.File]::WriteAllText($reportFile, $sb.ToString(), [Text.UTF8Encoding]::new($false))
return [pscustomobject]@{ File = $reportFile; Alerts = @($sorted | Where-Object { $_.Verdict -match '^(CRITICAL|FILELESS|CHEAT)' }).Count; Review = @($sorted | Where-Object { $_.Verdict -match '^REVIEW' }).Count; Enabled = [bool]$logInfo.IsEnabled; Events = $events.Count }
}

$hunt = $null
try { $hunt = Invoke-Ps4104Hunt } catch { $hunt = $null }
if ($hunt -and $hunt.Alerts -gt 0) { $flags += "PowerShell 4104 alerts ($($hunt.Alerts))" }
if ($hunt -and $hunt.Review -gt 0) { $warns += "PowerShell 4104 blocks to review ($($hunt.Review))" }

Write-Pink "`nPS OPERATIONAL (4104)"
if ($hunt) {
    Write-Host ("  Log saved : {0}" -f $hunt.File) -ForegroundColor White
    if ($hunt.Alerts -gt 0) { Write-Host ("  Alerts : {0}" -f $hunt.Alerts) -ForegroundColor Red }
    elseif ($hunt.Review -gt 0) { Write-Host ("  Review : {0}" -f $hunt.Review) -ForegroundColor White }
    else { Write-Host "  Alerts : None" -ForegroundColor Green }
    if (-not $hunt.Enabled) { Write-Host "  Script Block Logging is off, 4104 log has no new data" -ForegroundColor Gray }
} else {
    Write-Host "  Error during 4104 scan" -ForegroundColor Red
}

Write-Pink "`nSFC SCANNOW"
if (-not $sfcJob -or $evFrozen) { Write-Host "  Skipped" -ForegroundColor Gray }
else {
    Write-Host "  Waiting for sfc to finish..." -ForegroundColor White
    Wait-Job $sfcJob | Out-Null
    Receive-Job $sfcJob | Out-Null
    Remove-Job $sfcJob
    try {
        $since = $scriptStart.AddMinutes(-1).ToString('yyyy-MM-dd HH:mm:ss')
        $srLines = New-Object System.Collections.Generic.List[string]
        $fs = [IO.File]::Open("$env:SystemRoot\Logs\CBS\CBS.log", 'Open', 'Read', 'ReadWrite')
        $rd = New-Object IO.StreamReader($fs)
        while (($ln = $rd.ReadLine()) -ne $null) {
            if ($ln.Length -ge 19 -and $ln.Contains('[SR]') -and [string]::CompareOrdinal($ln.Substring(0, 19), $since) -ge 0) { $srLines.Add($ln) }
        }
        $rd.Close(); $fs.Close()
        $cannot = @($srLines | Where-Object { $_ -match 'Cannot repair' })
        $fixed  = @($srLines | Where-Object { $_ -match 'Repairing corrupted file|Repaired file|Repairing \d+ components' })
        $done   = @($srLines | Where-Object { $_ -match 'Verify complete|Verification \d+% complete' })
        if ($cannot.Count -gt 0) {
            Write-Host "  Result: SFC could not repair $($cannot.Count) corrupted file(s)" -ForegroundColor Red
            foreach ($c in ($cannot | Select-Object -First 6)) { Write-Host "    $($c.Trim())" -ForegroundColor White }
            $warns += "SFC could not repair $($cannot.Count) file(s)"
        }
        elseif ($fixed.Count -gt 0) { Write-Host "  Result: SFC repaired $($fixed.Count) item(s)" -ForegroundColor White }
        elseif ($done.Count -gt 0) { Write-Host "  Result: Windows Resource Protection did not find any integrity violations" -ForegroundColor Green }
        else { Write-Host "  Result: completed (check CBS.log)" -ForegroundColor White }
    } catch { Write-Host "  Result: completed (could not read CBS.log: $($_.Exception.Message))" -ForegroundColor White }
}

# SUMMARY
Write-Host "`n============================================================" -ForegroundColor DarkGray
Write-Pink "  SUMMARY"
Write-Host "============================================================" -ForegroundColor DarkGray
Write-Host "  Suspicious activities : $($suspAct.Count)" -ForegroundColor $(if ($suspAct.Count -gt 0) {"Red"} else {"Green"})
Write-Host "  Faker detected        : $(if ($fakerDetected) {'YES'} else {'No'})" -ForegroundColor $(if ($fakerDetected) {"Red"} else {"Green"})
Write-Host "  Hotspot profiles      : $(($networkProfiles | Where-Object {$_.IsHotspot}).Count)" -ForegroundColor White
Write-Host "  Hard flags            : $($flags.Count)" -ForegroundColor $(if ($flags.Count -gt 0) {"Red"} else {"Green"})
Write-Host "  Warnings              : $($warns.Count)" -ForegroundColor $(if ($warns.Count -gt 0) {"Red"} else {"Green"})
if ($suspAct.Count -gt 0) { Write-Host "`n  Suspicious:" -ForegroundColor Red; $suspAct | ForEach-Object { Write-Host "    - $_" -ForegroundColor White } }
if ($fakerIndicators.Count -gt 0) { Write-Host "`n  Faker indicators:" -ForegroundColor Red; $fakerIndicators | ForEach-Object { Write-Host "    - $_" -ForegroundColor White } }
if ($flags.Count -gt 0) { Write-Host "`n  Flags:" -ForegroundColor Red; $flags | ForEach-Object { Write-Host "    - $_" -ForegroundColor White } }
if ($warns.Count -gt 0) { Write-Host "`n  Review:" -ForegroundColor White; $warns | ForEach-Object { Write-Host "    - $_" -ForegroundColor White } }
if ($suspAct.Count -eq 0 -and $flags.Count -eq 0 -and $warns.Count -eq 0) { Write-Host "`n  CLEAN" -ForegroundColor Green }

Write-Host "`nCheck complete. @sweetvata" -ForegroundColor DarkGray
Write-Host ""
