# Java Heap Memory Monitor - WMI Version
# This script monitors Java heap memory usage using Windows Management Instrumentation (WMI)
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
    $body = "${message}: Memory usage is at $usage% on host $($config.manualHostname)."

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
        Write-Log "$message alert sent: Memory usage is at $usage%."

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

# Function to get memory usage using WMI
function Get-MemoryUsage {
    param (
        [int]$processPid
    )

    try {
        # Get process information using WMI
        Write-Log "Getting memory information for process with PID: $processPid using WMI"
        $process = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $processPid"
        
        if ($null -eq $process) {
            Write-Log "Process with PID $processPid not found using WMI"
            return $null
        }
        
        # Get process memory information
        $processMemoryInfo = Get-Process -Id $processPid -ErrorAction SilentlyContinue
        
        if ($null -eq $processMemoryInfo) {
            Write-Log "Could not get memory information for process with PID $processPid"
            return $null
        }
        
        # Get memory usage details
        $workingSet = $processMemoryInfo.WorkingSet64
        $privateMemory = $processMemoryInfo.PrivateMemorySize64
        $virtualMemory = $processMemoryInfo.VirtualMemorySize64
        $peakWorkingSet = $processMemoryInfo.PeakWorkingSet64
        $peakVirtualMemory = $processMemoryInfo.PeakVirtualMemorySize64
        
        # Log memory usage details
        # 1MB = 1048576 bytes
        Write-Log "Process memory details:"
        Write-Log "  Working Set: $([math]::Round($workingSet / 1048576, 2)) MB"
        Write-Log "  Private Memory: $([math]::Round($privateMemory / 1048576, 2)) MB"
        Write-Log "  Virtual Memory: $([math]::Round($virtualMemory / 1048576, 2)) MB"
        Write-Log "  Peak Working Set: $([math]::Round($peakWorkingSet / 1048576, 2)) MB"
        Write-Log "  Peak Virtual Memory: $([math]::Round($peakVirtualMemory / 1048576, 2)) MB"
        
        # Get system memory information
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $totalPhysicalMemory = $computerSystem.TotalPhysicalMemory
        
        # Extract max heap size from command line if available
        $maxHeapSize = 0
        $commandLine = $process.CommandLine
        if ($commandLine -match "-Xmx(\d+)([mMgG])")
        {
            $heapSizeValue = [int]$Matches[1]
            $heapSizeUnit = $Matches[2].ToLower()
            
            if ($heapSizeUnit -eq "g")
            {
                $maxHeapSize = $heapSizeValue * 1024 # Convert GB to MB
            }
            else
            {
                $maxHeapSize = $heapSizeValue # Already in MB
            }
            
            Write-Log "Detected max heap size from command line: $maxHeapSize MB"
        }
        
        # Calculate actual heap usage (focus on used heap, not committed)
        # For Java processes, the actual heap usage is typically closer to the Working Set
        # than the Private Memory, especially for small heap sizes
        $estimatedHeapUsage = $workingSet
        $estimatedHeapUsageMB = [math]::Round($estimatedHeapUsage / 1048576, 2)
        Write-Log "Estimated actual heap usage: $estimatedHeapUsageMB MB"
        
        # If we have a max heap size, calculate percentage based on that
        if ($maxHeapSize -gt 0)
        {
            $heapUsagePercentage = [math]::Round(($estimatedHeapUsageMB / $maxHeapSize) * 100, 2)
            Write-Log "Heap usage percentage (Estimated Heap / Max Heap): $heapUsagePercentage%"
            
            # Return the heap usage percentage
            return $heapUsagePercentage
        }
        else
        {
            # Calculate memory usage percentage based on working set
            $memoryUsagePercentage = [math]::Round(($workingSet / $totalPhysicalMemory) * 100, 2)
            Write-Log "Memory usage percentage (Working Set / Total Physical Memory): $memoryUsagePercentage%"
            
            # Calculate memory usage percentage based on private memory
            $privateMemoryPercentage = [math]::Round(($privateMemory / $totalPhysicalMemory) * 100, 2)
            Write-Log "Memory usage percentage (Private Memory / Total Physical Memory): $privateMemoryPercentage%"
            
            # Return the working set percentage as it's closer to actual heap usage
            return $memoryUsagePercentage
        }
    }
    catch {
        Write-Log "Error getting memory usage: $_"
        Write-Log "Exception details: $($_.Exception.Message)"
        Write-Log "Stack trace: $($_.ScriptStackTrace)"
        return $null
    }
}

