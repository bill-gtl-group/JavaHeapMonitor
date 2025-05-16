# Java Heap Monitor - JMX Version

This document describes the JMX version of the Java Heap Memory Monitor, which is an alternative implementation that uses JMX (Java Management Extensions) tools instead of jstat to monitor Java heap usage.

## Overview

The JMX version of the Java Heap Memory Monitor uses the following tools to monitor Java heap usage:

1. `jcmd` - A diagnostic command tool that can be used to send diagnostic command requests to a running Java Virtual Machine (JVM)
2. `jinfo` - A tool that can be used to query the JVM system properties and command-line flags

This version is particularly useful when:

- You encounter permission issues with jstat
- You need to monitor Java processes running under different user accounts
- You want more detailed heap information than what jstat provides

## How It Works

The JMX version of the Java Heap Memory Monitor works as follows:

1. It detects Java processes running on the system
2. It uses `jcmd` to get heap information from the Java process
3. If `jcmd` fails, it falls back to using `jinfo` to get heap information
4. It calculates the actual heap usage percentage based on the used and total heap sizes
5. It sends alerts when the heap usage exceeds the configured threshold

## Features

- **Flexible Process Detection**: Detects Java processes with names matching "java", "HeapTester*", or "*java*"
- **Multiple Monitoring Methods**: Uses both `jcmd` and `jinfo` for better compatibility
- **Detailed Logging**: Logs detailed information about the monitoring process, including command outputs and error messages
- **Email Alerts**: Sends email alerts when heap usage exceeds the configured threshold
- **Alert Throttling**: Prevents alert flooding by throttling alerts based on a configurable interval
- **Configuration Reloading**: Automatically reloads the configuration file at configurable intervals

## Requirements

- Windows operating system
- PowerShell 5.0 or later
- Java Development Kit (JDK) installed (for jcmd and jinfo tools)
- SMTP server for sending email alerts

## Configuration

The JMX version of the Java Heap Memory Monitor uses the same configuration file as the other versions:

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

Note that even though this version doesn't use jstat, the `jstatPath` configuration is still used to determine the location of the JDK bin directory, where jcmd and jinfo are located.

## Usage

To run the JMX version of the Java Heap Memory Monitor:

1. Make sure the configuration file (`java_heap_monitor_config.json`) is in the same directory as the script
2. Run the `run_jmx_monitor.bat` batch file

The monitor will start and begin logging to the configured log directory.

## Troubleshooting

If you encounter issues with the JMX version of the Java Heap Memory Monitor:

1. Check the logs for error messages
2. Make sure the JDK bin directory is in the system PATH
3. Make sure the Java process you're trying to monitor is running
4. Try running the script with administrator privileges if you're still having permission issues

## Comparison with Other Versions

| Feature | JMX Version | Actual Usage Version | Fixed Version |
|---------|-------------|----------------------|---------------|
| Monitoring Method | jcmd, jinfo | jstat -gc | jstat -gcutil |
| Heap Usage Calculation | Used / Total | Used / Capacity | Weighted Average |
| Permission Requirements | Lower | Higher | Higher |
| Detailed Heap Information | Yes | Yes | No |
| Process Detection | Flexible | Flexible | Basic |

## Conclusion

The JMX version of the Java Heap Memory Monitor provides a more robust and flexible way to monitor Java heap usage, especially in environments where jstat may have permission issues or when monitoring Java processes running under different user accounts.
