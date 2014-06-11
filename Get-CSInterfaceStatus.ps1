<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-CSInterfaceStatus
{
    [CmdletBinding()]
    Param()
    #TODO: inject type info and format file
    #TODO: split port when format is */*

    # make sure each line is only seperated by a \n, so remove any \r
    # if data is paged, seperate on the blank lines. might not be called for here but shouldnt hurt anything
    ((Invoke-CSCMD -Cmd "show int status") -replace "\r","") -split "\n\n" | ConvertFrom-FixedSize2
}