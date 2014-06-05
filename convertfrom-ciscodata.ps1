function Convertfrom-CiscoData{
param($data)
$header = $data[0] +(" "*100) ##buffer end for splitting
$spacing = $data[1].split('+')
$rows = $data[2..($data.Count-1)]
$results =@()
$ri = 0 #result index

##split headers
$headers=@()
$last = 0
foreach($field in $spacing)
{
    $headers+=$header.Substring($last,$field.Length).trim()
    $last+=$field.Length
}


##process rows

foreach($row in $rows)
{
    #break in to hash
    $start = 0
    $obj = @{}
    for($idx=0;$idx -lt $spacing.count;$idx++)
    {
        $row = $row + (" "*100)
        $end = $spacing[$idx].length + 1
        $obj.($headers[$idx])=$row.Substring($start,$end).trim()
        $start +=$end
    }
    ## process row
    if(!$obj.($headers[0])) ## no primary key, add to last record (assume header 0 is pk)
    {
        foreach($key in $obj.keys)
        {
            if($obj.$key)
            {
                $results[$ri -1].$key = $results[$ri - 1].$key + "," +$obj.$key
            }
        }
      
    }
    else ##pk exists, add to list
    {
        $results += New-Object psobject -Property $obj
        $si++
    }
}
$results
}