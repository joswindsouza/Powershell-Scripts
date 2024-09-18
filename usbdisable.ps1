# Script to configure USB restrictions with options
# Created by Joswin Dsouza

$authorName = "Joswin Dsouza"
$scriptMessage = "Executing script created by $authorName..."
Write-Host $scriptMessage -ForegroundColor Red
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Ensure the script is running with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator."
    exit
}



# Function to set registry values
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "DWORD"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

# Disable USB storage devices by setting Group Policy and Registry values
function Disable-USBStorage {
    Write-Output "Disabling USB storage devices..."

    # Group Policy Settings
    $gpoPath = "HKLM:\Software\Policies\Microsoft\Windows\RemovableStorageDevices"

    Set-RegistryValue -Path $gpoPath -Name "Deny_All" -Value 1
    Set-RegistryValue -Path $gpoPath -Name "Allow_Floppy" -Value 0
    Set-RegistryValue -Path $gpoPath -Name "Allow_CDROM" -Value 0
    Set-RegistryValue -Path $gpoPath -Name "Allow_Tape" -Value 0

    # Registry Settings
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name "Start" -Value 4
}

# Allow USB devices based on their hardware IDs
function Allow-USBDevices {
    param (
        [string[]]$deviceHardwareIds
    )
    Write-Output "Allowing USB devices with Hardware IDs: $deviceHardwareIds"

    $policyPath = "HKLM:\Software\Policies\Microsoft\Windows\DeviceInstall\Restrictions"

    Set-RegistryValue -Path $policyPath -Name "AllowHardwareIds" -Value $deviceHardwareIds -Type "MultiString"
}

# Function to process Option 1: Disable using HID registration
function Process-HIDRegistration {
    Write-Output "This option will disable all USB and removable storage devices while registering the keyboard and mouse through HID (Human Interface Device) protocol."
    Write-Output "Please ensure that your keyboard and mouse are connected before proceeding. Note: If you change your keyboard or mouse, they will not be detected."
    $confirmation = Read-Host "Press 'Y' to continue or 'N' to cancel"

    if ($confirmation -eq 'Y') {
        Disable-USBStorage

        # Get the hardware IDs of the USB keyboard and mouse
        $keyboardIds = (Get-WmiObject Win32_Keyboard).PNPDeviceID
        $mouseIds = (Get-WmiObject Win32_PointingDevice).PNPDeviceID

        # Combine the hardware IDs into an array
        $allowedDeviceIds = $keyboardIds + $mouseIds

        Allow-USBDevices -deviceHardwareIds $allowedDeviceIds

        Write-Output "HID registration complete. Please restart the computer for the changes to take effect."
    } else {
        Write-Output "Operation cancelled."
    }
}

# Function to process Option 2: Disable USB storage while allowing keyboard and mouse
function Process-DisableNormal {
    Write-Output "This option will disable all removable storage devices while allowing the keyboard and mouse to function normally."
    $confirmation = Read-Host "Press 'Y' to continue or 'N' to cancel"

    if ($confirmation -eq 'Y') {
        Disable-USBStorage

        Write-Output "Configuration complete. Please restart the computer for the changes to take effect."
    } else {
        Write-Output "Operation cancelled."
    }
}

# Main script execution
Write-Output "Please choose an option:"
Write-Output "1. Disable all USB and removable storage devices while registering the keyboard and mouse through HID protocol."
Write-Output "2. Disable all removable storage devices while allowing the keyboard and mouse to function normally."

$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    '1' {
        Process-HIDRegistration
    }
    '2' {
        Process-DisableNormal
    }
    default {
        Write-Output "Invalid choice. Please run the script again and select option 1 or 2."
    }
}
