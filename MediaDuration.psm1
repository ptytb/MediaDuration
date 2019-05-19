
Function Get-MediaDuration {
  [CmdletBinding()]      
  param(
    [string[]] $Path,
    [string] $Filter,
    [switch] $Recurse,
    [switch] $Total,
    [switch] $Progress,
    [Parameter(ValueFromPipeline=$true)] [Object[]] $items
    ) 
  begin {
    $ffprobe = Get-Command -CommandType Application -Name 'ffprobe.exe' -ErrorAction SilentlyContinue
    if (-not $ffprobe) {
      Write-Warning "ffprobe.exe not found in PATH, grab it there: https://ffbinaries.com/downloads"
      return
    }
    $ffprobe = $ffprobe.Source
    $args = @{Recurse=$Recurse; Filter=$Filter; Path=$Path}
    if (-not $items) {
      $items = Get-ChildItem @args 
    }
    if ($Total) {
      $totalTime = [TimeSpan]::FromSeconds(0)
      $Progress = $true
    }
    if ($Progress) {
      $totalCount = $items.Count
      $i = 0
    }
  }
  process {
    $items `
    | ForEach-Object {
      & $ffprobe -v quiet -print_format json -show_format -show_streams -i $_.FullName 2>&1 `
      | ConvertFrom-Json 
    } `
    | Select-Object `
      @{Name='FullName';Expression={ $_.format.filename }},
      @{Name='BitRate';Expression={ $_.format.bit_rate }},
      @{Name='Duration';Expression={ [TimeSpan]::FromSeconds($_.format.duration -replace ('(\.\d{0,3})\d+','$1')) } } `
    | Where-Object { $_.Duration -gt [TimeSpan]::Zero } `
    | ForEach-Object {
      if ($Progress) {
        ++$i
        $percent = ($i / $totalCount * 100)
        $percentPretty = [math]::Round($percent, 1)
        Write-Progress -Activity "Calculating duration" -Status "Progress: ${i} of ${totalCount} $percentPretty%" -PercentComplete $percent
        if ($i -eq $totalCount) {
          $totalCount += 1  # when pipelining, process{} block is invoked per directory; counting won't work properly for recursive directories
        }
      }
      if ($Total) {
        $totalTime = $totalTime + $_.Duration 
        $_ = $null  # prevent writing item to terminal when aggregating
      }
      $_  # return item to pipeline
    }
  }
  end { 
    if ($Total) {
      $totalTime.ToString()
    }
  }

<#
.SYNOPSIS

Query duration time and other properties from video or audio files using ffprobe command.

.DESCRIPTION

You can generate the item list with Get-ChildItem command and pipe it into
Get-MediaDuration cmdlet. The resulting output is a list of objects and
can be pipelined as well into Sort-Object, Where-Object, Measure-Object, etc.
Mind that Measure-Object requires an integer as an input property, so you'll
have to convert the Duration field of type TimeSpan, to milliseconds
(see examples section).

.PARAMETER Progress
Show progress bar while calculating. Defaults to $true when the Total
parameter is $true.

.INPUTS

None or list of items from Get-ChildItem.

.OUTPUTS 

Object[]. Returns the list of objects, use the Duration property to get the
time of media. When using -Total parameter, outputs System.String for convinience.

.EXAMPLE

Get-MediaDuration -Recurse -Total

.EXAMPLE

Get-MediaDuration -Recurse -Total -Path "Podcasts"

.EXAMPLE

Get-MediaDuration -Recurse -Total '.\Audiobook A','.\Audiobook B' '*.m4a'

.EXAMPLE

Get-MediaDuration -Recurse "Movies" '*.*' 

.EXAMPLE

Get-MediaDuration -Recurse "Movies" '*.mp4' -Total

.EXAMPLE

Get-MediaDuration -Recurse "Movies" '*.mp4' | ForEach-Object {  $_.Duration = $_.Duration.TotalMilliseconds ; $_ }

.EXAMPLE

Get-MediaDuration -Recurse `
  | ForEach-Object { $_.Duration = $_.Duration.TotalMilliseconds ; $_ } `
  | Measure-Object -Sum Duration `
  | % { [TimeSpan]::FromMilliseconds($_.Sum).ToString() }

.EXAMPLE

Get-ChildItem -Recurse | Get-MediaDuration

.EXAMPLE

Get-ChildItem -Recurse | Get-MediaDuration -Total

.EXAMPLE

Get-ChildItem -Recurse "Movies" | Get-MediaDuration | Sort Duration -Descending 

.LINK

https://superuser.com/questions/650291/how-to-get-video-duration-in-seconds

#>
}


