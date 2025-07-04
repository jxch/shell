#requires -Version 5.0
<#
.SYNOPSIS
    使用 ImageMagick 批量或单独压缩图片至指定大小，尽可能保持画质。

.DESCRIPTION
    本脚本通过自动调整图片的压缩质量，将一张或多张图片压缩到目标大小以下，
    支持自定义初始画质、最小画质、目标大小（支持 B/KB/MB/GB 单位），
    并自动检测是否安装 ImageMagick，并支持静默模式和彩色控制台输出。

.PARAMETER InputFile
    （必需）要压缩的图片文件路径/路径数组。可用 -i 或 -InputFile 指定。

.PARAMETER OutputFile
    （可选）压缩后图片的输出文件路径/路径数组，数量需与输入文件一致。
    若未指定，则自动在原文件名前加 compressed_ 前缀。可用 -o 或 -OutputFile 指定。

.PARAMETER TargetSize
    （可选）目标文件大小，支持 B/KB/MB/GB 单位，如 3500KB、2MB、5000000B，默认 4MB。可用 -s 或 -TargetSize 指定。

.PARAMETER Quality
    （可选）初始画质（1-100），默认 95。可用 -q 或 -Quality 指定。

.PARAMETER MinQuality
    （可选）最低画质（1-100），默认 60。可用 -mq 或 -MinQuality 指定。

.PARAMETER Silent
    （可选）静默模式，屏蔽所有控制台输出，仅保留错误。可用 -slt 或 -Silent 指定。

.EXAMPLE
    .\imageQ.ps1 -i photo1.jpg,photo2.png

.EXAMPLE
    .\imageQ.ps1 -i img1.jpg,img2.jpg -o out1.jpg,out2.jpg -s 2MB

.EXAMPLE
    .\imageQ.ps1 -i .\*.jpg -s 1500KB -q 88

.EXAMPLE
    .\imageQ.ps1 -i .\*.png -Silent

.NOTES
    如未安装 ImageMagick，请先执行：
    winget install ImageMagick.ImageMagick
#>

param(
    [Alias('i')]
    [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="输入图片路径（支持多个）")]
    [string[]]$InputFile,

    [Alias('o')]
    [Parameter(Mandatory=$false, HelpMessage="输出文件路径（支持多个）")]
    [string[]]$OutputFile,

    [Alias('s')]
    [Parameter(Mandatory=$false, HelpMessage="目标大小，如 2MB、3500KB、5000000B，默认4MB")]
    [string]$TargetSize = "4MB",

    [Alias('q')]
    [Parameter(Mandatory=$false, HelpMessage="初始画质（1-100），默认95")]
    [int]$Quality = 95,

    [Alias('mq')]
    [Parameter(Mandatory=$false, HelpMessage="最低画质（1-100），默认60")]
    [int]$MinQuality = 60,

    [Alias('slt')]
    [Parameter(Mandatory=$false, HelpMessage="静默模式，屏蔽所有控制台输出，仅保留错误")]
    [switch]$Silent,

    [Alias('?', '/?', '/h')]
    [Switch]$Help
)

$helpText = @"
imageQ.ps1 - 批量或单独压缩图片到指定大小（需 ImageMagick）

【语法】
    .\imageQ.ps1 -i <输入图片> [-o <输出图片>] [-s <目标大小>] [-q <初始画质>] [-mq <最低画质>] [-Silent]
    .\imageQ.ps1 -? | -Help

【参数说明】
    -i, -InputFile   (必需)   输入图片路径，支持通配符和数组，如 .\*.jpg 或 img1.jpg,img2.png
    -o, -OutputFile  (可选)   输出图片路径，必须与输入数量一致，未指定则自带前缀 compressed_
    -s, -TargetSize  (可选)   目标压缩大小，支持 B/KB/MB/GB，如 2MB、1800KB，默认4MB
    -q, -Quality     (可选)   初始画质，1-100，默认95
    -mq, -MinQuality (可选)   最低画质，1-100，默认60
    -Silent, -slt    (可选)   静默模式，仅保留错误输出
    -?, -Help        (可选)   显示本帮助信息

【示例】
    .\imageQ.ps1 -i .\*.jpg
    .\imageQ.ps1 -i img1.jpg,img2.png -s 2MB
    .\imageQ.ps1 -i img1.jpg,img2.jpg -o out1.jpg,out2.jpg -q 90
    .\imageQ.ps1 -i .\*.png -Silent
    .\imageQ.ps1 -Help

