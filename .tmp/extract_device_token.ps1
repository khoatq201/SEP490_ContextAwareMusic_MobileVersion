param(
  [string]$PackageName = 'com.example.cams_store_manager',
  [string]$TempDir = '.tmp'
)

$ErrorActionPreference = 'Stop'

$hivePath = Join-Path $TempDir 'auth_box.hive'

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

cmd /c "adb exec-out run-as $PackageName cat app_flutter/auth_box.hive > `"$hivePath`""

$dump = dart run .tmp/read_hive.dart $TempDir auth_box
$line = ($dump | Select-String 'deviceAccessToken:').Line

if ([string]::IsNullOrWhiteSpace($line)) {
  throw 'Cannot find deviceAccessToken in local device session dump.'
}

$accessMatch = [regex]::Match($line, 'deviceAccessToken:\s*([^,}]+)')
if (-not $accessMatch.Success) {
  throw 'Failed to parse deviceAccessToken.'
}

$refreshMatch = [regex]::Match($line, 'deviceRefreshToken:\s*([^,}]+)')
$spaceMatch = [regex]::Match($line, 'spaceId:\s*([^,}]+)')
$storeMatch = [regex]::Match($line, 'storeId:\s*([^,}]+)')
$brandMatch = [regex]::Match($line, 'brandId:\s*([^,}]+)')

Write-Output "deviceAccessToken:"
Write-Output ($accessMatch.Groups[1].Value.Trim())

if ($refreshMatch.Success) {
  Write-Output ''
  Write-Output "deviceRefreshToken:"
  Write-Output ($refreshMatch.Groups[1].Value.Trim())
}

if ($spaceMatch.Success -or $storeMatch.Success -or $brandMatch.Success) {
  Write-Output ''
  Write-Output 'sessionIds:'
  if ($brandMatch.Success) {
    Write-Output ("brandId={0}" -f $brandMatch.Groups[1].Value.Trim())
  }
  if ($storeMatch.Success) {
    Write-Output ("storeId={0}" -f $storeMatch.Groups[1].Value.Trim())
  }
  if ($spaceMatch.Success) {
    Write-Output ("spaceId={0}" -f $spaceMatch.Groups[1].Value.Trim())
  }
}
