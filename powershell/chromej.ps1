# 不需要 param()，直接用 $args

# ------------- 参数解析 ---------------
$knownSwitches = @(
    "-ChromePath","-c",
    "-RootDir","-r",
    "-Url","-u",
    "-Delete","-d",
    "-Yes","-y",
    "-Activate","-a",
    "-Help",
    "-ShowCmd","-sc",
    "-Silent","-s"
)
$ProfileNames = @()
$ChromePath = $null
$RootDir = "C:\ProgramData\chrome"
$Url = $null
$Delete = $false
$Yes = $false
$Activate = $false
$Help = $false
$ShowCmd = $false
$Silent = $false
$ExtraChromeArgs = @()

$expectValue = $null
foreach ($arg in $args) {
    if ($expectValue) {
        switch ($expectValue) {
            "ChromePath" { $ChromePath = $arg }
            "RootDir"    { $RootDir    = $arg }
            "Url"        { $Url        = $arg }
        }
        $expectValue = $null
        continue
    }
    switch -Regex ($arg) {
        "^(-ChromePath|-c)$" { $expectValue = "ChromePath"; continue }
        "^(-RootDir|-r)$"    { $expectValue = "RootDir";    continue }
        "^(-Url|-u)$"        { $expectValue = "Url";        continue }
        "^(-Delete|-d)$"     { $Delete   = $true; continue }
        "^(-Yes|-y)$"        { $Yes      = $true; continue }
        "^(-Activate|-a)$"   { $Activate = $true; continue }
        "^(-Help)$"          { $Help     = $true; continue }
        "^(-ShowCmd|-sc)$"   { $ShowCmd  = $true; continue }
        "^(-Silent|-s)$"     { $Silent   = $true; continue }
        default {
            if ($arg -notmatch "^-" -and $arg -match '^[\w\-]+$' -and -not $Delete) {
                $ProfileNames += $arg
            } else {
                $ExtraChromeArgs += $arg
            }
        }
    }
}

function Show-Help {
@"
chromej.ps1 - Windows 多开独立 Chrome 实例工具

【用途说明】
    一键多开 Chrome 独立配置实例；支持 profile 目录管理、进程激活、参数透传、批量删除、静默运行等高级场景。

【基本用法】
    chromej.ps1 <Profile1> [<Profile2> ...] [chrome原生参数] [选项]
    chromej.ps1 <Profile> -Delete [-Yes]
    chromej.ps1 [chrome原生参数] [选项]              # 无 profile 时只启动本体

【参数说明】
    <Profile>           可选，支持多个。Profile 名称或编号（仅字母、数字、下划线、横线），用于多开或批量操作。
    -ChromePath, -c     可选。指定 Chrome 可执行文件路径。
    -RootDir, -r        可选。Profile 配置根目录（默认 C:\ProgramData\chrome）。
    -Url, -u            可选。Chrome 启动时自动打开的网页。
    -Delete, -d         可选。删除指定 Profile 目录（危险操作！且不可逆！）。
    -Yes, -y            可选。删除时无需确认，直接强制删除。
    -Activate, -a       可选。如 profile 已有进程，激活其窗口，不重复启动。
    -ShowCmd, -sc       可选。输出完整 chrome.exe 启动命令行参数。
    -Silent, -s         可选。静默执行，除错误外无任何输出。
    -Help               可选。显示此帮助信息。
    chrome原生参数      其余未识别参数，均原样透传给 Chrome（如 --incognito、--disable-gpu 等）。

【典型示例】
    chromej.ps1 1 2 --disable-web-security --incognito
        # 启动/多开 1、2 两个 profile，并传递原生参数

    chromej.ps1 dev -a -u "https://example.com" --disable-gpu
        # 激活已开的 dev profile，或未开则以指定网址和参数新开

    chromej.ps1 1 -Delete -y
        # 强制删除 1 号 profile 目录，无需确认

    chromej.ps1 --disable-software-rasterizer -sc
        # 启动 Chrome 并显示完整命令行

    chromej.ps1 -s
        # 静默启动 Chrome 本体

    chromej.ps1 1 2 3 -Activate -ShowCmd -Silent
        # 激活/多开 1、2、3，命令行输出，静默执行

【使用说明】
  - 可同时指定多个 profile，实现批量多开、批量激活或批量删除。
  - 选项顺序不限，Profile 名/Chrome 参数可混排。
  - 支持所有 Chrome 原生命令行参数，未识别参数自动透传。
  - -Url 仅对每个 profile 的第一个新实例生效，后续参数均透传。
  - -Delete 与 -Activate 可组合批量操作；静默模式下仅输出错误信息。
  - 指定 -ShowCmd 时，展示完整 chrome.exe 启动命令（含所有参数）。
  - 建议将此脚本路径加入 PATH，或以脚本名直接调用。

【注意事项】
  - 删除 profile 时请确保对应 Chrome 进程已关闭，否则操作会中断。
  - 启动 profile 目录若不存在将自动创建。
  - Profile 名称仅允许字母、数字、下划线、横线，且不能与选项冲突。
  - 强烈建议定期备份重要 profile 数据。

【作者】
  JXCH
  https://github.com/jxch/shell/blob/main/powershell/chromej.ps1
  反馈建议请在仓库 issues 提交

"@ | Write-Host
}

