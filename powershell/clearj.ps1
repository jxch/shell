<#
.SYNOPSIS
    clearj.ps1 - Windows 11/10 专业垃圾清理脚本

.DESCRIPTION
    支持交互菜单和命令行参数双模式，覆盖回收站、临时文件、系统和用户缓存、浏览器、Office、日志、OneDrive、WSL、UWP/APPX、Defender、下载等多类垃圾，适合个人和企业自动化运维。

    每项有分项进度条、总体进度条，静默、确认、报错输出全部优化。

.PARAMETER All, a
    一键清理全部支持项

.PARAMETER Yes, y
    跳过所有二次确认，强制执行

.PARAMETER Silent, s
    静默模式，仅输出错误

.PARAMETER Help, h
    显示帮助文档

# 基础
.PARAMETER RecycleBin, rb
    清空所有回收站及子目录回收站

.PARAMETER Temp, t
    清理所有临时文件夹（系统/用户）

.PARAMETER TempDownload, td
    清理下载临时区（如 Edge/Chrome/IE 的下载残留）

.PARAMETER Recent, r
    清理最近访问记录（Recent JumpList）

.PARAMETER Prefetch, pf
    清理预读取缓存

.PARAMETER Thumbnails, th
    清理缩略图缓存

.PARAMETER Logs, l
    清理系统日志（含 .evtx/.etl/.log）

.PARAMETER ErrorReports, er
    清理 Windows 错误报告

.PARAMETER DumpFiles, df
    清理系统/程序 Dump 文件

# 系统相关
.PARAMETER UpdateCache, uc
    清理 Windows 更新缓存

.PARAMETER UpgradeResiduals, ur
    清理系统升级残留（如 $WINDOWS.~BT）

.PARAMETER WindowsOld, wo
    清理 Windows.old

.PARAMETER DeliveryOptimization, do
    清理 Delivery Optimization 缓存

.PARAMETER OldDrivers, od
    清理旧驱动

.PARAMETER FontsCache, fc
    清理系统字体缓存

.PARAMETER SearchCache, sc
    清理 Windows Search 索引缓存

# 应用/用户相关
.PARAMETER Browsers, b
    清理常见浏览器缓存（Edge/IE/Chrome/Firefox/Edge Chromium）

.PARAMETER EdgeUserCache, eu
    清理 Edge Chromium 用户数据缓存

.PARAMETER OfficeCache, oc
    清理 Office 临时文件和缓存

.PARAMETER OneDriveCache, on
    清理 OneDrive 本地缓存和旧安装包

.PARAMETER AppxCache, ac
    清理 UWP/APPX 残留包缓存

.PARAMETER StoreCache, st
    清理微软商店和 UWP 应用缓存

.PARAMETER WSLTemp, ws
    清理 WSL 临时空间

.PARAMETER PrinterCache, pc
    清理打印机缓存

.PARAMETER DefenderLogs, dl
    清理 Windows Defender 扫描日志

.EXAMPLE
    clearj.ps1 -a -y
    clearj.ps1 -rb -b -th -df
    clearj.ps1 -All -Yes
    clearj.ps1          # 菜单多选模式

.NOTES
    作者: JXCH
    https://github.com/JXCh1
    如需定制功能、企业运维批量部署，欢迎 issues 或私信联系。
#>

param(
    [Alias("a")][switch]$All,
    [Alias("y")][switch]$Yes,
    [Alias("s")][switch]$Silent,
    [Alias("h")][switch]$Help,
    [Alias("rb")][switch]$RecycleBin,
    [Alias("t")][switch]$Temp,
    [Alias("td")][switch]$TempDownload,
    [Alias("r")][switch]$Recent,
    [Alias("pf")][switch]$Prefetch,
    [Alias("th")][switch]$Thumbnails,
    [Alias("l")][switch]$Logs,
    [Alias("er")][switch]$ErrorReports,
    [Alias("df")][switch]$DumpFiles,
    [Alias("uc")][switch]$UpdateCache,
    [Alias("ur")][switch]$UpgradeResiduals,
    [Alias("wo")][switch]$WindowsOld,
    [Alias("do")][switch]$DeliveryOptimization,
    [Alias("od")][switch]$OldDrivers,
    [Alias("fc")][switch]$FontsCache,
    [Alias("sc")][switch]$SearchCache,
    [Alias("b")][switch]$Browsers,
    [Alias("eu")][switch]$EdgeUserCache,
    [Alias("oc")][switch]$OfficeCache,
    [Alias("on")][switch]$OneDriveCache,
    [Alias("ac")][switch]$AppxCache,
    [Alias("st")][switch]$StoreCache,
    [Alias("ws")][switch]$WSLTemp,
    [Alias("pc")][switch]$PrinterCache,
    [Alias("dl")][switch]$DefenderLogs
)

