param(
    [Parameter(Mandatory = $true)]
    [string]$KeystorePath,

    [Parameter(Mandatory = $true)]
    [string]$Alias,

    [Parameter(Mandatory = $true)]
    [string]$StorePassword,

    [Parameter(Mandatory = $false)]
    [string]$KeyPassword = ""
)

$ErrorActionPreference = "Stop"
$targetFingerprint = "03:36:BA:E9:EF:D3:26:4B:60:CD:F5:46:6C:65:FF:BE:03:25:8D:FC:15:BC:21:72:C6:30:70:54:49:37:49:02"

if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
    $KeyPassword = $StorePassword
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot "android"
$keyPropsPath = Join-Path $androidDir "key.properties"
$gradleWrapper = Join-Path $androidDir "gradlew.bat"
$apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-free-release.apk"

if (-not (Test-Path $KeystorePath)) {
    throw "Keystore not found: $KeystorePath"
}

$resolvedKeystore = (Resolve-Path $KeystorePath).Path

$keystoreInfo = & keytool -list -v -keystore $resolvedKeystore -alias $Alias -storepass $StorePassword -keypass $KeyPassword 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Cannot read keystore or alias. Check path/alias/passwords."
}

$keystoreFingerprintLine = ($keystoreInfo | Select-String "SHA256:" | Select-Object -First 1).Line
if ([string]::IsNullOrWhiteSpace($keystoreFingerprintLine)) {
    throw "Could not extract SHA256 fingerprint from keystore."
}

$keystoreFingerprint = ($keystoreFingerprintLine -replace '.*SHA256:\s*', '').Trim().ToUpperInvariant()
if ($keystoreFingerprint -ne $targetFingerprint) {
    throw "Fingerprint mismatch. Found: $keystoreFingerprint | Required: $targetFingerprint"
}

if (-not (Test-Path $keyPropsPath)) {
    throw "Missing key.properties at $keyPropsPath"
}

$backupPath = "$keyPropsPath.bak.copilot"
Copy-Item -Path $keyPropsPath -Destination $backupPath -Force

try {
    $relativeStore = [System.IO.Path]::GetRelativePath($androidDir, $resolvedKeystore).Replace('\\', '/')
    $newProps = @(
        "storePassword=$StorePassword",
        "keyPassword=$KeyPassword",
        "keyAlias=$Alias",
        "storeFile=$relativeStore"
    )
    Set-Content -Path $keyPropsPath -Value $newProps -Encoding ASCII

    Push-Location $androidDir
    try {
        & $gradleWrapper ":app:assembleFreeRelease"
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle build failed while signing APK."
        }
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path $apkPath)) {
        throw "Signed APK not found at $apkPath"
    }

    $apkInfo = & keytool -printcert -jarfile $apkPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Could not read APK certificate."
    }

    $apkFingerprintLine = ($apkInfo | Select-String "SHA256:" | Select-Object -First 1).Line
    $apkFingerprint = ($apkFingerprintLine -replace '.*SHA256:\s*', '').Trim().ToUpperInvariant()

    if ($apkFingerprint -ne $targetFingerprint) {
        throw "APK fingerprint mismatch. Found: $apkFingerprint | Required: $targetFingerprint"
    }

    Write-Host "SUCCESS"
    Write-Host "APK signed with required fingerprint: $apkFingerprint"
    Write-Host "APK path: $apkPath"
}
finally {
    if (Test-Path $backupPath) {
        Move-Item -Path $backupPath -Destination $keyPropsPath -Force
    }
}
