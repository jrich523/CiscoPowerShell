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

    Invoke-cscmd -Cmd "show int status" | ConvertFrom-FixedSize
}