function Write-Info($msg) {
    if (-not $Silent) { Write-Host $msg }
}

function Write-ErrorMsg($msg) {
    Write-Host $msg -ForegroundColor Red
}

if ($Help) {
    Show-Help
    exit 0
}

# 查找 Chrome 可执行文件
$chromeCandidates = @(
    $ChromePath,
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
)
$chromeExe = $null
foreach ($path in $chromeCandidates) {
    if ($path -and (Test-Path $path)) {
        $chromeExe = $path
        break
    }
}
if (-not $chromeExe) {
    Write-ErrorMsg "未找到 Chrome（chrome.exe），请用 -ChromePath 参数指定。"
    exit 2
}

# 多 profile 执行
if ($ProfileNames -and $ProfileNames.Count -gt 0) {
    foreach ($ProfileName in $ProfileNames) {
        # ProfileName 非法检测
        if ($ProfileName -notmatch '^[\w\-]+$') {
            Write-ErrorMsg "Profile 名称只能使用字母、数字、下划线、横线: $ProfileName"
            continue
        }
        $profileDir = Join-Path -Path $RootDir -ChildPath $ProfileName

        # 删除功能
        if ($Delete) {
            if (Test-Path $profileDir) {
                $usedBy = Get-CimInstance Win32_Process | Where-Object {
                    $_.Name -match 'chrome\.exe' -and $_.CommandLine -match [regex]::Escape($profileDir)
                }
                if ($usedBy) {
                    Write-Info "⚠️ 检测到下列 Chrome 进程正在使用此 profile 目录："
                    $usedBy | ForEach-Object { Write-Info "  PID=$($_.ProcessId) $($_.CommandLine)" }
                    Write-Info "请先关闭上述 Chrome 进程，再执行删除。"
                    continue
                }
                $doDelete = $Yes
                if (-not $Yes) {
                    Write-Info "请确认是否删除配置目录: $profileDir"
                    $confirmation = Read-Host "输入 Y 确认删除，其他任意键取消"
                    if ($confirmation.ToUpper() -eq 'Y') {
                        $doDelete = $true
                    } else {
                        Write-Info "已取消删除。"
                        continue
                    }
                }
                if ($doDelete) {
                    try {
                        Remove-Item -Path $profileDir -Recurse -Force -ErrorAction Stop
                        Write-Info "已删除: $profileDir"
                    } catch {
                        $remaining = Get-ChildItem -Path $profileDir -Recurse -Force -ErrorAction SilentlyContinue
                        if ($remaining) {
                            Write-ErrorMsg "部分文件/目录未能删除，可能被占用："
                            $remaining | ForEach-Object { Write-ErrorMsg $_.FullName }
                            Write-Info "请确保所有相关 Chrome 进程已关闭后重试。"
                        } else {
                            Write-ErrorMsg "删除目录失败: $profileDir"
                        }
                        continue
                    }
                }
            } else {
                Write-Info "目录不存在: $profileDir"
            }
            continue
        }

        # 检查是否已存在进程
        $chromeProc = Get-CimInstance Win32_Process | Where-Object {
            $_.Name -match 'chrome\.exe' -and $_.CommandLine -match [regex]::Escape($profileDir)
        }

        if ($chromeProc -and $Activate) {
            Write-Info "Profile [$ProfileName] 已有进程，正在激活窗口..."
            foreach ($proc in $chromeProc) {
                $procId = $proc.ProcessId
                $sig = '
                [DllImport("user32.dll")]
                public static extern bool SetForegroundWindow(IntPtr hWnd);
                [DllImport("user32.dll")]
                public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
                Add-Type -MemberDefinition $sig -Name WinAPI -Namespace Win -PassThru -ErrorAction SilentlyContinue | Out-Null

                try {
                    $handles = Get-Process -Id $procId -ErrorAction Stop | ForEach-Object { $_.MainWindowHandle }
                } catch {
                    Write-Info "进程 $procId 不存在，已跳过。"
                    continue
                }
                foreach ($h in $handles) {
                    if ($h -and $h -ne 0) {
                        [Win.WinAPI]::ShowWindowAsync($h, 9) | Out-Null  # SW_RESTORE
                        [Win.WinAPI]::SetForegroundWindow($h) | Out-Null
                    }
                }
            }
            continue
        }

        # 若没进程或不激活，则正常启动
        if (-not (Test-Path $profileDir)) {
            try {
                $null = New-Item -ItemType Directory -Path $profileDir -Force
                Write-Info "已创建配置目录: $profileDir"
            } catch {
                Write-ErrorMsg "创建目录失败: $profileDir"
                continue
            }
        } else {
            Write-Info "配置目录已存在: $profileDir"
        }
        $chromeArgs = @("--user-data-dir=`"$profileDir`"")
        if ($Url) { $chromeArgs += $Url }
        if ($ExtraChromeArgs.Count -gt 0) { $chromeArgs += $ExtraChromeArgs }

        if ($ShowCmd) {
            $joined = $chromeArgs | ForEach-Object { "`"$_`"" }
            Write-Host "CMD: `"$chromeExe`" $($joined -join ' ')" -ForegroundColor Cyan
        }

        if (-not $Silent) {
            Write-Info "------------------------------------------------------"
            Write-Info "Chrome 路径: $chromeExe"
            Write-Info "Profile 目录: $profileDir"
            if ($Url) { Write-Info "启动网址 : $Url" }
            if ($ExtraChromeArgs.Count -gt 0) { Write-Info "Chrome 原生参数: $($ExtraChromeArgs -join ' ')" }
            Write-Info "------------------------------------------------------"
        }
        try {
            Start-Process -FilePath $chromeExe -ArgumentList $chromeArgs
            if (-not $Silent) { Write-Info "Chrome [$ProfileName] 启动成功！" }
        } catch {
            Write-ErrorMsg "Chrome 启动失败: $_"
            continue
        }
    }
    exit 0
}

# 无 profile 时，直接启动本体
if (-not $ProfileNames -or $ProfileNames.Count -eq 0) {
    if (-not $Silent) { Write-Info "未指定 ProfileName，直接启动 Chrome 本体。" }
    try {
        $chromeArgs = @()
        if ($Url) { $chromeArgs += $Url }
        if ($ExtraChromeArgs.Count -gt 0) { $chromeArgs += $ExtraChromeArgs }
        if ($ShowCmd) {
            $joined = $chromeArgs | ForEach-Object { "`"$_`"" }
            Write-Host "CMD: `"$chromeExe`" $($joined -join ' ')" -ForegroundColor Cyan
        }
        if (-not $Silent) {
            if ($Url) { Write-Info "启动网址 : $Url" }
            if ($ExtraChromeArgs.Count -gt 0) { Write-Info "Chrome 原生参数: $($ExtraChromeArgs -join ' ')" }
        }
        if ($chromeArgs.Count -gt 0) {
            Start-Process -FilePath $chromeExe -ArgumentList $chromeArgs
        } else {
            Start-Process -FilePath $chromeExe
        }
        if (-not $Silent) { Write-Info "已启动 Chrome。" }
    } catch {
        Write-ErrorMsg "Chrome 启动失败: $_"
        exit 4
    }
    exit 0
}