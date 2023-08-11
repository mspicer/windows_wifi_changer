# Author: Mike Spicer (2023)
# Description: A tool that will automatically switch your network through the list of provided networks for testing WiFi connectivity. 

# List of wireless networks and their PSKs
$networks = @(
    @{ "SSID" = "EXAMPLESSID"; "PSK" = "ASECUREPSKONWIFI" },
    @{ "SSID" = "ANOTHEREXAMPLESSID"; "PSK" = "MORESECUREPSK" } 
    
)

foreach ($network in $networks) {
    # Network configuration template
    $configTemplate = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$($network.SSID)</name>
    <SSIDConfig>
        <SSID>
            <name>$($network.SSID)</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$($network.PSK)</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

    # Write the configuration to an XML file
    $configFile = "$($network.SSID).xml"
    $configTemplate | Out-File -FilePath $configFile

    # Add the wireless network profile
    netsh wlan add profile filename=$configFile user=all
    
    # Connect to the wireless network
    Write-Host "Connecting to $($network.SSID) with PSK $($network.PSK)..."
    netsh wlan connect name=$($network.SSID) ssid=$($network.SSID) interface="Wi-Fi"

    # Wait for a few seconds to make sure the connection is established
    Start-Sleep -Seconds 5

    # Run ipconfig
    Write-Host "Running ipconfig for $($network.SSID)..."
    ipconfig /all | Select-String -Context 0,18 'Wireless LAN adapter Wi-Fi'

    # Run ping
    # Write-Host "Pinging a common address (8.8.8.8) for $network..."
    ping 8.8.8.8

    # Wait for a few seconds before switching to the next network
    Start-Sleep -Seconds 5

    # Remove the wireless network profile
    netsh wlan delete profile name=$network
}
