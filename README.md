# zping.ps1

## Overview

`zping.ps1` is a PowerShell script that sends ICMP echo requests (pings) to a specified target host. Unlike the standard Windows `ping` command, it provides a clear, timestamped output and supports CSV logging for later analysis. The script leverages the .NET `Ping` class for efficient performance and detailed status information.

## Features

- **Timestamped Output:** Each ping result is displayed with a timestamp.
- **Customizable Ping Count:** Run the script indefinitely or for a fixed number of pings.
- **CSV Logging:** Option to log each ping attempt (including responses and errors) into a CSV file. The CSV log records use the ISO 8601 datetime format (`-Format 'o'`).
- **Error Handling:** Displays informative messages for ping failures and exceptions.

## Parameters

- **`target_name`** (Mandatory): The DNS name or IP address of the target host.
- **`-tt`** (Switch): When specified, pings the target a fixed number of times (default is 4). Otherwise, pings continuously.
- **`-n`** (Optional): The number of pings to send (default is 4 when `-tt` is used).
- **`-csvlog`** (Switch): Enables CSV logging using a default filename.
- **`-csvlogPath`** (Optional): Specifies a custom CSV file path for logging.

## Usage Examples

- **Continuous Ping Until Stopped:**
  ```
  .\zping.ps1 google.com
  ```
  Continuously pings `google.com` until manually stopped (Ctrl+C).

- **Finite Ping Count:**
  ```
  .\zping.ps1 1.1.1.1 -tt -n 10
  ```
  Pings `1.1.1.1` ten times.

- **CSV Logging with Default File:**
  ```
  .\zping.ps1 my-server -tt -csvlog
  ```
  Pings `my-server` 4 times and logs successful pings to a default CSV file.

- **CSV Logging with Custom File Path:**
  ```
  .\zping.ps1 my-server -tt -csvlogPath C:\logs\ping.csv
  ```
  Pings `my-server` 4 times and logs successful pings to `C:\logs\ping.csv`.

## Console Output Examples

When the script is executed, the output is formatted as follows:

- **Successful Ping:**
  ```
  12:34:56 | my-server [192.168.1.100] | time=24ms
  ```
  Indicates that at 12:34:56, a successful reply was received from `my-server` (resolved to 192.168.1.100) with a roundtrip time of 24ms.

- **Successful Ping (Sub-millisecond Response):**
  ```
  12:35:02 | example.com [93.184.216.34] | time<1ms
  ```
  Indicates a sub-millisecond response.

- **Ping Failure:**
  ```
  12:35:10 | my-server | Reply from 192.168.1.1: TimedOut
  ```
  Shows that at 12:35:10, a failure occurred (e.g. due to a timeout), possibly including information about an intermediate reply source.

- **DNS Resolution Error:**
  ```
  Ping request could not find host unknownhost. Please check the name and try again.
  ```
  Displayed when DNS resolution fails.

## CSV Log Output Example

When CSV logging is enabled, each ping attempt is recorded in a CSV file. Below is an example of what a CSV log entry might look like (including the "status" field):

```
datetime,target_name,target_ip,status,RoundtripTime,failure_reason
2025-08-23T12:34:56.7890123Z,my-server,192.168.1.100,Success,24,
2025-08-23T12:35:01.1234567Z,example.com,93.184.216.34,TimedOut,,Reply from 93.184.216.34: TimedOut
```

- **datetime:** Recorded in ISO 8601 format using `-Format 'o'`.
- **target_name:** The specified host name.
- **target_ip:** Resolved IP address.
- **status:** The status of the ping (e.g., `Success`, `TimedOut`, `Exception`).
- **RoundtripTime:** The response time in milliseconds (blank if the ping failed).
- **failure_reason:** Reason for failure (if any).

## How It Works

1. **Initialization:** The script creates a single instance of the .NET `Ping` object to reuse for efficiency.
2. **DNS Resolution:** It resolves the target name to an IP address before starting the ping loop.
3. **Ping Execution:** Sends an ICMP echo request with a 3-second timeout per ping.
4. **Output Formatting:** Displays each ping result with a timestamp, target information, response time or error message.
5. **CSV Logging (Optional):** If enabled, the script logs each ping attempt to the specified CSV file with detailed information.

## Requirements

- **PowerShell:** Execute the script in a PowerShell environment with appropriate execution policies.
- **.NET Framework:** The script relies on the .NET `Ping` class.

## Running the Script

1. Open PowerShell.
2. Navigate to the script directory:
   ```
   cd c:\scripts
   ```
3. Execute the script with desired parameters, for example:
   ```
   .\zping.ps1 google.com
   ```

## License

This script is provided as-is without any warranty. Use at your own risk.

## Contributions

Feel free to fork the repository and submit pull requests for
