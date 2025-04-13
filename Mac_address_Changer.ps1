# Requires Administrator
# Save this as Change-MAC.ps1

param (
    [string]$InterfaceName = $(Read-Host "Enter the name of the network adapter"),
    [string]$NewMAC = $(Read-Host "Enter the new MAC address (e.g., 001122334455)")
)

function Get-NICRegistryKey {
    param([string]$Name)

    $adapters = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" `
        | Where-Object { $_.DriverDesc -eq $Name }

    return $adapters.PSPath
}

function Change-MACAddress {
    param (
        [string]$Name,
        [string]$MAC
    )

    $key = Get-NICRegistryKey -Name $Name

    if (-not $key) {
        Write-Host "Adapter not found in registry!" -ForegroundColor Red
        return
    }

    Set-ItemProperty -Path $key -Name "NetworkAddress" -Value $MAC
    Write-Host "MAC address changed in registry." -ForegroundColor Green

    Write-Host "Restarting network adapter..."
    Disable-NetAdapter -Name $Name -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $Name -Confirm:$false
    Write-Host "Adapter restarted. New MAC should now be active."
}

# Check format
if ($NewMAC.Length -ne 12 -or $NewMAC -notmatch '^[0-9A-Fa-f]{12}$') {
    Write-Host "Invalid MAC format. Use 12 hex digits with no separators." -ForegroundColor Red
    exit
}

Change-MACAddress -Name $InterfaceName -MAC $NewMAC
