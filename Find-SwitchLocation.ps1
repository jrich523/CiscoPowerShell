$script:switches=@()

Function  Find-SwitchLocation{
    param($ip, $SwitchIP, $password)
    #test for plink
$cmd = @"
$password
term len 0
show arp
exit

"@

$arp = $cmd | plink $SwitchIP -telnet -batch

if($arp -match $ip){
    $mac = (($arp -match $ip) -split "\s+")[3]
    }
else {Write-host "IP not found on switch!"
break;}


$cmd = @"
$password
term len 0
show mac-address-table
exit

"@
$mat = $cmd | plink $SwitchIP -telnet -batch
$entry = ($mat -match $mac).trim()

#$spacing = ($mat -match "\+")[0]
#$last=0
#$lengths=$spacing.split("+")
$entry.substring($entry.LastIndexOf(" ")+1)
}

Function  Get-MacAddressTable{
    param($SwitchIP, $password)
    #test for plink


$cmd = @"
$password
term len 0
show mac-address-table
exit

"@
$mat = $cmd | plink $SwitchIP -telnet -batch
$groups = $mat -join "`n" -split "`n`n"
$uniTable =Convertfrom-CiscoData ($groups[2] -split "`n" | select -skip 6) | %{$_ | Add-Member -MemberType NoteProperty -Name CastType -Value "Unicast" -PassThru}
$multiTable = Convertfrom-CiscoData ($groups[3] -split "`n" | select -skip 1) | %{$_ | Add-Member -MemberType NoteProperty -Name CastType -Value "Unicast" -PassThru}

$uniTable + $multiTable

}
Function Get-ArpTable{
    param($SwitchIP, $password)

$cmd = @"
$password
term len 0
show arp
exit

"@

$arp = $cmd | plink $SwitchIP -telnet -batch
$data = $arp[9..($arp.count - 3)]
ConvertFrom-FixedField $data @(10,17,11,16,7)
}
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
        $ri++
    }
}
$results
}
function ConvertFrom-FixedField{
param($data,$fieldsize)
$pat = (($fieldsize | %{"(.{$_})"}) -join "") + "(.+)"
$data[0] -match $pat | out-null
$headers = $Matches
$headers.Remove(0)
$results=@()
$ri=0

foreach($row in ($data[1..$data.Count]))
{
    $row -match $pat | Out-Null
    $rtn = $matches
    $obj = @{}
    foreach($key in $headers.keys)
    {
        $obj.($headers.$key.trim()) = $rtn.$key.trim()
    }
    if(!$obj.($headers.1)) ## no primary key, add to last record (assume header 0 is pk)
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
        $ri++
    }
    
}

}

function Add-Switch
{
param($name,$ip,$password,[switch]$default,[switch]$ssh)
$script:switches += New-Object psobject -Property @{
name=$name
ip=$ip
password=$password
}
}