
<#$inputdir = $args[0]
$outputfile = $args[1]
$prefix = $args[2]#>

param(
    [string]$inputdir = "..\bitmaps",
    [string]$outputfile = "..\src\bitmaps.asm",
    [string]$prefix = "bm_"
)

$files = Get-ChildItem $inputdir
New-Item $outputfile -type file -force

foreach ($file in $files){
    Add-Content $outputfile "$prefix$($file.BaseName):"
    $out = python "$PSScriptRoot\bitmap2lm.py" $($file.fullName) '.dw 0b%b'
    Add-Content $outputfile $out   
}