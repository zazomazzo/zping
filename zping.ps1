<#
.SYNOPSIS
    Pings a host and displays the output in a custom, timestamped format.

.DESCRIPTION
    zping is a utility that sends ICMP echo requests to a target host, similar to the standard Windows ping command.
    It provides a clear, timestamped output for each reply, indicating success or failure.
    The script uses the more efficient .NET Ping class for better performance and more detailed status information.
    It can also log successful pings to a CSV file for later analysis.

.PARAMETER target_name
    Specifies the DNS name or IP address of the target host. This parameter is mandatory.

.PARAMETER tt
    Specifies that pinging does not continue until the script is manually stopped (by pressing CTRL+C).

.PARAMETER n
    Specifies the number of echo requests to send when tt is set. The default is 4.

.PARAMETER csvlog
    Specifies that CSV logging should be enabled, using a default file name.

.PARAMETER csvlogPath
    Specifies the full path for a CSV file to log results. 
    Format: datetime, target_name, target_ip, RoundtripTime

.EXAMPLE
    .\zping.ps1 google.com
    Pings google.com until stopped.

.EXAMPLE
    .\zping.ps1 1.1.1.1 -n 10
    Pings the IP address 1.1.1.1 ten times.

.EXAMPLE
    .\zping.ps1 my-server -tt -csvlog
    Pings my-server 4 times and logs successful pings to a default CSV file.

.EXAMPLE
    .\zping.ps1 my-server -tt -csvlogPath C:\logs\ping.csv
    Pings my-server 4 times and logs successful pings to the specified CSV file.

.OUTPUTS
    System.String
    Outputs a formatted string to the console for each ping attempt.
    Success: <HH:mm:ss> | <target_name> | time=<response time>ms
    Failure: <HH:mm:ss> | <target_name> | Reply from <IP>: <Reason>
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The hostname or IP address to ping.")]
    [string]$target_name,
    
    [Parameter(Mandatory = $false, HelpMessage = "Ping the specified host until stopped (Ctrl+C).")]
    [switch]$tt,
    
    [Parameter(Mandatory = $false, HelpMessage = "Number of echo requests to send.")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$n = 4,
    
    [Parameter(Mandatory = $false, HelpMessage = "Enable CSV logging with default file.")]
    [switch]$csvlog,

    [Parameter(Mandatory = $false, HelpMessage = "Specify CSV log file path/filename.")]
    [string]$csvlogPath
)

# Create a single instance of the Ping object to reuse.
# This is more efficient than creating a new one in a loop.
$pingSender = New-Object System.Net.NetworkInformation.Ping

