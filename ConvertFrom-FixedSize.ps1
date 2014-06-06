
function ConvertFrom-FixedSize
{
[cmdletbinding()]
param(
[Parameter(Mandatory=$true,
           ValueFromPipeline=$true)]
$data)


    function getIndexes{
    param($str)
        $str.ToCharArray() | %{$last = " ";$i=0}{if($last -eq " " -and $_ -ne " "){$i};$i++;$last =$_}
    }

    function chopData{
    param($str,$indexes)
        $current = $indexes[0]
        $indexes | select -skip 1 | %{ $str.substring($current,($_ - $current)).trim();$current = $_}
        $str.substring($current).trim()
    }

    $data = if($data -isnot [array]){$data -split "`n"|%{$_.trimend()}}

    #remove empty lines
    $data = $data |?{$_.trimend()}

    #header is --- based, not sure i need to check but we'll see
    if($data[0] -match '^\-+$')
    {
        $headerIndex = getIndexes $data[1]
        #one line header?
        if($data[2] -match '^\-+$')
        {
            $header = $data[1]
            $rawdata = $data | select -skip 3
        }
        #two line header
        elseif($data[3] -match '^\-+$')
        {
            $header = $data[1..2]
            #cant join header until we know the right indexes
            $rawdata = $data | select -skip 4
        }
        else
        {
            throw "cant parse header"
        }
    
        $fielddata = $rawdata | %{
                [pscustomobject]@{
                        Row = $_
                        Indexes = getIndexes $_
                        }
                    }
        #find indexes
        #maybe select only the first few rows to prevent excessive cpu usage
        $fielddata | %{$indexes = $headerIndex} { $indexes = $_.indexes |? {$_ -in $indexes}}

        #process headers
        $headerCount = $indexes.Length
        $headerSections = @()

        $headerSections = $header | %{,(chopdata $_ $indexes)}

        if($header -is [array])
        {
            $header = 0..($headerSections[0].count - 1) | %{$i=$_;(($headerSections | %{$_[$i]}) -join " ").trim();$i++}
        }
        else
        {
            $header = $headerSections | %{$_.trim()}
        }

        foreach($field in $fielddata)
        {
            $fdata = chopData $field.row $indexes
            [pscustomobject](0..($headerCount - 1) |%{ $h=@{} }{$h.($header[$_]) = $fdata[$_]}{$h})

        }
    }
}