function Show-Help {
@"
──────────────────────────────────────────────
clearj.ps1 – Windows 11/10 专业垃圾清理脚本
──────────────────────────────────────────────

【简介】
本工具适用于 Windows 11/10 系统的日常维护及运维自动化，覆盖系统、用户、应用等多种垃圾类型清理。支持命令行参数和菜单交互两种模式。

【主要功能】
- 支持回收站、临时文件、更新缓存、系统日志、浏览器缓存、升级残留、驱动、Office、WSL、UWP、Defender、字体、打印机、搜索索引等二十余类垃圾清理
- 所有清理项均可单独或批量组合执行
- 支持二次确认，-y 跳过所有确认，适合无人值守自动化
- 支持静默模式，仅输出错误
- 输出分级着色，便于快速定位
- 每项与总体均有美观进度条显示

【参数速查】
  -a  或  -All                一键清理全部支持项
  -y  或  -Yes                跳过所有确认直接清理
  -s  或  -Silent             静默执行，仅输出错误
  -h  或  -Help               显示帮助文档

  -rb 或  -RecycleBin         清空所有回收站及子目录回收站
  -t  或  -Temp               清理系统和用户临时文件夹
  -td 或  -TempDownload       清理下载临时区（各浏览器下载残留）
  -r  或  -Recent             清理最近访问记录
  -pf 或  -Prefetch           清理预读取缓存
  -th 或  -Thumbnails         清理缩略图缓存
  -l  或  -Logs               清理系统日志
  -er 或  -ErrorReports       清理 Windows 错误报告
  -df 或  -DumpFiles          清理系统和程序 Dump 文件

  -uc 或  -UpdateCache        清理 Windows 更新缓存
  -ur 或  -UpgradeResiduals   清理系统升级残留
  -wo 或  -WindowsOld         清理 Windows.old
  -do 或  -DeliveryOptimization 清理 Delivery Optimization 缓存
  -od 或  -OldDrivers         清理旧驱动
  -fc 或  -FontsCache         清理系统字体缓存
  -sc 或  -SearchCache        清理 Windows Search 索引缓存

  -b  或  -Browsers           清理浏览器缓存（Edge/IE/Chrome/Firefox/Edge Chromium）
  -eu 或  -EdgeUserCache      清理 Edge Chromium 用户数据
  -oc 或  -OfficeCache        清理 Office 临时缓存
  -on 或  -OneDriveCache      清理 OneDrive 本地缓存和旧安装包
  -ac 或  -AppxCache          清理 UWP/APPX 残留包缓存
  -st 或  -StoreCache         清理微软商店和 UWP 应用缓存
  -ws 或  -WSLTemp            清理 WSL 临时空间
  -pc 或  -PrinterCache       清理打印机缓存
  -dl 或  -DefenderLogs       清理 Windows Defender 扫描日志

【典型示例】
  clearj.ps1 -a -y
      一键清理全部垃圾，无需确认，适合自动化

  clearj.ps1 -rb -b -th -df
      只清理回收站、浏览器缓存、缩略图、Dump 文件

  clearj.ps1 -t -oc -on -er
      清理临时文件、Office 缓存、OneDrive 缓存、错误报告

  clearj.ps1
      进入菜单交互模式，可多选序号

  clearj.ps1 -wo -uc -y -s
      静默快速清理 Windows.old 和更新缓存，无确认无多余输出

【详细说明】
- 所有参数均可自由组合，顺序不限，短名和全名等价
- 无参数时进入菜单模式，支持多选，输入序号空格分隔
- 每项清理默认都会二次确认，-y 跳过全部确认
- 建议以管理员身份运行，部分项目非管理员无效
- 所有清理不可逆，请谨慎选择

【注意事项】
- 清理浏览器、OneDrive、Office、UWP 等缓存后，部分历史、账号、插件数据可能丢失
- 某些项目（如 Dump、日志、升级残留）清理后可能影响故障分析
- 企业用户可结合计划任务、RMM、SCCM、Intune、MDT、Ansible 等自动化工具批量部署
- 本工具仅适用于 Windows 10/11，其他系统请先测试

【返回码说明】
  0    成功
  1    用户取消
  10   未以管理员身份运行
  其他 脚本内部错误

【作者与反馈】
  作者：JXCH
  问题建议：请到项目 issues 区提交
  https://github.com/jxch/shell/blob/main/powershell/chromej.ps1
──────────────────────────────────────────────
"@ | Write-Host
}

