param(
  [Parameter(Mandatory = $true)]
  [string]$Token,
  [string]$Base = 'http://192.168.1.4:7001'
)

$ErrorActionPreference = 'Stop'

$headers = @{
  'Authorization' = "Bearer $token"
  'Content-Type' = 'application/json'
  'Accept' = 'application/json'
}

function Call-Api {
  param(
    [string]$Method,
    [string]$Path,
    $Body = $null
  )

  $uri = "$base$Path"
  if ($null -ne $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body ($Body | ConvertTo-Json -Depth 8)
  }
  return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
}

function Print-State([string]$label) {
  $state = Call-Api -Method GET -Path '/api/cams/spaces/state'
  $queue = Call-Api -Method GET -Path '/api/cams/spaces/queue'
  $d = $state.data
  $items = @($queue.data)
  Write-Output "`n=== $label ==="
  Write-Output "currentQueueItemId=$($d.currentQueueItemId)"
  Write-Output "currentTrackName=$($d.currentTrackName)"
  Write-Output "hlsUrl=$($d.hlsUrl)"
  Write-Output "isPaused=$($d.isPaused)"
  Write-Output "queueCount=$($items.Count)"
  foreach ($i in $items) {
    Write-Output (" - pos={0} status={1} track={2}" -f $i.position, $i.queueStatus, $i.trackName)
  }
}

# fetch one stream-ready track and one playlist
$tracksResp = Call-Api -Method GET -Path '/api/tracks?pageNumber=1&pageSize=50'
$allTracks = @(
  if ($tracksResp.items) { $tracksResp.items } else { $tracksResp.data.items }
)
$trackReady = $allTracks | Where-Object { $_.hlsUrl -and $_.status -eq 1 } | Select-Object -First 1
if (-not $trackReady) { throw 'No stream-ready track found' }

$playlistsResp = Call-Api -Method GET -Path '/api/playlists?pageNumber=1&pageSize=20'
$playlists = @(
  if ($playlistsResp.items) { $playlistsResp.items } else { $playlistsResp.data.items }
)
$playlist = $playlists | Select-Object -First 1
if (-not $playlist) { throw 'No playlist found' }

Write-Output "Using track: $($trackReady.id) - $($trackReady.title)"
Write-Output "Using playlist: $($playlist.id) - $($playlist.name)"

# start clean
Call-Api -Method DELETE -Path '/api/cams/spaces/queue/all' | Out-Null
Start-Sleep -Milliseconds 500
Print-State 'After clear all'

# TRACK AddToQueue mode=3
Call-Api -Method POST -Path '/api/cams/spaces/queue/tracks' -Body @{
  trackIds = @($trackReady.id)
  mode = 3
  reason = 'API smoke test track add-to-queue'
} | Out-Null
Start-Sleep -Milliseconds 500
Print-State 'Track mode=3 AddToQueue'

# TRACK PlayNext mode=2
Call-Api -Method POST -Path '/api/cams/spaces/queue/tracks' -Body @{
  trackIds = @($trackReady.id)
  mode = 2
  reason = 'API smoke test track play-next'
} | Out-Null
Start-Sleep -Milliseconds 500
Print-State 'Track mode=2 PlayNext'

# TRACK PlayNow mode=1 clear queue
Call-Api -Method POST -Path '/api/cams/spaces/queue/tracks' -Body @{
  trackIds = @($trackReady.id)
  mode = 1
  isClearExistingQueue = $true
  reason = 'API smoke test track play-now'
} | Out-Null
Start-Sleep -Milliseconds 700
Print-State 'Track mode=1 PlayNow clear=true'

# reset queue
Call-Api -Method DELETE -Path '/api/cams/spaces/queue/all' | Out-Null
Start-Sleep -Milliseconds 500
Print-State 'After clear before playlist tests'

# PLAYLIST AddToQueue mode=3
Call-Api -Method POST -Path '/api/cams/spaces/queue/playlist' -Body @{
  playlistId = $playlist.id
  mode = 3
  reason = 'API smoke test playlist add-to-queue'
} | Out-Null
Start-Sleep -Milliseconds 700
Print-State 'Playlist mode=3 AddToQueue'

# PLAYLIST PlayNext mode=2
Call-Api -Method POST -Path '/api/cams/spaces/queue/playlist' -Body @{
  playlistId = $playlist.id
  mode = 2
  reason = 'API smoke test playlist play-next'
} | Out-Null
Start-Sleep -Milliseconds 700
Print-State 'Playlist mode=2 PlayNext'

# PLAYLIST PlayNow mode=1 clear queue
Call-Api -Method POST -Path '/api/cams/spaces/queue/playlist' -Body @{
  playlistId = $playlist.id
  mode = 1
  isClearExistingQueue = $true
  reason = 'API smoke test playlist play-now'
} | Out-Null
Start-Sleep -Milliseconds 900
Print-State 'Playlist mode=1 PlayNow clear=true'
