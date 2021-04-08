If ( -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
{
    # Launch elevated process
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    # Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File",('"{0}"' -f $PSScriptRoot) -Verb RunAs
    exit
}

# Call script with elevated prompt
& "$PSScriptRoot\Start-Cleaning.ps1"