【注意】
    必须预先安装 ImageMagick，未安装可运行：
    winget install ImageMagick.ImageMagick
"@

if ($Help -or !$InputFile) {
    Write-Host $helpText -ForegroundColor Cyan
    exit 0
}

function Write-Info {
    param([string]$msg)
    if (-not $Silent) { Write-Host $msg -ForegroundColor White }
}
function Write-Success {
    param([string]$msg)
    if (-not $Silent) { Write-Host $msg -ForegroundColor Green }
}
function Write-WarningColor {
    param([string]$msg)
    if (-not $Silent) { Write-Host $msg -ForegroundColor Yellow }
}
function Write-Title {
    param([string]$msg)
    if (-not $Silent) { Write-Host $msg -ForegroundColor Cyan }
}
function Write-ErrorColor {
    param([string]$msg)
    Write-Host $msg -ForegroundColor Red
}

function Convert-ToBytes {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SizeStr
    )
    $size = $SizeStr.ToUpper().Trim()
    if ($size -match '^(\d+(\.\d+)?)(B|KB|MB|GB)?$') {
        $value = [double]$matches[1]
        switch ($matches[3]) {
            "B"  { return [int]$value }
            "KB" { return [int]($value * 1KB) }
            "MB" { return [int]($value * 1MB) }
            "GB" { return [int]($value * 1GB) }
            default { return [int]$value }
        }
    } else {
        throw "目标大小格式错误，请输入如 2500KB、4MB、5000000B 等格式"
    }
}

function Test-ImageMagickInstalled {
    $null = & magick -version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-WarningColor "未检测到 ImageMagick，请先安装：winget install ImageMagick.ImageMagick"
        exit 1
    }
}

function Compress-Image {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [int]$TargetBytes,
        [int]$Quality,
        [int]$MinQuality
    )

    if (-not (Test-Path $InputFile)) {
        throw "输入文件不存在: $InputFile"
    }

    $TempFile = [System.IO.Path]::GetTempFileName() + [System.IO.Path]::GetExtension($InputFile)
    $currentQuality = $Quality
    $step = 5

    do {
        & magick "$InputFile" -quality $currentQuality "$TempFile"
        $FileSize = (Get-Item "$TempFile").Length

        Write-Info "【$InputFile】尝试质量: $currentQuality, 文件大小: $([math]::Round($FileSize / 1MB, 2)) MB"

        if ($FileSize -gt $TargetBytes -and $currentQuality -gt $MinQuality) {
            $currentQuality -= $step
            if ($currentQuality -lt $MinQuality) { $currentQuality = $MinQuality }
        } else {
            break
        }
    } while ($true)

    Move-Item "$TempFile" "$OutputFile" -Force
    Write-Success "【$InputFile】压缩完成: $OutputFile, 最终质量: $currentQuality, 文件大小: $([math]::Round((Get-Item $OutputFile).Length/1MB,2)) MB"
}

try {
    Test-ImageMagickInstalled

    $TargetBytes = Convert-ToBytes $TargetSize

    if ($OutputFile) {
        if ($OutputFile.Count -ne $InputFile.Count) {
            throw "OutputFile 数量($($OutputFile.Count))必须与 InputFile 数量($($InputFile.Count))一致！"
        }
    } else {
        $OutputFile = $InputFile | ForEach-Object {
            Join-Path (Split-Path $_ -Parent) ("compressed_" + (Split-Path $_ -Leaf))
        }
    }

    for ($i=0; $i -lt $InputFile.Count; $i++) {
        try {
            Write-Title "`n========== [$(($i+1))/${($InputFile.Count)}] =========="
            Write-Info "输入文件: $($InputFile[$i])"
            Write-Info "输出文件: $($OutputFile[$i])"
            Write-Info "目标大小: $TargetSize ($TargetBytes 字节)"
            Write-Info "初始画质: $Quality"
            Write-Info "最低画质: $MinQuality"
            Compress-Image -InputFile $InputFile[$i] -OutputFile $OutputFile[$i] -TargetBytes $TargetBytes -Quality $Quality -MinQuality $MinQuality
        }
        catch {
            Write-ErrorColor "处理文件 $($InputFile[$i]) 时出错：$($_.Exception.Message)"
        }
    }
}
catch {
    Write-ErrorColor $_.Exception.Message
}