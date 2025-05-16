# Java Heap Monitor - Enhanced Version

This is an enhanced version of the Java Heap Memory Monitor with additional features for better monitoring and alerting.

## GitHub Repository

This project is available on GitHub at: https://github.com/bill-gtl-group/JavaHeapMonitor

### Git Operations

The Git tools have been moved to a central location at `C:\Develop\git_tools`. To perform Git operations for this project:

1. Run `git_operations.bat` in the Java Heap Monitor directory
2. Choose from the available options:
   - Push changes to GitHub
   - Set up a new GitHub repository
   - Create a GitHub repository automatically (requires GitHub token)

The batch file will use the Git tools from the central location, making it easier to maintain and update these tools across multiple projects.

## New Features

1. **External Configuration File**: All settings are now stored in a JSON configuration file (`java_heap_monitor_config.json`) that can be modified without changing the script.

2. **Alert Retry Logic**: The script will now retry sending alerts if the initial attempt fails, up to the configured number of retries.

3. **Alert Throttling**: Alerts are now throttled to prevent alert flooding. By default, only one alert will be sent per hour.

4. **Single Normal Alert**: When the system returns to normal, only one "good" alert will be sent.

5. **Configuration Reloading**: The script periodically reloads the configuration file, allowing for changes to be applied without restarting the monitor.

6. **Debug Mode**: A debug mode is available that reloads the configuration on every loop iteration, useful for testing configuration changes.

## Configuration Options

The configuration file (`java_heap_monitor_config.json`) contains the following settings:

| Setting | Description | Default Value |
|---------|-------------|---------------|
| threshold | Percentage of heap memory usage to trigger alert | 70 |
| emailTo | Email address to send alerts to | ahplau@hkma.gov.hk |
| emailFrom | Email address to send alerts from | brdruat-alert@easynet.com.hk |
| smtpServer | SMTP server for sending email | mail.easynet.com.hk |
| smtpPort | SMTP server port | 2525 |
| javaProcessName | Name of the Java process to monitor | java |
| logDirectory | Directory for the log files | C:\JavaHeapMonitor\Logs |
| jstatPath | Full path to jstat.exe | C:\Program Files\Java\jdk-17.0.4.1\bin\jstat.exe |
| sleepInterval | Sleep interval in seconds | 10 |
| manualHostname | Hostname to include in alerts | BRDRUATWB01 |
| alertRetryCount | Number of times to retry sending an alert | 3 |
| alertThrottleMinutes | Minimum time between alerts in minutes | 60 |
| configReloadInterval | Interval to reload configuration in seconds | 300 |
| debugMode | Enable debug mode (reload config every loop) | false |

## Installation

1. Run the `update_java_heap_monitor.bat` script to:
   - Back up the original script
   - Copy the updated script to the Java Heap Monitor directory
   - Copy the configuration file to the Java Heap Monitor directory

2. Review and adjust the configuration file as needed.

## Usage

The script can be run with the default configuration file:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor.ps1"
```

Or with a custom configuration file:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor.ps1" -ConfigFilePath "path\to\custom_config.json"
```

## Troubleshooting

- Check the log files in the configured log directory for detailed information about the script's operation.
- If alerts are not being sent, verify the SMTP server settings and connectivity.
- If the script is not detecting Java processes, ensure the correct Java process name is configured.
- For debugging configuration changes, set `debugMode` to `true` in the configuration file.
