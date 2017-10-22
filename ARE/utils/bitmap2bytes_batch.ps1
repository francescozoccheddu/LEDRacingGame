param(
    [string]$inputdir = "..\bitmaps",
    [string]$script = "$PSScriptRoot\bitmap2bytes.py"
)

$files = Get-ChildItem "$inputdir\*.png"

foreach ($file in $files){
    $out = python $script $($file.fullName) '0b%b,' 8
    $out = ".db $($out.TrimEnd(','))"
    $outfile = "$inputdir\$($file.BaseName).asm"
    New-Item $outfile -type file -force
    Set-Content $outfile $out
}
