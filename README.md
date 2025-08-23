# zping.ps1

## Overview

`zping.ps1` is a PowerShell script that performs ICMP ping tests similar to the standard Windows `ping` command. It uses the .NET `Ping` class for efficient and detailed responses. The script outputs timestamped ping results and can optionally log successful pings to a CSV file for analysis.

## Features

- **Timestamped Output:** Displays each ping result with a timestamp.
- **Customizable Ping Count:** You can specify a fixed number of pings or run continuously.
- **CSV Logging:** Optionally logs successful pings with details such as timestamp, target IP, and response time.
- **Error Handling:** Catches and displays ping exceptions and unexpected errors.

## Parameters

- **`target_name`** (Mandatory): The DNS name or IP address of the target host.
- **`-tt`** (Switch): When specified, the script pings the target a finite number of times (default is 4) instead of indefinitely.
- **`-n`** (Optional): Number of ping attempts when `-tt` is used. Default is 4.
- **`-csvlog`** (Switch): Enables CSV logging using a default file name.
- **`-csvlogPath`** (Optional): Specifies a custom CSV log file path and filename.

## Usage Examples

- **Continuous Ping Until Stopped:**
  ```
  .\zping.ps1 google.com
  ```
  This continuously pings `google.com` until manually stopped (Ctrl+C).

- **Finite Ping Count:**
  ```
  .\zping.ps1 1.1.1.1 -tt -n 10
  ```
  This pings `1.1.1.1` a total of 10 times.

- **CSV Logging with Default File:**
  ```
  .\zping.ps1 my-server -tt -csvlog
  ```
  This pings `my-server` 4 times and logs the successful pings to a default CSV file.

- **CSV Logging with Custom File Path:**
  ```
  .\zping.ps1 my-server -tt -csvlogPath C:\logs\ping.csv
  ```
  This pings `my-server` 4 times and logs the successful pings to `C:\logs\ping.csv`.

## How It Works

1. **Ping Initialization:** The script creates a single instance of the .NET `Ping` object for efficiency.
2. **DNS Resolution:** Before pinging, it resolves the target name to an IP address.
3. **Ping Execution:** It sends ICMP echo requests and formats the output with a timestamp.
4. **Logging:** If CSV logging is enabled, each ping result (success or failure) is appended to the specified CSV file.
5. **Continuous or Finite Loop:** The script either loops indefinitely or performs a fixed number of pings based on the parameters provided.

## Requirements

- **PowerShell:** Ensure that you are running the script in a PowerShell environment with appropriate execution policy settings.
- **.NET Framework:** The script relies on the .NET `Ping` class, so .NET must be available on the system.

## Running the Script

1. Open PowerShell.
2. Navigate to the directory containing `zping.ps1`:
   ```
   cd c:\scripts
   ```
3. Execute the script with the desired parameters. For example:
   ```
   .\zping.ps1 google.com
   ```

## License

This script is provided as-is without warranty of any kind. Use at your own risk.

## Contributions

Feel free to fork and contribute improvements or bug fixes
