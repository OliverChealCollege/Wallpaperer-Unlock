param(
    [string]$Source = "",
    [string]$RainmeterExe = ""
)

# Copies a chosen image into the Backgrounds history folder, makes it the current
# background, and tells Rainmeter to reload. Errors are written to browse.log.

$res    = $PSScriptRoot
$bgDir  = Join-Path $res "Backgrounds"
$state  = Join-Path $res "State.inc"
$log    = Join-Path $res "browse.log"
$exts   = @(".jpg", ".jpeg", ".png", ".bmp", ".gif")

function Log($m) { "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m | Add-Content -LiteralPath $log }
Log "started"

try {
    New-Item -ItemType Directory -Force -Path $bgDir | Out-Null

    # Find Rainmeter.exe: argument, then the usual portable layout, then the running process
    if (-not $RainmeterExe -or -not (Test-Path -LiteralPath $RainmeterExe)) {
        $guess = [System.IO.Path]::GetFullPath((Join-Path $res "..\..\..\Rainmeter.exe"))
        if (Test-Path -LiteralPath $guess) {
            $RainmeterExe = $guess
        } else {
            $p = Get-Process Rainmeter -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($p) { $RainmeterExe = $p.Path }
        }
    }
    if (-not $RainmeterExe) { throw "Could not find Rainmeter.exe" }

    # Ask for a file if none was passed in (drag-and-drop onto SetBackground.bat passes one)
    if (-not $Source) {
        Add-Type -AssemblyName System.Windows.Forms
        $owner = New-Object System.Windows.Forms.Form
        $owner.TopMost = $true
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title  = "Choose a background image"
        $dlg.Filter = "Images (*.jpg;*.jpeg;*.png;*.bmp;*.gif)|*.jpg;*.jpeg;*.png;*.bmp;*.gif"
        if ($dlg.ShowDialog($owner) -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
        $Source = $dlg.FileName
    }

    $srcFull = (Resolve-Path -LiteralPath $Source).Path
    $ext = [System.IO.Path]::GetExtension($srcFull).ToLower()
    if ($exts -notcontains $ext) { throw "Not a supported image type: $ext (use jpg, png, bmp or gif)" }

    $bgFull = (Resolve-Path -LiteralPath $bgDir).Path
    if ((Split-Path $srcFull -Parent) -ieq $bgFull) {
        $dest = $srcFull
    } else {
        $dest = Join-Path $bgFull (Split-Path $srcFull -Leaf)
        if (Test-Path -LiteralPath $dest) {
            $sameSize = (Get-Item -LiteralPath $dest).Length -eq (Get-Item -LiteralPath $srcFull).Length
            if (-not $sameSize) {
                $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $base  = [System.IO.Path]::GetFileNameWithoutExtension($srcFull)
                $dest  = Join-Path $bgFull ("{0}-{1}{2}" -f $base, $stamp, $ext)
            }
        }
        if (-not (Test-Path -LiteralPath $dest)) {
            Copy-Item -LiteralPath $srcFull -Destination $dest
        }
    }

    # Save it for next time, apply it right now, then reload the picker so the history updates
    & $RainmeterExe '!WriteKeyValue' 'Variables' 'Current' $dest $state
    & $RainmeterExe '!SetOption' 'MeterBackground' 'ImageName' $dest 'OrganizationWallpaper'
    & $RainmeterExe '!UpdateMeter' 'MeterBackground' 'OrganizationWallpaper'
    & $RainmeterExe '!Redraw' 'OrganizationWallpaper'
    & $RainmeterExe '!Refresh' 'OrganizationWallpaper\Picker'
    Log "done: $dest"
}
catch {
    Log ("ERROR: " + $_.Exception.Message)
}