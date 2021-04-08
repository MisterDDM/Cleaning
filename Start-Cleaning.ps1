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

		$SystemDrive = (Get-CimInstance Win32_OperatingSystem).SystemDrive

		$AppDataPath = @(
			'AppData\Local\Microsoft\Windows\Temporary Internet Files'
			'AppData\Local\Microsoft\Windows\WebCache'
			'AppData\Local\Microsoft\Windows\WER'
			'AppData\Local\Microsoft\Internet Explorer\Recovery'
			'AppData\Local\Microsoft\Terminal Server Client\Cache'
			'AppData\Local\KVS\Enterprise Vault'
			'AppData\Local\CrashDumps'
			'AppData\Local\Temp'
			'AppData\LocalLow\Sun\Java\Deployment\cache\6.0'
			'AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console'
		)

		Write-Verbose "Windows Version = $($WindowsProduct.CurrentVersion)"
		Write-Verbose "ComputerName = $env:COMPUTERNAME"
		Write-Verbose "UserName = $env:USERNAME"
		Write-Verbose '.'
	}

	Process
	{
		$Before = [System.Math]::Round(((Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$SystemDrive'").FreeSpace /1GB),2)

		Write-Verbose "Current free diskspace = $Before GB"        
		Write-Verbose "Starting disk cleanup"
		Write-Verbose '.'

		Start-Process cleanmgr.exe -ArgumentList '/sagerun:1' -Wait

		Write-Verbose "Analysing WinSxS Folder"

		$AnalyseWinSxS = dism /Online /Cleanup-Image /AnalyzeComponentStore

		if ($AnalyseWinSxS.Where({ $_ -like 'Component Store Cleanup Recommended*' }).EndsWith('Yes'))
		{
			Write-Verbose "Cleaning WinSxS Folder"
			Start-Process dism.exe -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup' -Wait
		}
		else
		{
			Write-Verbose "No need to clean the WinSxS folder"
		}
		Write-Verbose '.'       
		Write-Verbose "Collecting all Temp Files and Folders"

		$TempLocalData = Get-ChildItem $env:TEMP -Force
		$TempWindows = Get-ChildItem "$env:windir\temp" -Force
		
		$UsersPath = Join-Path $SystemDrive 'Users' -Resolve
		$Users = Get-ChildItem $UsersPath
		
		$UsersTempFolders = $Users | ForEach-Object { 
			$CurrentUser = $_.FullName 
			$AppDataPath | ForEach-Object {  
				if ( $FullName = Join-Path $CurrentUser $_ -Resolve -ErrorAction SilentlyContinue )
				{
					Get-ChildItem $FullName
				}
			} 
		}        

		Write-Verbose "Removing all Temp Files and Folders"

		$AllTempFiles = $TempLocalData,$UsersTempFolders,$TempWindows
		$ItemsCount = ($AllTempFiles.FullName | Select-Object -Unique).Count

		$AllTempFiles.FullName[0..$AllTempFiles.FullName.Count] | Select-Object -Unique | foreach {
			$Path = $_
			if ( Test-Path $Path )
			{
				if ( $PSBoundParameters['verbose'] )
				{
					Write-Verbose "$Path"
				}
				Remove-Item $Path -Force -Recurse -ErrorAction SilentlyContinue
			}
		}
		Write-Verbose '.'
		$After = [System.Math]::Round(((Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$SystemDrive'").FreeSpace /1GB),2)

		$MediaType = Get-Disk -Number 0 | Get-PhysicalDisk

		if( $PSBoundParameters['verbose'] ) 
		{        
			Write-Verbose "$ItemsCount files have been removed"
			Write-Verbose "Disk information:"
			Write-Verbose $($MediaType.Model)
			Write-Verbose $($MediaType.MediaType)
			Write-Verbose $($MediaType.HealthStatus)
			Write-Verbose "Diskspace after cleaning $After"
			Write-Verbose '.'
			Write-Verbose "Now starting Disk Defragmentation on System Disk"
		}
		else 
		{
			Write-Output "$ItemsCount files have been removed"
			Write-Output "Diskspace after cleaning $After"
			Write-Output "Now starting Disk Defragmentation on System Disk"
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
