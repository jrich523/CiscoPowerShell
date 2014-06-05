function Convertfrom-length
{
param(
[parameter(valuefrompipeline=$true)]
$data
)

    #if single string turn to array
    if($data -is [array]){$data = $data -split "\n"}

    # strip any blank lines or line splitters
    $data = $data | ? {$_ -notmatch "^[\s\-\+\=]*$"}

    #pull header, assume first time, without spaces
    $header = $data[0] -split "(\S+\s+)" | ?{$_}

    #build regex patern
    $Pat = (($header | select -SkipLast 1 | %{"(?<$($_.trim())>.{$($_.length)})"})-join "")
    $pat += "(?<$(($header |select -last 1).trim())>.+)"
    #process/convert data
    $data | select -skip 1 | ? { $_ -match $Pat} | %{ [pscustomobject]$Matches } | select * -ExcludeProperty 0
}