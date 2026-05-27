param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'

function Update-PlayReleaseNotesFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $notesPath = Join-Path $ProjectRoot 'docs\play-release-notes.md'
    if (-not (Test-Path $notesPath)) {
        Write-Warning "Release notes file not found, skipped: $notesPath"
        return
    }

    $content = Get-Content -Path $notesPath -Raw
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $buildName = ($Version -split '\+')[0]
    $releaseName = "v$buildName"
    $startMarker = '<!-- AUTO-GENERATED:START -->'
    $endMarker = '<!-- AUTO-GENERATED:END -->'

    $autoBlock = @"
$startMarker
## Auto Updated Build Metadata

- Build version: $Version
- Release name: $releaseName
- Last updated: $timestamp

$endMarker
"@

    $updatedContent = $content
    $markerPattern = '(?s)<!-- AUTO-GENERATED:START -->.*?<!-- AUTO-GENERATED:END -->'
    if ([regex]::IsMatch($content, $markerPattern)) {
        $updatedContent = [regex]::Replace($content, $markerPattern, $autoBlock, 1)
    } else {
        $instructionPattern = '(?m)^Use this exact block in Google Play Console release notes\.\s*$'
        if ([regex]::IsMatch($content, $instructionPattern)) {
            $updatedContent = [regex]::Replace(
                $content,
                $instructionPattern,
                "$0`r`n`r`n$autoBlock",
                1
            )
        } else {
            $updatedContent = "$autoBlock`r`n`r`n$content"
        }
    }

    Set-Content -Path $notesPath -Value $updatedContent -Encoding UTF8
    Write-Host "Release notes metadata updated: $notesPath"
}

if (-not (Test-Path $pubspecPath)) {
    throw "pubspec.yaml not found at $pubspecPath"
}

$content = Get-Content -Path $pubspecPath -Raw
$match = [regex]::Match($content, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')

if (-not $match.Success) {
    throw 'Could not parse version from pubspec.yaml. Expected format: version: X.Y.Z+N'
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value + 1
$build = [int]$match.Groups[4].Value + 1

$newVersion = "$major.$minor.$patch+$build"
$newContent = [regex]::Replace(
    $content,
    '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$',
    "version: $newVersion",
    1
)

Set-Content -Path $pubspecPath -Value $newContent -Encoding UTF8
Write-Host "Version bumped to $newVersion"
Update-PlayReleaseNotesFile -ProjectRoot $projectRoot -Version $newVersion

if ($SkipBuild) {
    Write-Host 'SkipBuild provided. Exiting after version bump.'
    exit 0
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
    $flutterExecutable = 'flutter'
} elseif (Test-Path 'C:\flutter\bin\flutter.bat') {
    $flutterExecutable = 'C:\flutter\bin\flutter.bat'
} else {
    throw 'Flutter executable not found. Add flutter to PATH or install at C:\flutter\bin\flutter.bat'
}

Push-Location $projectRoot
try {
    & $flutterExecutable build appbundle --flavor free
    if ($LASTEXITCODE -ne 0) {
        throw "AAB build failed with exit code $LASTEXITCODE"
    }

    $artifact = Join-Path $projectRoot 'build\app\outputs\bundle\freeRelease\app-free-release.aab'
    if (-not (Test-Path $artifact)) {
        throw "Build completed but artifact not found: $artifact"
    }

    $item = Get-Item $artifact
    Write-Host ''
    Write-Host "AAB ready: $($item.FullName)"
    Write-Host "Size (bytes): $($item.Length)"
    Write-Host "Updated: $($item.LastWriteTime)"
} finally {
    Pop-Location
}