# This is the core function that performs and formats a single ping.
# It takes the IP to ping as an argument to avoid repeated DNS lookups.
function Invoke-SinglePing {
    param(
        [System.Net.IPAddress]$IpToPing
    )

    try {
        # Send the ICMP echo request to the pre-resolved IP. A timeout of 3 seconds is used.
        $reply = $pingSender.Send($IpToPing, 3000)

        # Get a timestamp for the output line.
        $timestamp = (Get-Date).ToString('HH:mm:ss')

        # Prepare base log object
        $logObject = [PSCustomObject]@{
            datetime      = (Get-Date -Format 'o') # ISO 8601 format
            target_name   = $target_name
            target_ip     = $IpToPing.IPAddressToString
            status       = $reply.Status
            RoundtripTime = $null
            failure_reason = $null
        }

        # Check the status of the reply.
        if ($reply.Status -eq 'Success') {
            # Format the response time string. Show "<1ms" for sub-millisecond replies.
            $timeString = if ($reply.RoundtripTime -lt 1) { "time<1ms" } else { "time=$($reply.RoundtripTime)ms" }
            
            # Write the formatted success message to the host.
            Write-Host "$timestamp | $name_IP | $timeString"

            # Update log object for success
            $logObject.RoundtripTime = $reply.RoundtripTime
        }
        else {
            # For failures like HostUnreachable, the reply might come from an intermediate router.
            $replyFrom = if ($reply.Address -and $reply.Address.ToString() -ne '0.0.0.0') {
                "Reply from $($reply.Address):"
            } else {
                ""
            }
            
            # Write the formatted failure message.
            Write-Host "$timestamp | $target_name | $replyFrom $($reply.Status)" -ForegroundColor Yellow

            # Update log object for failure
            $logObject.failure_reason = "$replyFrom $($reply.Status)".Trim()
        }

        # Write to CSV file if logging is enabled
        if ($enableLogging) {
            $logObject | Export-Csv -Path $csvlogPath -NoTypeInformation -Append -Encoding UTF8
        }

    }
    catch [System.Net.NetworkInformation.PingException] {
        $timestamp = (Get-Date).ToString('HH:mm:ss')
        $errorMessage = "A ping exception occurred to $stringIP`: $($_.Exception.Message)"
        Write-Host "$timestamp | $target_name | $errorMessage" -ForegroundColor Red

        # Log exception if logging is enabled
        if ($enableLogging) {
            [PSCustomObject]@{
                datetime       = (Get-Date -Format 'o')
                target_name   = $target_name
                target_ip     = $IpToPing.IPAddressToString
                status        = 'Exception'
                RoundtripTime = $null
                failure_reason = $errorMessage
            } | Export-Csv -Path $csvlogPath -NoTypeInformation -Append -Encoding UTF8
        }
    }
    catch {
        $timestamp = (Get-Date).ToString('HH:mm:ss')
        $errorMessage = "An unexpected error occurred: $($_.Exception.Message)"
        Write-Host "$timestamp | $target_name | $errorMessage" -ForegroundColor Red

        # Log unexpected error if logging is enabled
        if ($enableLogging) {
            [PSCustomObject]@{
                datetime       = (Get-Date -Format 'o')
                target_name   = $target_name
                target_ip     = $IpToPing.IPAddressToString
                status        = 'Error'
                RoundtripTime = $null
                failure_reason = $errorMessage
            } | Export-Csv -Path $csvlogPath -NoTypeInformation -Append -Encoding UTF8
        }
    }
}

# --- Main Script Logic ---

# Setup CSV logging if requested
$enableLogging = $csvlog -or $PSBoundParameters.ContainsKey('csvlogPath')
if ($enableLogging) {
    if ([string]::IsNullOrWhiteSpace($csvlogPath)) {
        $timestamp = Get-Date -Format 'yyyyMMddTHHmmss'
        $safeName = $target_name -replace '[\\/:*?"<>|]', '_'
        $csvlogPath = Join-Path (Get-Location) "zping-${safeName}-${timestamp}.csv"
        Write-Host "CSV logging enabled. Using default file: $csvlogPath"
    }
    else {
        Write-Host "CSV logging enabled. Using file: $csvlogPath"
    }
    
    # Validate CSV log path
    try {
        $logDirectory = Split-Path -Path $csvlogPath -Parent
        if ($logDirectory -and (-not (Test-Path -Path $logDirectory -PathType Container))) {
            throw "The directory for the log file does not exist: '$logDirectory'"
        }
    }
    catch {
        Write-Host "Error with CSV log path '$csvlogPath': $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# Resolve the hostname to an IP address ONCE before starting the loop.
$ipAddress = try {
    [System.Net.Dns]::GetHostAddresses($target_name)[0]
} catch {
    Write-Host "Ping request could not find host $target_name. Please check the name and try again." -ForegroundColor Red
    return # Exit if resolution fails
}
$stringIP = $ipAddress.IPAddressToString
if ($target_name -eq $stringIP ) {
    $name_IP = $target_name
}
else {
    $name_IP = "$target_name [$stringIP]"
}

Write-Host "`nPinging $name_IP..."

if (-not $tt.IsPresent) {
    # If -tt is not used, loop indefinitely.
    while ($true) {
        Invoke-SinglePing -IpToPing $ipAddress
        Start-Sleep -Seconds 1 # Add a short delay to avoid flooding the console
    }
}
else {
    # If -tt is used, loop for the number of times specified by -n (or the default of 4).
    foreach ($i in 1..$n) {
        Invoke-SinglePing -IpToPing $ipAddress
        Start-Sleep -Seconds 1 # Add a short delay to avoid flooding the console
    }
}