function Write-Log($msg, $color="Gray") { if (-not $Silent) { Write-Host $msg -ForegroundColor $color } }
function Write-Err($msg) { Write-Host $msg -ForegroundColor Red }
function Confirm-Action($desc) { if ($Yes) {return $true} $ans = Read-Host "$desc（Y 确认，N 取消）"; if ($ans -eq 'Y' -or $ans -eq 'y') {return $true} Write-Log "已跳过 $desc" "Yellow"; return $false }
function Require-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Err "请用管理员身份运行本脚本！"; exit 10
    }
}
Require-Admin
if ($Help) { Show-Help; exit 0 }

# 进度条：记录顶部行号
[int]$ProgressLine1 = [Console]::CursorTop
Write-Host ""
[int]$ProgressLine2 = [Console]::CursorTop
Write-Host ""
[int]$ProgressLine3 = [Console]::CursorTop
Write-Host ""

function Show-ProgressBar {
    param(
        [int]$current,
        [int]$total,
        [string]$desc,
        [int]$subCurrent = $null,
        [int]$subTotal = $null,
        [string]$subName = $null
    )
    $width = 36
    $ratio = if ($total -eq 0) {1} else {$current / $total}
    $done = [int]($ratio * $width)
    $bar = ("█" * $done) + ("░" * ($width - $done))
    $percent = [int]($ratio * 100)
    $msg = "总体进度: [{0}] {1}/{2} {3} ({4}%)" -f $bar, $current, $total, $desc, $percent

    [Console]::SetCursorPosition(0, $ProgressLine1)
    Write-Host ($msg + (" " * 30)) -NoNewline -ForegroundColor Yellow

    if ($subCurrent -ne $null -and $subTotal -ne $null -and $subName) {
        $w2 = 22
        $r2 = if ($subTotal -eq 0) {1} else {$subCurrent / $subTotal}
        $done2 = [int]($r2 * $w2)
        $bar2 = ("■" * $done2) + ("·" * ($w2 - $done2))
        $p2 = [int]($r2 * 100)
        $msg2 = "分项进度: [{0}] {1}/{2} {3} ({4}%)" -f $bar2, $subCurrent, $subTotal, $subName, $p2
        [Console]::SetCursorPosition(0, $ProgressLine2)
        Write-Host ($msg2 + (" " * 30)) -NoNewline -ForegroundColor Cyan
    } else {
        [Console]::SetCursorPosition(0, $ProgressLine2)
        Write-Host (" " * 80) -NoNewline
    }
    $bottom = $ProgressLine3 + 1
    [Console]::SetCursorPosition(0, $bottom)
}

function Show-CleaningLine($text) {
    [Console]::SetCursorPosition(0, $ProgressLine3)
    $msg = "已清理: $text"
    Write-Host ($msg + (" " * 60)) -NoNewline -ForegroundColor Green
    $bottom = $ProgressLine3 + 1
    [Console]::SetCursorPosition(0, $bottom)
}

# --- 清理函数区 ---
function Clean-Temp {
    if (-not (Confirm-Action "清理系统和用户临时文件")) { return }
    $tempPaths = @(
        "$env:TEMP", "$env:TMP", "$env:SystemRoot\Temp", "$env:LOCALAPPDATA\Temp"
    ) + (Get-ChildItem "C:\Users" -Directory | ForEach-Object { "$($_.FullName)\AppData\Local\Temp" })
    $cleaned = 0
    $locked = 0
    foreach ($path in $tempPaths | Sort-Object -Unique) {
        if (Test-Path $path) {
            try {
                $files = Get-ChildItem "$path" -Force -ErrorAction SilentlyContinue
                $totalFiles = ($files | Measure-Object).Count
                $fileNum = 0
                foreach ($file in $files) {
                    $fileNum++
                    Show-ProgressBar 1 1 "清理系统和用户临时文件" $fileNum $totalFiles $file.Name
                    Show-CleaningLine $file.FullName
                    try {
                        Remove-Item $file.FullName -Recurse -Force -ErrorAction Stop
                    } catch {
                        $msg = $_.Exception.Message
                        if ($msg -match 'being used by another process|访问被拒绝|denied|正在被另一个进程使用') {
                            $locked++
                        } elseif ($msg -notmatch 'not exist|cannot find|不存在|找不到') {
                            Write-Err "清理 $($file.FullName) 失败: $msg"
                        }
                    }
                }
                $cleaned++
            } catch {
                Write-Err "清理 $path 失败: $($_.Exception.Message)"
            }
        }
    }
    Show-CleaningLine " "
    if ($locked -gt 0) { Write-Log "有 $locked 个文件被占用，未能删除（属正常现象）" "Yellow" }
    if ($cleaned -eq 0) { Write-Log "未发现可清理的临时目录。" "Yellow" }
    else { Write-Log "临时文件已清理完成。" "Green" }
}

