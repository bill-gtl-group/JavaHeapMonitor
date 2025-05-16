# Java Heap Monitor - WMI Version

This document describes the WMI version of the Java Heap Memory Monitor, which is an alternative implementation that uses Windows Management Instrumentation (WMI) to monitor Java heap usage.

## Overview

The WMI version of the Java Heap Memory Monitor uses Windows Management Instrumentation (WMI) to monitor Java processes and their memory usage. This version is particularly useful when:

- You encounter permission issues with jstat or JMX tools
- You need to monitor Java processes running under different user accounts
- You want more detailed process information than what jstat or JMX provides

## How It Works

The WMI version of the Java Heap Memory Monitor works as follows:

1. It detects Java processes running on the system using Get-Process
2. It uses WMI (Get-WmiObject) to get detailed process information
3. It uses Get-Process to get memory usage information for the Java process
4. It calculates the memory usage percentage based on the private memory size
5. It sends alerts when the memory usage exceeds the configured threshold

## Features

- **Flexible Process Detection**: Detects Java processes with names matching "java", "HeapTester*", or "*java*"
- **Detailed Process Information**: Provides detailed information about the Java process, including command line, parent process, and loaded modules
- **Memory Usage Monitoring**: Monitors various memory metrics including working set, private memory, and virtual memory
- **Email Alerts**: Sends email alerts when memory usage exceeds the configured threshold
- **Alert Throttling**: Prevents alert flooding by throttling alerts based on a configurable interval
- **Configuration Reloading**: Automatically reloads the configuration file at configurable intervals

## Requirements

- Windows operating system
- PowerShell 5.0 or later
- SMTP server for sending email alerts

## Configuration

The WMI version of the Java Heap Memory Monitor uses the same configuration file as the other versions:

```json
{
    "threshold": 70,
    "emailTo": "admin@example.com",
    "emailFrom": "alerts@example.com",
    "smtpServer": "smtp.example.com",
    "smtpPort": 25,
    "javaProcessName": "java",
    "logDirectory": "C:\\JavaHeapMonitor\\Logs",
    "jstatPath": "C:\\Program Files\\Java\\jdk-17.0.4.1\\bin\\jstat.exe",
    "sleepInterval": 10,
    "manualHostname": "SERVER01",
    "alertRetryCount": 3,
    "alertThrottleMinutes": 60,
    "configReloadInterval": 300,
    "debugMode": false
}
```

Note that even though this version doesn't use jstat, the `jstatPath` configuration is still used to determine the location of the JDK bin directory.

## Usage

To run the WMI version of the Java Heap Memory Monitor:

1. Make sure the configuration file (`java_heap_monitor_config.json`) is in the same directory as the script
2. Run the `run_wmi_monitor.bat` batch file

The monitor will start and begin logging to the configured log directory.

## Troubleshooting

If you encounter issues with the WMI version of the Java Heap Memory Monitor:

1. Check the logs for error messages
2. Make sure the Java process you're trying to monitor is running
3. Try running the script with administrator privileges if you're still having permission issues

## Comparison with Other Versions

| Feature | WMI Version | JMX Version | Actual Usage Version | Fixed Version |
|---------|-------------|-------------|----------------------|---------------|
| Monitoring Method | WMI | jcmd, jinfo | jstat -gc | jstat -gcutil |
| Heap Usage Calculation | Private Memory / Total Physical Memory | Used / Total | Used / Capacity | Weighted Average |
| Permission Requirements | Lower | Medium | Higher | Higher |
| Detailed Process Information | Yes | No | No | No |
| Process Detection | Flexible | Flexible | Flexible | Basic |

## Advantages of the WMI Version

The WMI version of the Java Heap Memory Monitor has several advantages over the other versions:

1. **Lower Permission Requirements**: WMI can often access processes that jstat and JMX tools cannot, especially when processes are running under different user accounts.
2. **More Detailed Process Information**: The WMI version provides detailed information about the Java process, including command line, parent process, and loaded modules.
3. **Multiple Memory Metrics**: The WMI version monitors various memory metrics including working set, private memory, and virtual memory, giving you a more complete picture of the Java process's memory usage.
4. **No JDK Dependency**: The WMI version does not require the JDK to be installed, as it uses built-in Windows tools to monitor the Java process.

## Conclusion

The WMI version of the Java Heap Memory Monitor provides a more robust and flexible way to monitor Java heap usage, especially in environments where jstat and JMX tools may have permission issues or when monitoring Java processes running under different user accounts.
