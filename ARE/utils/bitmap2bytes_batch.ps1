param(
    [string]$inputdir = "..\bitmaps",
    [string]$outputfile = "..\bitmaps.asm",
    [string]$prefix = "ee_",
    [string]$script = "$PSScriptRoot\bitmap2bytes.py"
)

$files = Get-ChildItem $inputdir
New-Item $outputfile -type file -force

foreach ($file in $files){
    $image  = New-Object -ComObject Wia.ImageFile
    $image.loadfile($file.FullName)
    Add-Content $outputfile "$prefix$($file.BaseName): ; $($file.BaseName) $($image.Width)x$($image.Height)"
    Add-Content $outputfile ".db " -NoNewline  
    $out = python $script $($file.fullName) '0b%b,' 8
    $out = $out.TrimEnd(",")
    Add-Content $outputfile $out
    Add-Content $outputfile "$prefix$($file.BaseName)_end:"
}