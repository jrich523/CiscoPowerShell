function ConvertFrom-FixedSize2
{
    [cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true)]
    $data
)

    function spaceIndex {
    param($row)
        $row.ToCharArray() | %{$i=0}{if(" " -eq $_){$i};$i++}
    }

    function chopData{
        param($str,$indexes)
            $current = $indexes[0]
            $indexes | select -skip 1 | %{
                #write-host "current: $current / pipe $_"
                $str.substring($current,($_ - $current)).trim();
                $current = $_
            
            }
            #write-host "current $current"
            $str.substring($current).trim()
        }


    #split data if needed
    $data = if($data -isnot [array]){$data -split "`n"|%{$_.trimend()}}

    #grab rows and space locations
    $rowdata = $data | %{[pscustomobject]@{data=$_;Indexes=(SpaceIndex $_)}}

    #starting row indexes
    $initIndex = $rowdata[0].Indexes

    #find spaces that are in all sets
    $rowdata | %{$initIndex= Compare-Object $initIndex $_.indexes -IncludeEqual -ExcludeDifferent -PassThru}

    #clean up those indexes by removing consecutive numbers
    $idx = $initIndex | %{$i=0}{if($i -eq ($_ -1)){$i=$_}else{$i;$i=$_}}{$i}

    #under the assumption that the first row is header, use those for property names
    $header = chopData $rowdata[0].data $idx

    #chop up data and spit out objects
    $rowdata | Select -skip 1 | %{ chopData $_.data $idx | %{$i=0;$h=@{}}{ $h.($header[$i]) = $_;$i++}{[pscustomobject]$h}}

}
