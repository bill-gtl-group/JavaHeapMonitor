# Java Heap Monitor - Offline Installation Guide

This guide provides step-by-step instructions for installing the Java Heap Monitor in an offline environment.

## Prerequisites

- Windows operating system
- PowerShell 5.0 or higher
- Java Development Kit (JDK) installed (for jstat.exe)

## Installation Steps

### 1. Prepare the Installation Package

Create a ZIP file containing the following files from the Java Heap Monitor repository:

- `java_heap_memory_monitor.ps1` - Original script
- `java_heap_memory_monitor_fixed.ps1` - Fixed version with improved heap usage calculation
- `java_heap_memory_monitor_old_gen_only.ps1` - Version that only monitors Old Generation heap usage
- `java_heap_monitor_config.json` - Configuration file
- `run_fixed_monitor.bat` - Batch file to run the fixed monitor script
- `run_old_gen_only_monitor.bat` - Batch file to run the Old Generation only monitor
- `README.md` - Documentation
- `README-OLD-GEN-ONLY.md` - Documentation for the Old Generation only version

You can download these files from the GitHub repository at https://github.com/bill-gtl-group/JavaHeapMonitor or copy them from an existing installation.

### 2. Transfer the Installation Package

Transfer the ZIP file to the target machine using a USB drive, network share, or any other available method.

### 3. Extract the Files

1. Create a directory for the Java Heap Monitor on the target machine (e.g., `C:\JavaHeapMonitor`)
2. Extract the contents of the ZIP file to this directory

### 4. Configure the Monitor

1. Open the `java_heap_monitor_config.json` file in a text editor
2. Update the configuration settings as needed:

```json
{
  "threshold": 70,
  "emailTo": "your-email@example.com",
  "emailFrom": "alerts@example.com",
  "smtpServer": "mail.example.com",
  "smtpPort": 25,
  "javaProcessName": "java",
  "logDirectory": "C:\\JavaHeapMonitor\\Logs",
  "jstatPath": "C:\\Program Files\\Java\\jdk-17.0.4.1\\bin\\jstat.exe",
  "sleepInterval": 10,
  "manualHostname": "YOUR-SERVER-NAME",
  "alertRetryCount": 3,
  "alertThrottleMinutes": 60,
  "configReloadInterval": 300,
  "debugMode": false
}
```

Important settings to verify:
- `jstatPath`: Update this to the correct path of jstat.exe on the target machine
- `logDirectory`: Create this directory if it doesn't exist
- `emailTo`, `emailFrom`, `smtpServer`, `smtpPort`: Update with your email settings
- `manualHostname`: Set to the hostname of the target machine

### 5. Create the Log Directory

Create the log directory specified in the configuration file:

```
mkdir C:\JavaHeapMonitor\Logs
```

### 6. Test the Installation

Run one of the batch files to test the installation:

```
cd C:\JavaHeapMonitor
.\run_fixed_monitor.bat
```

Or for the Old Generation only version:

```
.\run_old_gen_only_monitor.bat
```

The script should start monitoring Java processes and logging information to the specified log directory.

## Setting Up as a Scheduled Task

To run the Java Heap Monitor as a scheduled task:

1. Open Task Scheduler (taskschd.msc)
2. Click "Create Basic Task"
3. Enter a name (e.g., "Java Heap Monitor") and description
4. Set the trigger (e.g., "At startup" or "Daily")
5. Select "Start a program" as the action
6. Browse to the batch file you want to run (e.g., `C:\JavaHeapMonitor\run_fixed_monitor.bat`)
7. Set the "Start in" field to the installation directory (e.g., `C:\JavaHeapMonitor`)
8. Complete the wizard and check "Open the Properties dialog" before finishing
9. In the Properties dialog, go to the "Settings" tab
10. Check "Run task as soon as possible after a scheduled start is missed"
11. Click "OK" to save the task

## Troubleshooting

If you encounter issues:

1. Check the log files in the configured log directory
2. Verify that jstat.exe is available at the path specified in the configuration
3. Ensure PowerShell execution policy allows running scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```
4. Check that the Java process name in the configuration matches the actual process name
5. Verify SMTP settings if alerts are not being sent

## Updating the Installation

To update an existing installation:

1. Back up the current configuration file
2. Replace the script files with the new versions
3. Compare and merge any changes to the configuration file
4. Restart the monitoring service or scheduled task

## Choosing the Right Version

The Java Heap Monitor comes in three versions:

1. **Original Version** (`java_heap_memory_monitor.ps1`):
   - Basic functionality
   - Monitors only Old Generation heap usage
   - Use when you need a simple monitoring solution

2. **Fixed Version** (`java_heap_memory_monitor_fixed.ps1`):
   - Improved heap usage calculation
   - Monitors both Young and Old generations
   - Provides more accurate total heap usage
   - Use when you need comprehensive heap monitoring

3. **Old Generation Only Version** (`java_heap_memory_monitor_old_gen_only.ps1`):
   - Focuses only on Old Generation heap usage
   - Includes all enhancements from the fixed version
   - More stable metrics less affected by garbage collection
   - Use when you want to avoid false alerts from Young Generation fluctuations

For most production environments, the Fixed Version or Old Generation Only Version is recommended.

## Understanding Heap Usage Measurement

### Heap Used vs. Heap Committed

It's important to understand how the Java Heap Monitor measures heap usage:

- **Heap Used**: The amount of memory currently occupied by Java objects
- **Heap Committed**: The total amount of memory allocated to the JVM by the operating system

All versions of the Java Heap Monitor measure the **Heap Used** as a percentage of the **Heap Committed**, not the committed heap itself. This is the most relevant metric for detecting memory issues, as it shows how much of the available heap space is actually being consumed.

### How It Works

The monitor uses the `jstat -gcutil` command, which outputs utilization percentages:

```
S0     S1     E      O      M     
0.00   0.00  33.33  75.21  98.07
```

Where:
- S0, S1: Survivor spaces (part of Young Generation)
- E: Eden space (part of Young Generation)
- O: Old Generation
- M: Metaspace

These percentages represent the "utilization" (used space) as a percentage of the "current capacity" (committed space). For example, if O = 75.21, it means that 75.21% of the committed Old Generation heap space is currently in use.

The Old Generation Only version specifically focuses on the "O" column, which provides a more stable metric for monitoring and alerting.

## Creating an Automated Installation Script

For easier deployment, you can create a simple batch file (`install.bat`) with the following content:

```batch
@echo off
echo Installing Java Heap Monitor...

:: Create installation directory
mkdir C:\JavaHeapMonitor
echo Created installation directory

:: Copy files
copy /Y *.ps1 C:\JavaHeapMonitor\
copy /Y *.bat C:\JavaHeapMonitor\
copy /Y *.json C:\JavaHeapMonitor\
copy /Y *.md C:\JavaHeapMonitor\
echo Copied files to installation directory

:: Create logs directory
mkdir C:\JavaHeapMonitor\Logs
echo Created logs directory

echo Installation complete!
echo Please review and update the configuration file at C:\JavaHeapMonitor\java_heap_monitor_config.json
pause
```

Place this batch file in the same directory as your installation files and run it with administrator privileges.
