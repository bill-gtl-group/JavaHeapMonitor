# Java Heap Memory Monitor
# This script monitors Java heap memory usage and sends alerts when thresholds are exceeded
# Configuration is loaded from an external JSON file

# Default config file path - can be overridden with command line parameter
param (
    [string]$ConfigFilePath = "java_heap_monitor_config.json"
)

# Global variables
$config = $null
$alertSent = $false  # Track alert state
$alertRetryCounter = 0  # Counter for alert retries
$lastAlertTime = [DateTime]::MinValue  # Track when the last alert was sent
$lastConfigLoadTime = [DateTime]::Now  # Track when config was last loaded
$normalAlertSent = $false  # Track if normal alert was sent

# Function to load configuration from JSON file
function Load-Configuration {
    param (
        [string]$configPath
    )

    try {
        if (Test-Path $configPath) {
            $configContent = Get-Content -Path $configPath -Raw
            $configObj = ConvertFrom-Json -InputObject $configContent
            Write-Host "Configuration loaded successfully from $configPath"
            return $configObj
        } else {
            Write-Host "Configuration file not found at $configPath. Using default values."
            return $null
        }
    } catch {
        Write-Host "Error loading configuration: $_"
        return $null
    }
}

# Function to write to log
function Write-Log {
    param (
        [string]$message
    )

    $dateString = (Get-Date).ToString("yyyy-MM-dd")
    $logFile = Join-Path -Path $config.logDirectory -ChildPath "java_heap_memory_$dateString.log"

    # Create log directory if it doesn't exist
    if (-not (Test-Path -Path $config.logDirectory)) {
        New-Item -Path $config.logDirectory -ItemType Directory -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
    Write-Host "$timestamp - $message"
}

# Function to send alert email with retry logic
function Send-Alert {
    param (
        [float]$usage,
        [string]$message
    )

    $subject = "Java Heap Memory Alert on $($config.manualHostname)"
    $body = "${message}: Heap usage is at $usage% on host $($config.manualHostname)."

    # Check if we should throttle alerts
    $currentTime = [DateTime]::Now
    $timeSinceLastAlert = $currentTime - $lastAlertTime

    # If this is a normal alert and we've already sent one, don't send again
    if ($message -eq "Normal" -and $normalAlertSent) {
        Write-Log "Normal alert already sent, not sending again."
        return
    }

    # If this is a warning alert, check throttling
    if ($message -eq "Warning" -and $alertSent -and $timeSinceLastAlert.TotalMinutes -lt $config.alertThrottleMinutes) {
        Write-Log "Alert throttled: Last alert was sent $($timeSinceLastAlert.TotalMinutes) minutes ago (throttle set to $($config.alertThrottleMinutes) minutes)"
        return
    }

    try {
        Send-MailMessage -To $config.emailTo -From $config.emailFrom -Subject $subject -Body $body -SmtpServer $config.smtpServer -Port $config.smtpPort
        Write-Log "$message alert sent: Heap usage is at $usage%."

        # Update tracking variables
        $lastAlertTime = $currentTime
        $alertRetryCounter = 0

        # If this is a normal alert, mark it as sent
        if ($message -eq "Normal") {
            $normalAlertSent = $true
        }
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Failed to send alert email: $errorMessage"

        # Increment retry counter and try again if under the limit
        $alertRetryCounter++
        if ($alertRetryCounter -lt $config.alertRetryCount) {
            Write-Log "Will retry sending alert (Attempt $alertRetryCounter of $($config.alertRetryCount))"
            Start-Sleep -Seconds 5  # Wait before retrying
            Send-Alert -usage $usage -message $message  # Recursive call to retry
        } else {
            Write-Log "Maximum retry attempts ($($config.alertRetryCount)) reached. Alert not sent."
            $alertRetryCounter = 0  # Reset counter after max retries
        }
    }
}

# Function to calculate total heap usage from jstat output
function Calculate-TotalHeapUsage {
    param (
        [string[]]$heapData
    )

    # Parse the values from jstat output
    $s0Usage = 0.0
    $s1Usage = 0.0
    $edenUsage = 0.0
    $oldUsage = 0.0

    # Make sure we have enough data
    if ($heapData.Count -ge 5) {
        # Parse S0 (index 0)
        if (-not [float]::TryParse($heapData[0], [ref]$s0Usage)) {
            Write-Log "Failed to parse S0 usage: $($heapData[0])"
            $s0Usage = 0.0
        }

        # Parse S1 (index 1)
        if (-not [float]::TryParse($heapData[1], [ref]$s1Usage)) {
            Write-Log "Failed to parse S1 usage: $($heapData[1])"
            $s1Usage = 0.0
        }

        # Parse Eden (index 2)
        if (-not [float]::TryParse($heapData[2], [ref]$edenUsage)) {
            Write-Log "Failed to parse Eden usage: $($heapData[2])"
            $edenUsage = 0.0
        }

        # Parse Old (index 3)
        if (-not [float]::TryParse($heapData[3], [ref]$oldUsage)) {
            Write-Log "Failed to parse Old usage: $($heapData[3])"
            $oldUsage = 0.0
        }

        # Calculate total heap usage
        # Note: This is a simplified calculation. For more accuracy, we would need to know the actual sizes
        # of each generation, but this gives a better approximation than just using the old generation.
        $youngGenUsage = ($s0Usage + $s1Usage + $edenUsage) / 3
        $totalHeapUsage = ($youngGenUsage + $oldUsage) / 2

        # Log both values for comparison
        Write-Log "Young Generation usage: $youngGenUsage%, Old Generation usage: $oldUsage%, Calculated Total: $totalHeapUsage%"
        
        return $totalHeapUsage
    } else {
        Write-Log "Not enough data to calculate heap usage"
        return 0.0
    }
}

# Initial configuration load
$config = Load-Configuration -configPath $ConfigFilePath

# If config couldn't be loaded, exit
if ($null -eq $config) {
    Write-Host "Failed to load configuration. Exiting."
    exit 1
}

Write-Host "Java Heap Memory Monitor started"
Write-Host "Alert level is: $($config.threshold)% usage"
Write-Host "Alert email is: $($config.emailTo)"
Write-Host "Alert throttle: $($config.alertThrottleMinutes) minutes"
Write-Host "Config reload interval: $($config.configReloadInterval) seconds"

# Monitor Java heap memory
while ($true) {
    # Check if we need to reload the configuration
    $currentTime = [DateTime]::Now
    $timeSinceConfigLoad = $currentTime - $lastConfigLoadTime

    # Reload config if interval has passed or debug mode is enabled
    if ($config.debugMode -or $timeSinceConfigLoad.TotalSeconds -gt $config.configReloadInterval) {
        Write-Host "Reloading configuration..."
        $config = Load-Configuration -configPath $ConfigFilePath
        $lastConfigLoadTime = $currentTime

        if ($null -eq $config) {
            Write-Host "Failed to reload configuration. Using previous settings."
            # Recreate config with default values if needed
        }
    }

    # Get the Java process ID
    $javaProcess = Get-Process | Where-Object { $_.ProcessName -like $config.javaProcessName }

    if (-not $javaProcess) {
        Write-Log "No Java process found with name '$($config.javaProcessName)'. Waiting..."
        Start-Sleep -Seconds $config.sleepInterval
        continue
    }

    $javaPID = $javaProcess.Id
    Write-Log "Monitoring Java process with PID: $javaPID"

    # Get heap memory usage
    try {
        $jstatOutput = & $config.jstatPath -gcutil $javaPID
    } catch {
        Write-Log "Failed to execute jstat: $_"
        Start-Sleep -Seconds $config.sleepInterval
        continue
    }

    # Check if the output is valid
    if ($jstatOutput) {
        $lines = $jstatOutput -split "`n"
        if ($lines.Count -gt 1) {
            $heapData = $lines[1] -split '\s+'

            # Calculate total heap usage
            $heapUsage = Calculate-TotalHeapUsage -heapData $heapData
            Write-Log "Current total heap usage: $heapUsage%"

            # Check if heap usage exceeds the threshold
            if ($heapUsage -gt $config.threshold) {
                if (-not $alertSent) {
                    Send-Alert -usage $heapUsage -message "Warning"
                    $alertSent = $true  # Set flag to true after sending the alert
                }
            } else {
                if ($alertSent) {
                    # System returned to normal, send normal alert once
                    Send-Alert -usage $heapUsage -message "Normal"
                    $alertSent = $false  # Reset flag when memory usage is back to normal
                }
            }
        } else {
            Write-Log "No data found from jstat."
        }
    } else {
        Write-Log "No output received from jstat. Check if the Java process is running."
    }

    # Sleep for the specified interval
    Start-Sleep -Seconds $config.sleepInterval
    Write-Host "." -NoNewline

    # Reset normal alert flag if we're back in warning state
    if ($heapUsage -gt $config.threshold) {
        $normalAlertSent = $false
    }
}
