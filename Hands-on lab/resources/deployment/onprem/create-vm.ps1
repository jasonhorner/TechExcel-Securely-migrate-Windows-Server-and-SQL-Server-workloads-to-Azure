<# 
Microsoft Cloud Workshop: BCDR
.File Name
 - create-vm.ps1

.What does this script do?  
 - Creates an Internal Switch in Hyper-V called "Nat Switch"
    
 - Downloads an Image of an Ubuntu Linux 16.04 Server to the local drive

 - Add a new IP address to the Internal Network for Hyper-V attached to the NAT Switch

 # - Creates a NAT Network on 192.168.0.0/24

 - Creates the Virtual Machine in Hyper-V

 - Issues a Start Command for the new "OnPremVM"
#>

Configuration Main
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration', 'xHyper-V'

	node "localhost"
  	{
		# Ensures a VM with default settings
        xVMSwitch InternalSwitch
        {
            Ensure         = 'Present'
            Name           = 'Nat Switch'
            Type           = 'Internal'
        }
		
		Script ConfigureHyperV
    	{
			GetScript = 
			{
				@{Result = "ConfigureHyperV"}
			}	
		
			TestScript = 
			{
           		return $false
        	}	
		
			SetScript =
			{
                mkdir "C:\git"
                cd "C:\git"

                git lfs install --skip-smudge
                git clone --quiet --single-branch "https://github.com/microsoft/TechExcel-Securely-migrate-Windows-Server-and-SQL-Server-workloads-to-Azure.git"
                cd "C:\git\TechExcel-Securely-migrate-Windows-Server-and-SQL-Server-workloads-to-Azure\"
                git lfs pull
                git lfs install --force

                $downloadedFile = "C:\git\TechExcel-Securely-migrate-Windows-Server-and-SQL-Server-workloads-to-Azure\Hands-on lab\resources\deployment\onprem\OnPremWinServerVM.zip"
                $vmFolder = "C:\VM"

                Add-Type -assembly "system.io.compression.filesystem"
                [io.compression.zipfile]::ExtractToDirectory($downloadedFile, $vmFolder)
                # The following command was used to Zip up the VM files originally
                # [io.compression.zipfile]::CreateFromDirectory("C:\OnPremWinServerVM", "C:\OnPremWinServerVM.zip")

                $NatSwitch = Get-NetAdapter -Name "vEthernet (NAT Switch)"
                New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $NatSwitch.ifIndex

                New-NetNat -Name NestedVMNATnetwork -InternalIPInterfaceAddressPrefix 192.168.0.0/24 -Verbose

                New-VM -Name OnPremVM `
                        -MemoryStartupBytes 4GB `
                        -BootDevice VHD `
                        -VHDPath 'C:\VM\WinServer\Virtual Hard Disks\WinServer.vhdx' `
                        -Path 'C:\VM\WinServer\Virtual Hard Disks' `
                        -Generation 1 `
                        -Switch "NAT Switch"

                Start-VM -Name OnPremVM
			}
		}	
  	}
}
