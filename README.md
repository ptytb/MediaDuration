### Install
```PowerShell
Install-Module MediaDuration
Import-Module MediaDuration
```

### Usage

Dig `Get-Help Get-MediaDuration` for even more details.

```PowerShell

Get-MediaDuration -Recurse -Total


Get-MediaDuration -Recurse -Total -Path "Podcasts"


Get-MediaDuration -Recurse -Total '.\Audiobook A','.\Audiobook B' '*.m4a'


Get-MediaDuration -Recurse "Movies" '*.*'


Get-MediaDuration -Recurse "Movies" '*.mp4' -Total


Get-MediaDuration -Recurse "Movies" '*.mp4' | ForEach-Object {  $_.Duration = $_.Duration.TotalMilliseconds ; $_ }


Get-MediaDuration -Recurse `
  | ForEach-Object { $_.Duration = $_.Duration.TotalMilliseconds ; $_ } `
  | Measure-Object -Sum Duration `
  | % { [TimeSpan]::FromMilliseconds($_.Sum).ToString() }


Get-ChildItem -Recurse | Get-MediaDuration


Get-ChildItem -Recurse | Get-MediaDuration -Total


Get-ChildItem -Recurse "Movies" | Get-MediaDuration | Sort Duration -Descending
```
