if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Run as Administrator!" -ForegroundColor Red
    exit
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ConsoleHelper {
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

Write-Pink "Y-sysinfo"
Write-Host ""

Write-Host "Starting sfc /scannow in background..." -ForegroundColor Gray
$sfcJob = Start-Job -ScriptBlock { sfc /scannow 2>&1 }

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
    $raw = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").InstallDate
    if ($raw) {
        $installDate = (Get-Date "1970-01-01 00:00:00").AddSeconds($raw).ToLocalTime()
        Write-Host ("  Install Date : {0}" -f $installDate.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor White
    }
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host ("  OS Version   : {0}" -f $os.Caption) -ForegroundColor White
    Write-Host ("  Build        : {0}" -f $os.BuildNumber) -ForegroundColor White
} catch { Write-Host "  Error reading install info" -ForegroundColor Red }

# DRIVES
$drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
if ($drives) {
    Write-Pink "`nCONNECTED DRIVES"
    foreach ($d in $drives) { Write-Host ("  {0}: {1}" -f $d.DeviceID, $d.FileSystem) -ForegroundColor Green }
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
    if ($s) {
        $dn = if ($svc.DN.Length -gt 40) { $svc.DN.Substring(0,37)+"..." } else { $svc.DN }
        if ($svc.Name -eq "icssvc") {
            $col = if ($s.Status -eq "Running") { "Red" } else { "Green" }
            Write-Host ("  {0,-12} {1,-42} {2}" -f $svc.Name, $dn, $s.Status) -ForegroundColor $col
        } elseif ($s.Status -eq "Running") {
            Write-Host ("  {0,-12} {1,-42}" -f $svc.Name, $dn) -ForegroundColor Green -NoNewline
            if ($svc.Name -eq "Bam") { Write-Host " | Enabled" -ForegroundColor White }
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
            Write-Host ("  {0,-12} {1,-42} {2}" -f $svc.Name, $dn, $s.Status) -ForegroundColor Red
        }
    } else {
        Write-Host ("  {0,-12} {1,-42} N/A" -f $svc.Name, "Not Found") -ForegroundColor White
    }
}

# REGISTRY
Write-Pink "`nREGISTRY"
$regs = @(
    @{Name="CMD";              Path="HKCU:\Software\Policies\Microsoft\Windows\System";                                                                Key="DisableCMD";               W="Disabled"; S="Available"},
    @{Name="PS Logging";       Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging";                                         Key="EnableScriptBlockLogging"; W="Disabled"; S="Enabled"},
    @{Name="Activities Cache"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                                                Key="EnableActivityFeed";       W="Disabled"; S="Enabled"},
    @{Name="Prefetch";         Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key="EnablePrefetcher"; W="Disabled"; S="Enabled"}
)
foreach ($r in $regs) {
    $val = Get-ItemProperty -Path $r.Path -Name $r.Key -ErrorAction SilentlyContinue
    Write-Host "  $($r.Name): " -NoNewline -ForegroundColor White
    if ($val -and $val.$($r.Key) -eq 0) { Write-Host $r.W -ForegroundColor Red; $warns += "$($r.Name) $($r.W)" }
    else { Write-Host $r.S -ForegroundColor Green }
}

# DEFENDER
Write-Pink "`nWINDOWS DEFENDER"
try {
    $rtp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $pol = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name DisableRealtimeMonitoring -ErrorAction SilentlyContinue).DisableRealtimeMonitoring
    $tmp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name TamperProtection -ErrorAction SilentlyContinue).TamperProtection
    Write-Host "  Real-Time Protection : " -NoNewline -ForegroundColor White
    if ($rtp -eq 1 -or $pol -eq 1) { Write-Host "DISABLED" -ForegroundColor Red; $flags += "Defender real-time protection is OFF" }
    else { Write-Host "Enabled" -ForegroundColor Green }
    Write-Host "  Tamper Protection    : " -NoNewline -ForegroundColor White
    if ($tmp -eq 5) { Write-Host "Enabled" -ForegroundColor Green }
    elseif ($null -eq $tmp) { Write-Host "Unknown" -ForegroundColor Gray }
    else { Write-Host "DISABLED" -ForegroundColor Red; $warns += "Tamper Protection disabled" }
    if ($pol -eq 1) { Write-Host "  Note: disabled via Group Policy" -ForegroundColor White }
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
Check-EVMulti "System"      @(104,1102) "Event Logs cleared"
Check-EV      "System"      1074        "Last PC Shutdown"
Check-EV      "Security"    4616        "System time changed"
Check-EV      "System"      6005        "Event Log Service started"
try {
    $ev = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -FilterXPath "*[System[EventID=400]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($ev) { Write-Host "  Device config changed at: " -NoNewline -ForegroundColor White; Write-Host $ev.TimeCreated.ToString("MM/dd HH:mm") -ForegroundColor White }
    else { Write-Host "  Device changes - No records found" -ForegroundColor Green }
} catch { Write-Host "  Device changes - No records found" -ForegroundColor Green }
$logCleared = Get-WinEvent -FilterHashtable @{LogName="System"; Id=@(104,1102)} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($logCleared) { $warns += "Event log was cleared" }

# USN JOURNAL
Write-Pink "`nUSN JOURNAL"
try {
    $usn = fsutil usn queryjournal C: 2>&1
    if ($usn -match "Invalid") {
        Write-Host "  Status       : DISABLED" -ForegroundColor Red
        $warns += "USN Journal disabled"
    } elseif ($usn -match "Usn Journal ID") {
        Write-Host "  Status       : Enabled" -ForegroundColor Green
        $usnClear = Get-WinEvent -LogName "Application" -FilterXPath "*[System[EventID=3079]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($usnClear) { Write-Host "  Last cleared : $($usnClear.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
        else { Write-Host "  Last cleared : Never cleared manually" -ForegroundColor Green }
        $fu = $usn | Select-String "First Usn"
        if ($fu) { Write-Host "  $($fu.Line.Trim())" -ForegroundColor Gray }
    } else { Write-Host "  Status       : Unknown" -ForegroundColor White }
} catch { Write-Host "  Error reading USN Journal" -ForegroundColor Red }

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
                $h = Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
                if ($h) {
                    if ($ht.ContainsKey($h.Hash)) { $ht[$h.Hash].Add($f.Name) }
                    else { $ht[$h.Hash] = [System.Collections.Generic.List[string]]::new(); $ht[$h.Hash].Add($f.Name) }
                }
            } catch { $sus[$f.Name] = "Error" }
        }
        if ($hidro.Count -gt 0) { Write-Host "  Hidden+ReadOnly: $($hidro.Count)" -ForegroundColor White; $hidro | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        if ($hid.Count   -gt 0) { Write-Host "  Hidden: $($hid.Count)" -ForegroundColor White; $hid | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor White } }
        else { Write-Host "  Hidden Files: None" -ForegroundColor Green }
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
        $rbClear = Get-WinEvent -FilterHashtable @{LogName="System"; Id=10006} -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($rbClear) { Write-Host "  Last Cleared : $($rbClear.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Red }
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
                    $pk = Join-Path $inst.PSPath "Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0065"
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
    } else { Write-Host "  USBSTOR key not accessible" -ForegroundColor White }
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
    $bssidM = $iface | Select-String "^\s+BSSID\s+:\s+(.+)$"
    $chanM  = $iface | Select-String "^\s+Channel\s+:\s+(.+)$"
    $sigM   = $iface | Select-String "^\s+Signal\s+:\s+(.+)$"
    if ($ssidM -and $stateM) {
        $curSSID  = $ssidM.Matches.Groups[1].Value.Trim()
        $curState = $stateM.Matches.Groups[1].Value.Trim()
        $bssid    = if ($bssidM) { $bssidM.Matches.Groups[1].Value.Trim() } else { "N/A" }
        $chan     = if ($chanM)  { $chanM.Matches.Groups[1].Value.Trim() }  else { "N/A" }
        $sig      = if ($sigM)   { $sigM.Matches.Groups[1].Value.Trim() }   else { "N/A" }
        if ($curState -eq "connected") {
            $isHs = $false; $hsInd = @()
            $pats = @("Android","iPhone","iPad","Galaxy","Pixel","OnePlus","Xiaomi","Huawei","Oppo","Vivo","Realme","Nokia","DIRECT-","SM-[A-Z0-9]","GT-[A-Z0-9]","Redmi","'s iPhone","'s Galaxy","'s Pixel")
            foreach ($pat in $pats) { if ($curSSID -match $pat) { $isHs=$true; $hsInd+="SSID matches: $pat"; break } }
            if ($bssid -ne "N/A") { $sc=$bssid.Substring(1,1); if ($sc -match "[26AEae]") { $isHs=$true; $hsInd+="BSSID locally administered" } }
            try {
                $gw = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -and $_.DefaultIPGateway }).DefaultIPGateway | Select-Object -First 1
                if ($gw) {
                    if ($gw -like "192.168.137.*") { $isHs=$true; $fakerDetected=$true; $fakerIndicators+="Windows PC Hotspot gateway (192.168.137.x)"; $hsInd+="Gateway = Windows Mobile Hotspot - FAKER" }
                    elseif ($gw -eq "192.168.43.1") { $isHs=$true; $hsInd+="Gateway = Android hotspot" }
                    elseif ($gw -eq "192.168.49.1") { $isHs=$true; $hsInd+="Gateway = Android hotspot" }
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
    $va = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true -and $_.Description -match "Virtual|Hosted|Wi-Fi Direct|TAP" }
    if ($va) { $va | ForEach-Object { Write-Host "  Virtual adapter: $($_.Description)" -ForegroundColor White }; $suspAct+="$($va.Count) virtual adapter(s)" }
    else { Write-Host "  Virtual adapters: None" -ForegroundColor Green }
} catch {}

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
                $sh = if ($cl.Length -gt 120) { $cl.Substring(0,117)+"..." } else { $cl }
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
        $_ -like "-Xmx*" -or $_ -like "-Xms*" -or $_ -like "-javaagent*" -or $_ -like "-Dfabric.addMods*" -or $_ -like "-Dloader.addMods*"
    }
    if ($jvmArgs) {
        $jvmAny = $true
        Write-Host "  PID $($_.ProcessId)" -ForegroundColor White
        foreach ($a in $jvmArgs) {
            $t = $a.Trim()
            $bad = ($t -like "-javaagent*" -or $t -like "-D*addMods*")
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
        $late = @($jars | Where-Object { $_.LastAccessTime -gt $win })
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
            $line = ($ev.Message -split "`n" | Select-String "Process Command Line|New Process Name")
            $txt = ($line -join " ").Trim()
            if (-not $txt) { continue }
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

# SFC RESULT (last)
Write-Pink "`nSFC SCANNOW"
Write-Host "  Waiting for sfc to finish..." -ForegroundColor White
Wait-Job $sfcJob | Out-Null
$sfcResult = Receive-Job $sfcJob | ForEach-Object { ($_ -replace "`0","").Trim() }
Remove-Job $sfcJob
$sfcSum = $sfcResult | Where-Object { $_ -match "protection|found|repair|did not find|resource" } | Select-Object -Last 1
if ($sfcSum) {
    $col = if ($sfcSum -match "did not find") { "Green" } else { "White" }
    Write-Host "  Result: $($sfcSum.ToString().Trim())" -ForegroundColor $col
} else { Write-Host "  Result: completed (check CBS.log)" -ForegroundColor White }

Write-Host "`nCheck complete. @sweetvata" -ForegroundColor DarkGray
Write-Host ""
