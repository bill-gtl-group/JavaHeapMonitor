# Java Heap Memory Monitor - Actual Usage
# This script monitors Java heap memory usage (actual used bytes, not percentage of committed) and sends alerts when thresholds are exceeded
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
    $body = "${message}: Actual heap usage is at $usage% on host $($config.manualHostname)."

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
        Write-Log "$message alert sent: Actual heap usage is at $usage%."

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

# Initial configuration load
$config = Load-Configuration -configPath $ConfigFilePath

# If config couldn't be loaded, exit
if ($null -eq $config) {
    Write-Host "Failed to load configuration. Exiting."
    exit 1
}

Write-Host "Java Heap Memory Monitor (Actual Usage) started"
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
    $javaProcesses = Get-Process | Where-Object { $_.ProcessName -like $config.javaProcessName -or $_.ProcessName -like "HeapTester*" -or $_.ProcessName -like "*java*" }

    if (-not $javaProcesses -or $javaProcesses.Count -eq 0) {
        Write-Log "No Java process found with name '$($config.javaProcessName)' or 'HeapTester*' or '*java*'. Waiting..."
        Start-Sleep -Seconds $config.sleepInterval
        continue
    }

    # If multiple Java processes are found, use the first one
    $javaProcess = $javaProcesses | Select-Object -First 1
    $javaPID = $javaProcess.Id
    Write-Log "Found Java process: $($javaProcess.ProcessName) with PID: $javaPID"
    Write-Log "Monitoring Java process with PID: $javaPID"

    # Get heap memory usage using jstat -gc (which shows actual sizes, not just percentages)
    try {
        Write-Log "Executing: $($config.jstatPath) -gc $javaPID"
        $jstatOutput = & $config.jstatPath -gc $javaPID 2>&1
        
        # Check if there was an error
        if ($LASTEXITCODE -ne 0) {
            Write-Log "jstat command failed with exit code $LASTEXITCODE"
            Write-Log "Output: $jstatOutput"
            
            # Try with -help to see if jstat is working at all
            Write-Log "Testing jstat with -help option..."
            $jstatHelpOutput = & $config.jstatPath -help 2>&1
            Write-Log "jstat -help output: $jstatHelpOutput"
            
            # Try listing available counters for the process
            Write-Log "Testing jstat with -options for PID $javaPID..."
            $jstatOptionsOutput = & $config.jstatPath -options $javaPID 2>&1
            Write-Log "jstat -options output: $jstatOptionsOutput"
            
            Start-Sleep -Seconds $config.sleepInterval
            continue
        }
    } catch {
        Write-Log "Failed to execute jstat: $_"
        Write-Log "Exception details: $($_.Exception.Message)"
        Write-Log "Stack trace: $($_.ScriptStackTrace)"
        Start-Sleep -Seconds $config.sleepInterval
        continue
    }

    # Check if the output is valid
    if ($jstatOutput) {
        $lines = $jstatOutput -split "`n"
        if ($lines.Count -gt 1) {
            # Parse the header line to find column indices
            $headerLine = $lines[0] -split '\s+'
            $headerLine = $headerLine | Where-Object { $_ -ne "" }  # Remove empty entries
            
            # Find indices for the columns we need
            $ouIndex = [array]::IndexOf($headerLine, "OU")  # Old gen used
            $ocIndex = [array]::IndexOf($headerLine, "OC")  # Old gen capacity
            $s0uIndex = [array]::IndexOf($headerLine, "S0U")  # Survivor 0 used
            $s1uIndex = [array]::IndexOf($headerLine, "S1U")  # Survivor 1 used
            $euIndex = [array]::IndexOf($headerLine, "EU")  # Eden used
            $ecIndex = [array]::IndexOf($headerLine, "EC")  # Eden capacity
            
            # Parse the data line
            $dataLine = $lines[1] -split '\s+'
            $dataLine = $dataLine | Where-Object { $_ -ne "" }  # Remove empty entries
            
            # Extract values
            $oldGenUsed = 0.0
            $oldGenCapacity = 0.0
            $edenUsed = 0.0
            $edenCapacity = 0.0
            $survivor0Used = 0.0
            $survivor1Used = 0.0
            
            if ($ouIndex -ge 0 -and $ocIndex -ge 0 -and 
                $euIndex -ge 0 -and $ecIndex -ge 0 -and 
                $s0uIndex -ge 0 -and $s1uIndex -ge 0) {
                
                [float]::TryParse($dataLine[$ouIndex], [ref]$oldGenUsed)
                [float]::TryParse($dataLine[$ocIndex], [ref]$oldGenCapacity)
                [float]::TryParse($dataLine[$euIndex], [ref]$edenUsed)
                [float]::TryParse($dataLine[$ecIndex], [ref]$edenCapacity)
                [float]::TryParse($dataLine[$s0uIndex], [ref]$survivor0Used)
                [float]::TryParse($dataLine[$s1uIndex], [ref]$survivor1Used)
                
                # Calculate total heap used and capacity
                $totalHeapUsed = $oldGenUsed + $edenUsed + $survivor0Used + $survivor1Used
                $totalHeapCapacity = $oldGenCapacity + $edenCapacity  # Survivor spaces are part of total capacity
                
                # Calculate actual usage percentage
                $actualUsagePercentage = 0.0
                if ($totalHeapCapacity -gt 0) {
                    $actualUsagePercentage = [math]::Round(($totalHeapUsed / $totalHeapCapacity) * 100, 2)
                }
                
                # Log both the actual usage and the old generation usage for comparison
                $oldGenUsagePercentage = 0.0
                if ($oldGenCapacity -gt 0) {
                    $oldGenUsagePercentage = [math]::Round(($oldGenUsed / $oldGenCapacity) * 100, 2)
                }
                
                Write-Log "Actual heap usage: $actualUsagePercentage% (Used: $totalHeapUsed KB, Capacity: $totalHeapCapacity KB)"
                Write-Log "Old Generation usage: $oldGenUsagePercentage% (Used: $oldGenUsed KB, Capacity: $oldGenCapacity KB)"
                
                # Check if heap usage exceeds the threshold
                if ($actualUsagePercentage -gt $config.threshold) {
                    if (-not $alertSent) {
                        Send-Alert -usage $actualUsagePercentage -message "Warning"
                        $alertSent = $true  # Set flag to true after sending the alert
                    }
                } else {
                    if ($alertSent) {
                        # System returned to normal, send normal alert once
                        Send-Alert -usage $actualUsagePercentage -message "Normal"
                        $alertSent = $false  # Reset flag when memory usage is back to normal
                    }
                }
                
                # Reset normal alert flag if we're back in warning state
                if ($actualUsagePercentage -gt $config.threshold) {
                    $normalAlertSent = $false
                }
            } else {
                Write-Log "Could not find required columns in jstat output."
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
}
