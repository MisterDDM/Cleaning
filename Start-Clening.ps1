#Requires -RunAsAdministrator

Function Start-Cleaning 
{
    [CmdletBinding()]
    param()
    
    Begin 
    {
        if( $PSBoundParameters['verbose'] ) 
        {
            $VerbosePreference = "Continue"
            Write-Verbose "Verbose mode is on"
        }
        else
        {
            $VerbosePreference = "SilentlyContinue"
            Write-Output 'Running silently ... '
        }

        $WindowsProduct = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        
        Write-Verbose "Windows Version = $($WindowsProduct.CurrentVersion)"
        Write-Verbose "ComputerName is $env:COMPUTERNAME"
        Write-Verbose "UserName is $env:USERNAME"
        "`n"
    }

    Process
    {
        Write-Verbose "Starting disk cleanup"

        Start-Process cleanmgr.exe -ArgumentList '/sagerun:1' -Wait
        
        Write-Verbose "Collecting all temp items"
        
        $TempLocalData = Get-ChildItem $env:TEMP -Force
        $TempWindows = Get-ChildItem "$env:windir\temp" -Force

        Write-Verbose "Removing all temp items."

        $AllTempFiles = $TempLocalData,$TempWindows
        $ItemsCount = $AllTempFiles.FullName.Count

        $AllTempFiles.FullName[0..$AllTempFiles.FullName.Count] | foreach {

            if ( $PSBoundParameters['verbose'] )
            {
                Write-Verbose "$_"
            }
            else
            {
                Write-Output "$_"
            }
            
            Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue
        }

        $MediaType = Get-Disk -Number 0 | Get-PhysicalDisk

        if( $PSBoundParameters['verbose'] ) 
        {        
            Write-Verbose "$ItemsCount files have been removed"
            "`n"
            Write-Verbose "Now starting Disk Defragmentation on System Disk"
            Write-Verbose "Disk information:"
            Write-Verbose "`t$($MediaType.Model)"
            Write-Verbose "`t$($MediaType.MediaType)"
            Write-Verbose "`t$($MediaType.HealthStatus)"
        }
        else 
        {
            Write-Output "$ItemsCount files have been removed"
            "`n"
            Write-Output "Now starting Disk Defragmentation on System Disk"
            Write-Output "Disk information:"
            Write-Output "`t$($MediaType.Model)"
            Write-Output "`t$($MediaType.MediaType)"
            Write-Output "`t$($MediaType.HealthStatus)"
        }

        if ( $MediaType.HealthStatus -like 'Healthy' )
        {
            $Argument = '/A /G /U /V'
            Start-Process Defrag.exe -ArgumentList "C: $Argument" -Wait
        }
        else
        {
            Write-Warning "System in bad condition and will not defrag. Program ends here."
        }

    }

    end 
    {
        Get-Variable * | foreach { Remove-Variable $_ -Force -ErrorAction SilentlyContinue }
        
        if( $PSBoundParameters['verbose'] ) 
        {        
            Write-Verbose "Work done"
        }
        else 
        {
            Write-Output "Work done"
        }
    }
}

Start-Cleaning -Verbose
"`n"
Read-Host "Press ENTER to continue ..."
