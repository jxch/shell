param(
    [Parameter(Position=0, Mandatory=$false)]
    [Alias("n")]
    [string]$ProfileName,

    [Parameter(Position=1, Mandatory=$false)]
    [Alias("c")]
    [string]$ChromePath,

    [Parameter(Position=2, Mandatory=$false)]
    [Alias("r")]
    [string]$RootDir = "C:\ProgramData\chrome",

    [Parameter(Position=3, Mandatory=$false)]
    [Alias("u")]
    [string]$Url,

    [Parameter(Mandatory=$false)]
    [switch]$Help,

    [Parameter(Mandatory=$false)]
    [Alias("d")]
    [switch]$Delete,

    [Parameter(Mandatory=$false)]
    [Alias("y")]
    [switch]$Yes
)

function Show-Help {
@"
chromej.ps1 - Windows 多开独立 Chrome 配置实例脚本（带 profile 删除功能）

【基本用法】
    .\chromej.ps1 <ProfileName> [-ChromePath <chrome.exe路径>] [-RootDir <配置根目录>] [-Url <网址>]
    .\chromej.ps1 <ProfileName> -Delete [-y]
    .\chromej.ps1 [-ChromePath <chrome.exe路径>] [-Url <网址>]

【参数说明】
    ProfileName      可选。Profile 名称或编号（仅字母、数字、下划线、横线）。
    -ChromePath/-c   可选。手动指定 Chrome 可执行文件路径。
    -RootDir/-r      可选。Profile 配置根目录（默认 C:\ProgramData\chrome）。
    -Url/-u          可选。Chrome 启动时自动打开的网页。
    -Delete/-d       删除指定 Profile 目录（危险操作！且不可逆！）。
    -y               删除时无需确认（强制删除）。
    -Help            显示本帮助信息。

【示例】
    .\chromej.ps1 1
    .\chromej.ps1 devtest -Url "https://example.com"
    .\chromej.ps1 test2 -ChromePath "D:\chrome\chrome.exe" -RootDir "D:\chrome-profiles"
    .\chromej.ps1 1 -Delete
    .\chromej.ps1 1 -Delete -y
    .\chromej.ps1 -Help
    .\chromej.ps1 -ChromePath "D:\chrome\chrome.exe" -Url "https://example.com"
    .\chromej.ps1 -Url "https://example.com"

【功能扩展】
    - 自动查找常规 Chrome 路径
    - 自动递归创建 profile 目录
    - 各 profile 互不干扰，可多实例同时打开
    - 支持一键删除 profile 目录（检测进程占用，静默模式下无需确认）
    - 删除时如有占用文件，列出未能删除的内容

【作者】
    JXCH
"@ | Write-Host
}

if ($Help) {
    Show-Help
    exit 0
}

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
    Write-Host "未找到 Chrome（chrome.exe），请用 -ChromePath 参数指定。" -ForegroundColor Red
    exit 2
}

# 如果没有ProfileName且没有-Delete参数，直接启动chrome.exe（支持 -ChromePath 和 -Url）
if (-not $ProfileName -and -not $Delete) {
    Write-Host "未指定 ProfileName，直接启动 Chrome 本体。"
    try {
        if ($Url) {
            Write-Host "启动网址 : $Url"
            Start-Process -FilePath $chromeExe -ArgumentList $Url
        } else {
            Start-Process -FilePath $chromeExe
        }
        Write-Host "已启动 Chrome。"
    } catch {
        Write-Host "Chrome 启动失败: $_" -ForegroundColor Red
        exit 4
    }
    exit 0
}

if ($ProfileName -and ($ProfileName -notmatch '^[\w\-]+$')) {
    Write-Host "Profile 名称只能使用字母、数字、下划线、横线。" -ForegroundColor Red
    exit 1
}

$profileDir = Join-Path -Path $RootDir -ChildPath $ProfileName

if ($Delete) {
    if ($ProfileName -and (Test-Path $profileDir)) {
        $usedBy = Get-CimInstance Win32_Process | Where-Object {
            $_.Name -match 'chrome\.exe' -and $_.CommandLine -match [regex]::Escape($profileDir)
        }
        if ($usedBy) {
            Write-Host "⚠️ 检测到下列 Chrome 进程正在使用此 profile 目录：" -ForegroundColor Yellow
            $usedBy | ForEach-Object { Write-Host "  PID=$($_.ProcessId) $($_.CommandLine)" }
            Write-Host "请先关闭上述 Chrome 进程，再执行删除。" -ForegroundColor Yellow
            exit 6
        }

        $doDelete = $Yes
        if (-not $Yes) {
            Write-Host "请确认是否删除配置目录: $profileDir" -ForegroundColor Yellow
            $confirmation = Read-Host "输入 Y 确认删除，其他任意键取消"
            if ($confirmation.ToUpper() -eq 'Y') {
                $doDelete = $true
            } else {
                Write-Host "已取消删除。"
                exit 0
            }
        }
        if ($doDelete) {
            try {
                Remove-Item -Path $profileDir -Recurse -Force -ErrorAction Stop
                Write-Host "已删除: $profileDir" -ForegroundColor Green
            } catch {
                $remaining = Get-ChildItem -Path $profileDir -Recurse -Force -ErrorAction SilentlyContinue
                if ($remaining) {
                    Write-Host "部分文件/目录未能删除，可能被占用：" -ForegroundColor Red
                    $remaining | ForEach-Object { Write-Host $_.FullName }
                    Write-Host "请确保所有相关 Chrome 进程已关闭后重试。" -ForegroundColor Yellow
                } else {
                    Write-Host "删除目录失败: $profileDir" -ForegroundColor Red
                }
                exit 5
            }
        }
    } elseif (-not $ProfileName) {
        Write-Host "未指定 ProfileName，无需删除 profile 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "目录不存在: $profileDir" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path $profileDir)) {
    try {
        $null = New-Item -ItemType Directory -Path $profileDir -Force
        Write-Host "已创建配置目录: $profileDir"
    } catch {
        Write-Host "创建目录失败: $profileDir" -ForegroundColor Red
        exit 3
    }
} else {
    Write-Host "配置目录已存在: $profileDir"
}

$chromeArgs = @("--user-data-dir=`"$profileDir`"")
if ($Url) {
    $chromeArgs += $Url
}

Write-Host "------------------------------------------------------"
Write-Host "Chrome 路径: $chromeExe"
Write-Host "Profile 目录: $profileDir"
if ($Url) { Write-Host "启动网址 : $Url" }
Write-Host "------------------------------------------------------"

try {
    Start-Process -FilePath $chromeExe -ArgumentList $chromeArgs
    Write-Host "Chrome 启动成功！"
} catch {
    Write-Host "Chrome 启动失败: $_" -ForegroundColor Red
    exit 4
}