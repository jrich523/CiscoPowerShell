function ConvertFrom-SecureToPlain {
    
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)
    
    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    
    # Get the plain text version of the password
    $private:PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    
    # Return the plain text password
    $private:PlainTextPassword
    
}

<#
.Synopsis
   Connects to a Cisco device
.DESCRIPTION
   Connects to a cisco device via SSH for execution of IOS commands.
.EXAMPLE
   should probably show an example, but its pretty straight forward.

#>
function Connect-CSUnit
{
    [CmdletBinding()]
    Param
    (
        # Name or IP of unit to connect to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $SystemName,

        # Username to login as.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName="string")]
        [string]
        $UserName="admin",

        #password to login
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2,
                   ParameterSetName="string")]
        [string]
        $Password,

        #ps credential object for login info
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName="cred")]
        [pscredential]
        $Credential,
        
        # Port to connect on, defaults to 22
        [int]
        $port = 22
    )

    if($Credential)
    {
        $UserName = $Credential.UserName
        $password = ConvertFrom-SecureToPlain $Credential.Password
    }
    if($Script:Connection)
    {
        #dont bother checking to see if its already connected, might need to reset
        Disconnect-CSUnit
    }    
    try
    {
        $Script:Connection = New-Object Renci.SshNet.SshClient($systemname, $Port, $Username, $Password)  
    }
    catch
    {
        Write-Error "Unable to create session to ${systemname}: $($_.exception.innerexception.message)" -ErrorAction Stop
    }
    try
    {
        $Script:Connection.Connect()
    }
    catch
    {
        Write-Error "Unable to open connection to ${systemname}: $($_.exception.innerexception.message)" -ErrorAction Stop
    }
}

<#
.Synopsis
   Closes connection to unit
.DESCRIPTION
   Closes the SSH connection to the Cisco device
.EXAMPLE
   Disconnect-CSUnit
#>
function Disconnect-CSUnit
{
    [CmdletBinding()]
    Param()
    if($Script:Connection)
    {
        if($Script:Connection.isconnected)
        {
            $script:connection.Disconnect()
        }
        $script:connection.dispose()
        $script:connection = $null
    }
}



## internal
Function Invoke-CSCMD
{
param($cmd)

if($Script:Connection)
    {
        if($Script:Connection.isconnected)
        {
            try
            {
                $rtn = $Script:Connection.RunCommand($cmd)
            }
            catch
            {
                Write-Error "Command failed! $_"
            }
            if($rtn.ExitStatus -eq 0)
            {
                $rtn.Result.TrimEnd()
            }
            else
            {
                Write-Error "Error executing command: $($rtn.error)"
            }
        }
        else
        {
            #TODO: maybe try to reconnect?
            Write-Error "Connection has closed, please re-establish the connection"
        }
    }
    else
    {
        Write-Error "No connection found. use Connect-CSUnit"
    }
}