# Function to get detailed process information
function Get-DetailedProcessInfo {
    param (
        [int]$processPid
    )
    
    try {
        # Get process information using WMI
        $process = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $processPid"
        
        if ($null -eq $process) {
            Write-Log "Process with PID $processPid not found using WMI"
            return
        }
        
        # Get process details
        $processName = $process.Name
        $processPath = $process.ExecutablePath
        $commandLine = $process.CommandLine
        $parentPid = $process.ParentProcessId
        $creationDate = $process.CreationDate
        
        # Log process details
        Write-Log "Detailed process information for PID: $processPid"
        Write-Log "  Process Name: $processName"
        Write-Log "  Process Path: $processPath"
        Write-Log "  Command Line: $commandLine"
        Write-Log "  Parent PID: $parentPid"
        Write-Log "  Creation Date: $creationDate"
        
        # Get parent process information
        $parentProcess = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $parentPid"
        
        if ($null -ne $parentProcess) {
            Write-Log "  Parent Process Name: $($parentProcess.Name)"
            Write-Log "  Parent Process Path: $($parentProcess.ExecutablePath)"
        }
        
        # Get process modules
        $processModules = Get-Process -Id $processPid -Module -ErrorAction SilentlyContinue
        
        if ($null -ne $processModules) {
            Write-Log "  Loaded Modules:"
            
            # Check for Java-related modules
            $javaModules = $processModules.ModuleName | Where-Object { $_ -like "*java*" -or $_ -like "*jvm*" }
            
            if ($null -ne $javaModules -and $javaModules.Count -gt 0) {
                Write-Log "  Java-related modules found:"
                foreach ($module in $javaModules) {
                    Write-Log "    $module"
                }
            } else {
                Write-Log "  No Java-related modules found. This might not be a Java process."
            }
        }
    }
    catch {
        Write-Log "Error getting detailed process information: $_"
    }
}

# Initial configuration load
$config = Load-Configuration -configPath $ConfigFilePath

# If config couldn't be loaded, exit
if ($null -eq $config) {
    Write-Host "Failed to load configuration. Exiting."
    exit 1
}

Write-Host "Java Heap Memory Monitor (WMI Version) started"
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
    
    # Get detailed process information on first detection
    Get-DetailedProcessInfo -processPid $javaPID
    
    Write-Log "Monitoring Java process with PID: $javaPID"

    # Get memory usage
    $memoryUsage = Get-MemoryUsage -processPid $javaPID
    
    if ($null -ne $memoryUsage) {
        # Check if memory usage exceeds the threshold
        if ($memoryUsage -gt $config.threshold) {
            if (-not $alertSent) {
                Send-Alert -usage $memoryUsage -message "Warning"
                $alertSent = $true  # Set flag to true after sending the alert
            }
        } else {
            if ($alertSent) {
                # System returned to normal, send normal alert once
                Send-Alert -usage $memoryUsage -message "Normal"
                $alertSent = $false  # Reset flag when memory usage is back to normal
            }
        }
        
        # Reset normal alert flag if we're back in warning state
        if ($memoryUsage -gt $config.threshold) {
            $normalAlertSent = $false
        }
    } else {
        Write-Log "Could not determine memory usage for Java process with PID: $javaPID"
    }

    # Sleep for the specified interval
    Start-Sleep -Seconds $config.sleepInterval
    Write-Host "." -NoNewline
}
