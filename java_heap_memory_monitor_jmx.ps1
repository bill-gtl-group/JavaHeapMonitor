# Java Heap Memory Monitor - JMX Version
# This script monitors Java heap memory usage using JMX instead of jstat
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

# Function to get heap usage using JConsole command-line
function Get-HeapUsage {
    param (
        [int]$processPid
    )

    try {
        # Create a temporary file to store the JConsole output
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        # Use jcmd to get heap information
        $jcmdPath = Join-Path -Path (Split-Path -Parent $config.jstatPath) -ChildPath "jcmd.exe"
        Write-Log "Executing: $jcmdPath $processPid GC.heap_info"
        
        $output = & $jcmdPath $processPid GC.heap_info 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "jcmd command failed with exit code $LASTEXITCODE"
            Write-Log "Output: $output"
            
            # Try with VM.version to see if jcmd can connect to the process
            Write-Log "Testing jcmd with VM.version for PID $processPid..."
            $jcmdVersionOutput = & $jcmdPath $processPid VM.version 2>&1
            Write-Log "jcmd VM.version output: $jcmdVersionOutput"
            
            # Try with help to see what commands are available
            Write-Log "Testing jcmd with help for PID $processPid..."
            $jcmdHelpOutput = & $jcmdPath $processPid help 2>&1
            Write-Log "jcmd help output: $jcmdHelpOutput"
            
            return $null
        }
        
        # Parse the output to get heap usage
        $heapInfo = $output -join "`n"
        Write-Log "Heap info: $heapInfo"
        
        # Try to extract heap usage information
        $usedHeap = 0
        $totalHeap = 0
        
        # Look for patterns like "used 123M" and "capacity 456M"
        $usedMatch = [regex]::Match($heapInfo, "used\s+(\d+)([KMG])")
        $totalMatch = [regex]::Match($heapInfo, "capacity\s+(\d+)([KMG])")
        
        if ($usedMatch.Success -and $totalMatch.Success) {
            $usedValue = [double]$usedMatch.Groups[1].Value
            $usedUnit = $usedMatch.Groups[2].Value
            
            $totalValue = [double]$totalMatch.Groups[1].Value
            $totalUnit = $totalMatch.Groups[2].Value
            
            # Convert to bytes based on unit
            switch ($usedUnit) {
                "K" { $usedHeap = $usedValue * 1024 }
                "M" { $usedHeap = $usedValue * 1024 * 1024 }
                "G" { $usedHeap = $usedValue * 1024 * 1024 * 1024 }
                default { $usedHeap = $usedValue }
            }
            
            switch ($totalUnit) {
                "K" { $totalHeap = $totalValue * 1024 }
                "M" { $totalHeap = $totalValue * 1024 * 1024 }
                "G" { $totalHeap = $totalValue * 1024 * 1024 * 1024 }
                default { $totalHeap = $totalValue }
            }
            
            # Calculate percentage
            if ($totalHeap -gt 0) {
                $usagePercentage = [math]::Round(($usedHeap / $totalHeap) * 100, 2)
                Write-Log "Calculated heap usage: $usagePercentage% (Used: $usedHeap bytes, Total: $totalHeap bytes)"
                return $usagePercentage
            }
        }
        
        # If we couldn't parse the output, try using jinfo to get heap usage
        Write-Log "Could not parse heap usage from jcmd output. Trying alternative method..."
        
        # Use jinfo to get heap information
        $jinfoPath = Join-Path -Path (Split-Path -Parent $config.jstatPath) -ChildPath "jinfo.exe"
        Write-Log "Executing: $jinfoPath -sysprops $processPid"
        
        $jinfoOutput = & $jinfoPath -sysprops $processPid 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "jinfo command failed with exit code $LASTEXITCODE"
            Write-Log "Output: $jinfoOutput"
            return $null
        }
        
        # Look for heap size properties
        $maxHeapMatch = [regex]::Match($jinfoOutput, "java.lang.Runtime.maxMemory=(\d+)")
        $totalMemoryMatch = [regex]::Match($jinfoOutput, "java.lang.Runtime.totalMemory=(\d+)")
        $freeMemoryMatch = [regex]::Match($jinfoOutput, "java.lang.Runtime.freeMemory=(\d+)")
        
        if ($maxHeapMatch.Success -and $totalMemoryMatch.Success -and $freeMemoryMatch.Success) {
            $maxHeap = [double]$maxHeapMatch.Groups[1].Value
            $totalMemory = [double]$totalMemoryMatch.Groups[1].Value
            $freeMemory = [double]$freeMemoryMatch.Groups[1].Value
            
            $usedHeap = $totalMemory - $freeMemory
            
            # Calculate percentage
            if ($maxHeap -gt 0) {
                $usagePercentage = [math]::Round(($usedHeap / $maxHeap) * 100, 2)
                Write-Log "Calculated heap usage from jinfo: $usagePercentage% (Used: $usedHeap bytes, Max: $maxHeap bytes)"
                return $usagePercentage
            }
        }
        
        Write-Log "Could not determine heap usage from available tools."
        return $null
    }
    catch {
        Write-Log "Error getting heap usage: $_"
        Write-Log "Exception details: $($_.Exception.Message)"
        Write-Log "Stack trace: $($_.ScriptStackTrace)"
        return $null
    }
}

# Initial configuration load
$config = Load-Configuration -configPath $ConfigFilePath

# If config couldn't be loaded, exit
if ($null -eq $config) {
    Write-Host "Failed to load configuration. Exiting."
    exit 1
}

Write-Host "Java Heap Memory Monitor (JMX Version) started"
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

    # Get heap usage
    $heapUsage = Get-HeapUsage -processPid $javaPID
    
    if ($null -ne $heapUsage) {
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
        
        # Reset normal alert flag if we're back in warning state
        if ($heapUsage -gt $config.threshold) {
            $normalAlertSent = $false
        }
    } else {
        Write-Log "Could not determine heap usage for Java process with PID: $javaPID"
    }

    # Sleep for the specified interval
    Start-Sleep -Seconds $config.sleepInterval
    Write-Host "." -NoNewline
}