function Clean-RecycleBin {
    if (-not (Confirm-Action "清理回收站")) { return }
    Show-CleaningLine "回收站"
    Write-Log "清理回收站..."
    try {
        $null = Clear-RecycleBin -Force -ErrorAction Stop
        Get-ChildItem -Path 'C:\$Recycle.Bin','D:\$Recycle.Bin','E:\$Recycle.Bin' -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item "$($_.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Log "回收站已清空。" "Green"
    } catch {
        if ($_.Exception.Message -like "*cannot find the path*") {
            Write-Log "未检测到回收站或回收站已为空。" "Yellow"
        } else {
            Write-Err "清理回收站失败: $($_.Exception.Message)"
        }
    }
    Show-CleaningLine " "
}

function Clean-TempDownload {
    if (-not (Confirm-Action "清理下载临时区")) { return }
    $dlPaths = @(
        "$env:USERPROFILE\Downloads\$RECYCLE.BIN",
        "$env:USERPROFILE\Downloads\Temp",
        "$env:LOCALAPPDATA\Packages\*\TempState\Downloads"
    )
    foreach ($path in $dlPaths) {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
            Show-CleaningLine $_.FullName
            try { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        }
    }
    Show-CleaningLine " "
    Write-Log "下载临时区清理完成。" "Green"
}
function Clean-Recent {
    if (-not (Confirm-Action "清理最近访问记录")) { return }
    $recent = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recent) {
        try {
            $files = Get-ChildItem "$recent" -Force -ErrorAction SilentlyContinue
            $totalFiles = ($files | Measure-Object).Count
            $fileNum = 0
            foreach ($file in $files) {
                $fileNum++
                Show-ProgressBar 1 1 "清理最近访问记录" $fileNum $totalFiles $file.Name
                Show-CleaningLine $file.FullName
                try { Remove-Item $file.FullName -Recurse -Force -ErrorAction Stop } catch {
                    if ($_.Exception.Message -notmatch 'not exist|cannot find|不存在|找不到') {
                        Write-Err "清理 $($file.FullName) 失败: $($_.Exception.Message)"
                    }
                }
            }
            Write-Log "Recent 记录已清理。" "Green"
        } catch { Write-Err "清理 Recent 失败: $_" }
    } else { Write-Log "未找到 Recent 目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-Prefetch {
    if (-not (Confirm-Action "清理预读取缓存")) { return }
    Show-CleaningLine "预读取缓存"
    $prefetch = "$env:SystemRoot\Prefetch"
    if (Test-Path $prefetch) {
        try { Remove-Item "$prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "预读取缓存已清理。" "Green" } catch { Write-Err "清理预读取缓存失败: $_" }
    } else { Write-Log "未检测到预读取目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-Thumbnails {
    if (-not (Confirm-Action "清理缩略图缓存")) { return }
    Show-CleaningLine "缩略图缓存"
    $thumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    $thumbFiles = Get-ChildItem $thumbCache -Filter "thumbcache_*.db" -ErrorAction SilentlyContinue
    if ($thumbFiles) {
        try { $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue; Write-Log "缩略图缓存已清理。" "Green" } catch { Write-Err "清理缩略图缓存失败: $_" }
    } else { Write-Log "未找到缩略图缓存。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-Logs {
    if (-not (Confirm-Action "清理系统日志")) { return }
    Show-CleaningLine "系统日志"
    $logDirs = @(
        "$env:SystemRoot\Logs", "$env:SystemRoot\System32\winevt\Logs", "$env:SystemRoot\Logs\CBS", "$env:SystemRoot\Panther"
    )
    foreach ($dir in $logDirs) {
        if (Test-Path $dir) {
            try { Remove-Item "$dir\*.log" -Force -ErrorAction SilentlyContinue; Remove-Item "$dir\*.evtx" -Force -ErrorAction SilentlyContinue; Remove-Item "$dir\*.etl" -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $dir" "DarkGreen" } catch { Write-Err "清理 $dir 失败: $_" }
        }
    }
    try { wevtutil el | ForEach-Object { wevtutil cl $_ }; Write-Log "Windows 事件日志已清空。" "DarkGreen" } catch { Write-Err "清理事件日志失败: $_" }
    Write-Log "系统日志已清理完成。" "Green"
    Show-CleaningLine " "
}
function Clean-ErrorReports {
    if (-not (Confirm-Action "清理 Windows 错误报告")) { return }
    Show-CleaningLine "Windows 错误报告"
    $dirs = @(
        "$env:ProgramData\Microsoft\Windows\WER\ReportArchive", "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
        "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportArchive", "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue"
    )
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            try { Remove-Item "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $dir" "DarkGreen" } catch { Write-Err "清理 $dir 失败: $_" }
        }
    }
    Write-Log "错误报告清理完成。" "Green"
    Show-CleaningLine " "
}
function Clean-DumpFiles {
    if (-not (Confirm-Action "清理系统/程序 Dump 文件")) { return }
    Show-CleaningLine "Dump 文件"
    $dumps = @("$env:SystemRoot\memory.dmp", "$env:SystemRoot\Minidump\*")
    foreach ($d in $dumps) {
        if (Test-Path $d) {
            try { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $d" "DarkGreen" } catch { Write-Err "清理 $d 失败: $_" }
        }
    }
    Write-Log "Dump 文件清理完成。" "Green"
    Show-CleaningLine " "
}
function Clean-UpdateCache {
    if (-not (Confirm-Action "清理 Windows 更新缓存")) { return }
    Show-CleaningLine "Windows 更新缓存"
    $updateCache = "$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path $updateCache) {
        try { Remove-Item "$updateCache\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Windows 更新缓存已清理。" "Green" } catch { Write-Err "清理更新缓存失败: $_" }
    } else { Write-Log "未找到更新缓存目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-UpgradeResiduals {
    if (-not (Confirm-Action "清理系统升级残留")) { return }
    Show-CleaningLine "系统升级残留"
    $dirs = @("$env:SystemRoot\$WINDOWS.~BT", "$env:SystemRoot\$WINDOWS.~WS")
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            try { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $dir" "DarkGreen" } catch { Write-Err "清理 $dir 失败: $_" }
        }
    }
    Write-Log "系统升级残留清理完成。" "Green"
    Show-CleaningLine " "
}
function Clean-WindowsOld {
    if (-not (Confirm-Action "清理 Windows.old")) { return }
    Show-CleaningLine "Windows.old"
    $winOld = "C:\Windows.old"
    if (Test-Path $winOld) {
        try { Remove-Item $winOld -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Windows.old 已清理。" "Green" } catch { Write-Err "清理 Windows.old 失败: $_" }
    } else { Write-Log "未检测到 Windows.old。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-DeliveryOptimization {
    if (-not (Confirm-Action "清理 Delivery Optimization 缓存")) { return }
    Show-CleaningLine "Delivery Optimization 缓存"
    $doDir = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"
    if (Test-Path $doDir) {
        try { Remove-Item "$doDir\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Delivery Optimization 缓存已清理。" "Green" } catch { Write-Err "清理 Delivery Optimization 缓存失败: $_" }
    } else { Write-Log "未找到 Delivery Optimization 缓存目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-OldDrivers {
    if (-not (Confirm-Action "清理旧驱动")) { return }
    Show-CleaningLine "旧驱动"
    $drvDir = "$env:SystemRoot\System32\DriverStore\FileRepository"
    if (Test-Path $drvDir) {
        $dirs = Get-ChildItem $drvDir -Directory | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) }
        $removed = 0
        foreach ($d in $dirs) {
            Show-CleaningLine $d.FullName
            try { Remove-Item $d.FullName -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理旧驱动: $($d.Name)" "DarkGreen"; $removed++ } catch { Write-Err "清理 $($d.Name) 失败: $_" }
        }
        if ($removed -eq 0) { Write-Log "未检测到可清理旧驱动。" "Yellow" } else { Write-Log "旧驱动已清理完成。" "Green" }
    } else { Write-Log "未检测到驱动存储目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-FontsCache {
    if (-not (Confirm-Action "清理字体缓存")) { return }
    Show-CleaningLine "字体缓存"
    $fc = "$env:LOCALAPPDATA\FontCache"
    if (Test-Path $fc) {
        try { Remove-Item "$fc\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "字体缓存已清理。" "Green" } catch { Write-Err "清理字体缓存失败: $_" }
    } else { Write-Log "未找到字体缓存目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-SearchCache {
    if (-not (Confirm-Action "清理 Windows Search 索引缓存")) { return }
    Show-CleaningLine "Windows Search 索引缓存"
    $sc = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows"
    if (Test-Path $sc) {
        try { Remove-Item "$sc\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Search 索引缓存已清理。" "Green" } catch { Write-Err "清理 Search 缓存失败: $_" }
    } else { Write-Log "未找到 Search 索引缓存目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-Browsers {
    if (-not (Confirm-Action "清理浏览器缓存")) { return }
    Show-CleaningLine "浏览器缓存"
    $browserCleaned = $false
    try { RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351; Write-Log "已清理 Edge/IE 缓存。" "DarkGreen"; $browserCleaned = $true } catch { }
    $chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $chromeCache) { try { Remove-Item "$chromeCache\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理 Chrome 缓存。" "DarkGreen"; $browserCleaned = $true } catch { } }
    $ffBase = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffBase) {
        Get-ChildItem $ffBase -Directory | ForEach-Object {
            $cacheDir = "$($_.FullName)\cache2"
            if (Test-Path $cacheDir) {
                try { Remove-Item "$cacheDir\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理 Firefox 缓存: $($_.Name)" "DarkGreen"; $browserCleaned = $true } catch { }
            }
        }
    }
    $edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path $edgeUserData) { try { Remove-Item "$edgeUserData\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理 Edge Chromium 缓存。" "DarkGreen"; $browserCleaned = $true } catch { } }
    if (-not $browserCleaned) { Write-Log "未检测到可清理的浏览器缓存。" "Yellow" } else { Write-Log "浏览器缓存已清理完成。" "Green" }
    Show-CleaningLine " "
}
function Clean-EdgeUserCache {
    if (-not (Confirm-Action "清理 Edge Chromium 用户数据")) { return }
    Show-CleaningLine "Edge Chromium 用户数据"
    $paths = @(
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { try { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $p" "DarkGreen" } catch { } }
    }
    Write-Log "Edge Chromium 用户数据已清理。" "Green"
    Show-CleaningLine " "
}
function Clean-OfficeCache {
    if (-not (Confirm-Action "清理 Office 临时文件和缓存")) { return }
    Show-CleaningLine "Office 缓存"
    $paths = @(
        "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache",
        "$env:LOCALAPPDATA\Microsoft\Office\16.0\WEF",
        "$env:APPDATA\Microsoft\Templates"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { try { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "已清理: $p" "DarkGreen" } catch { } }
    }
    Write-Log "Office 缓存已清理。" "Green"
    Show-CleaningLine " "
}
function Clean-OneDriveCache {
    if (-not (Confirm-Action "清理 OneDrive 本地缓存和旧安装包")) { return }
    Show-CleaningLine "OneDrive 本地缓存"
    $odDir = "$env:LOCALAPPDATA\Microsoft\OneDrive"
    if (Test-Path $odDir) { try { Remove-Item "$odDir\*\*.tmp" -Force -ErrorAction SilentlyContinue; Write-Log "OneDrive 缓存已清理。" "Green" } catch { } }
    $oldOD = "$env:LOCALAPPDATA\Microsoft\OneDrive\Update"
    if (Test-Path $oldOD) { try { Remove-Item "$oldOD\*" -Force -ErrorAction SilentlyContinue; Write-Log "OneDrive 旧安装包已清理。" "Green" } catch { } }
    Show-CleaningLine " "
}
function Clean-AppxCache {
    if (-not (Confirm-Action "清理 UWP/APPX 残留包缓存")) { return }
    Show-CleaningLine "UWP/APPX 缓存"
    $appx = "$env:LOCALAPPDATA\Packages"
    if (Test-Path $appx) {
        Get-ChildItem $appx -Directory | ForEach-Object {
            $cacheDir = "$($_.FullName)\AC"
            if (Test-Path $cacheDir) {
                Show-CleaningLine $cacheDir
                try { Remove-Item "$cacheDir\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "清理: $cacheDir" "DarkGreen" } catch { }
            }
        }
    }
    Write-Log "UWP/APPX 缓存已清理。" "Green"
    Show-CleaningLine " "
}
function Clean-StoreCache {
    if (-not (Confirm-Action "清理微软商店及 UWP 应用缓存")) { return }
    Show-CleaningLine "微软商店及 UWP 应用缓存"
    $dirs = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_*\AC\Temp",
        "$env:LOCALAPPDATA\Packages\*\TempState"
    )
    foreach ($d in $dirs) {
        Get-ChildItem -Path $d -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Show-CleaningLine $_.FullName
            try { Remove-Item "$($_.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "清理: $($_.FullName)" "DarkGreen" } catch { }
        }
    }
    Write-Log "商店缓存已清理。" "Green"
    Show-CleaningLine " "
}
function Clean-WSLTemp {
    if (-not (Confirm-Action "清理 WSL 临时空间")) { return }
    Show-CleaningLine "WSL 临时空间"
    $wsl = "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.UbuntuonWindows_*\LocalState\temp"
    Get-ChildItem -Path $wsl -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Show-CleaningLine $_.FullName
        try { Remove-Item "$($_.FullName)\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "清理: $($_.FullName)" "DarkGreen" } catch { }
    }
    Write-Log "WSL 临时空间已清理。" "Green"
    Show-CleaningLine " "
}
function Clean-PrinterCache {
    if (-not (Confirm-Action "清理打印机缓存")) { return }
    Show-CleaningLine "打印机缓存"
    $pc = "$env:SystemRoot\System32\spool\PRINTERS"
    if (Test-Path $pc) { try { Remove-Item "$pc\*" -Force -ErrorAction SilentlyContinue; Write-Log "打印机缓存已清理。" "Green" } catch { Write-Err "清理打印机缓存失败: $_" } }
    else { Write-Log "未检测到打印机缓存目录。" "Yellow" }
    Show-CleaningLine " "
}
function Clean-DefenderLogs {
    if (-not (Confirm-Action "清理 Windows Defender 扫描日志")) { return }
    Show-CleaningLine "Windows Defender 扫描日志"
    $dl = "$env:ProgramData\Microsoft\Windows Defender\Scans\History"
    if (Test-Path $dl) { try { Remove-Item "$dl\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Defender 扫描日志已清理。" "Green" } catch { Write-Err "清理 Defender 日志失败: $_" } }
    else { Write-Log "未找到 Defender 扫描日志目录。" "Yellow" }
    Show-CleaningLine " "
}

# --- 菜单清单 ---
$allItems = @(
    @{Name="清空回收站 (-rb)"; Action="Clean-RecycleBin"},
    @{Name="清理系统/用户临时文件 (-t)"; Action="Clean-Temp"},
    @{Name="清理下载临时区 (-td)"; Action="Clean-TempDownload"},
    @{Name="清理最近访问记录 (-r)"; Action="Clean-Recent"},
    @{Name="清理预读取缓存 (-pf)"; Action="Clean-Prefetch"},
    @{Name="清理缩略图缓存 (-th)"; Action="Clean-Thumbnails"},
    @{Name="清理系统日志 (-l)"; Action="Clean-Logs"},
    @{Name="清理 Windows 错误报告 (-er)"; Action="Clean-ErrorReports"},
    @{Name="清理 Dump 文件 (-df)"; Action="Clean-DumpFiles"},
    @{Name="清理 Windows 更新缓存 (-uc)"; Action="Clean-UpdateCache"},
    @{Name="清理系统升级残留 (-ur)"; Action="Clean-UpgradeResiduals"},
    @{Name="清理 Windows.old (-wo)"; Action="Clean-WindowsOld"},
    @{Name="清理 Delivery Optimization (-do)"; Action="Clean-DeliveryOptimization"},
    @{Name="清理旧驱动 (-od)"; Action="Clean-OldDrivers"},
    @{Name="清理字体缓存 (-fc)"; Action="Clean-FontsCache"},
    @{Name="清理搜索索引缓存 (-sc)"; Action="Clean-SearchCache"},
    @{Name="清理浏览器缓存 (-b)"; Action="Clean-Browsers"},
    @{Name="清理 Edge Chromium 用户数据 (-eu)"; Action="Clean-EdgeUserCache"},
    @{Name="清理 Office 缓存 (-oc)"; Action="Clean-OfficeCache"},
    @{Name="清理 OneDrive 本地缓存 (-on)"; Action="Clean-OneDriveCache"},
    @{Name="清理 UWP/APPX 包缓存 (-ac)"; Action="Clean-AppxCache"},
    @{Name="清理商店与 UWP 应用缓存 (-st)"; Action="Clean-StoreCache"},
    @{Name="清理 WSL 临时空间 (-ws)"; Action="Clean-WSLTemp"},
    @{Name="清理打印机缓存 (-pc)"; Action="Clean-PrinterCache"},
    @{Name="清理 Defender 扫描日志 (-dl)"; Action="Clean-DefenderLogs"}
)

# --- 主流程 ---
$selectedActions = @()
if ($All) {
    $selectedActions = $allItems
} elseif (-not (
    $All -or $RecycleBin -or $Temp -or $TempDownload -or $Recent -or $Prefetch -or $Thumbnails -or $Logs -or $ErrorReports -or $DumpFiles -or $UpdateCache -or $UpgradeResiduals -or $WindowsOld -or $DeliveryOptimization -or $OldDrivers -or $FontsCache -or $SearchCache -or $Browsers -or $EdgeUserCache -or $OfficeCache -or $OneDriveCache -or $AppxCache -or $StoreCache -or $WSLTemp -or $PrinterCache -or $DefenderLogs
)) {
    Write-Log "请输入要执行的清理项目（用空格多选，回车确定）：" "Cyan"
    for ($i=0; $i -lt $allItems.Count; $i++) { Write-Host "[$i] $($allItems[$i].Name)" }
    $sel = Read-Host "请输入要清理的序号（支持多个，用空格分隔，如 1 2 3）"
    $indices = $sel -split "\s+" | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 0 -and [int]$_ -lt $allItems.Count }
    if ($indices.Count -eq 0) { Write-Log "未选择任何项目，已退出。" "Yellow"; exit 0 }
    foreach ($idx in $indices) { $selectedActions += $allItems[$idx] }
} else {
    if ($RecycleBin)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-RecycleBin" } }
    if ($Temp)               { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Temp" } }
    if ($TempDownload)       { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-TempDownload" } }
    if ($Recent)             { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Recent" } }
    if ($Prefetch)           { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Prefetch" } }
    if ($Thumbnails)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Thumbnails" } }
    if ($Logs)               { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Logs" } }
    if ($ErrorReports)       { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-ErrorReports" } }
    if ($DumpFiles)          { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-DumpFiles" } }
    if ($UpdateCache)        { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-UpdateCache" } }
    if ($UpgradeResiduals)   { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-UpgradeResiduals" } }
    if ($WindowsOld)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-WindowsOld" } }
    if ($DeliveryOptimization) { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-DeliveryOptimization" } }
    if ($OldDrivers)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-OldDrivers" } }
    if ($FontsCache)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-FontsCache" } }
    if ($SearchCache)        { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-SearchCache" } }
    if ($Browsers)           { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-Browsers" } }
    if ($EdgeUserCache)      { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-EdgeUserCache" } }
    if ($OfficeCache)        { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-OfficeCache" } }
    if ($OneDriveCache)      { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-OneDriveCache" } }
    if ($AppxCache)          { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-AppxCache" } }
    if ($StoreCache)         { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-StoreCache" } }
    if ($WSLTemp)            { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-WSLTemp" } }
    if ($PrinterCache)       { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-PrinterCache" } }
    if ($DefenderLogs)       { $selectedActions += $allItems | Where-Object { $_.Action -eq "Clean-DefenderLogs" } }
}

$total = $selectedActions.Count
if ($total -eq 0) {
    Write-Log "未选择任何清理项目，已退出。" "Yellow"
    exit 0
}

for ($i = 0; $i -lt $total; $i++) {
    $item = $selectedActions[$i]
    Show-ProgressBar ($i+1) $total $item.Name
    & $item.Action
}
Show-ProgressBar $total $total "全部完成"
Show-CleaningLine ""
Write-Host "`n所有选定清理项目已执行完成。" -ForegroundColor Green
exit 0