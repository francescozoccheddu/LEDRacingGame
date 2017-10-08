
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
    $image  = New-Object -ComObject Wia.ImageFile
    $image.loadfile($file.FullName)
    if ($image.Height -gt 8) {
        $out = python "$PSScriptRoot\bitmap2lm.py" $($file.fullName) '.dw 0b%b ' 16
    }
    else {
        Add-Content $outputfile ".db " -NoNewline  
        $out = python "$PSScriptRoot\bitmap2lm.py" $($file.fullName) '0b%b,' 8
        $out = $out.TrimEnd(",")
    }
    Add-Content $outputfile $out
}