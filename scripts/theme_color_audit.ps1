param(
  [string]$Root = "."
)

$patterns = @(
  "Color\(0x",
  "Colors\.(white|black|grey|red|blue|orange|green)",
  "#[0-9A-Fa-f]{6}"
)

$include = @("*.dart", "*.svg", "*.json", "*.yaml")
$paths = @("lib", "assets", "web", "pubspec.yaml")
$results = @()

foreach ($path in $paths) {
  $fullPath = Join-Path $Root $path
  if (-not (Test-Path $fullPath)) {
    continue
  }

  $files = if ((Get-Item $fullPath).PSIsContainer) {
    Get-ChildItem $fullPath -Recurse -File -Include $include
  } else {
    Get-Item $fullPath
  }

  foreach ($file in $files) {
    $matches = Select-String -Path $file.FullName -Pattern $patterns
    if ($matches) {
      $results += [PSCustomObject]@{
        Count = $matches.Count
        File = Resolve-Path -Path $file.FullName -Relative
      }
    }
  }
}

$results | Sort-Object Count -Descending | Format-Table -AutoSize
