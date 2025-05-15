# Java Heap Monitor - Project Summary

## Project Overview

The Java Heap Monitor is a PowerShell-based tool that monitors Java heap memory usage and sends alerts when thresholds are exceeded. This project has been enhanced with several new features and is now available on GitHub.

## Enhancements Made

1. **External Configuration File**: Added `java_heap_monitor_config.json` with all configurable settings
2. **Alert Improvements**:
   - Added retry count for failed alert attempts
   - Implemented alert throttling (1 alert per hour)
   - Ensured "good" alerts are sent only once when system returns to normal
3. **Configuration Reloading**: Added functionality to periodically reload the configuration file
4. **Debug Mode**: Added option to reload configuration on every loop iteration for testing

## GitHub Repository

The project has been successfully pushed to GitHub and is available at:

**Repository URL**: https://github.com/bill-gtl-group/JavaHeapMonitor

All project files are now version-controlled and can be cloned, forked, or downloaded from GitHub.

## Project Files

- `java_heap_memory_monitor.ps1` - The main PowerShell script
- `java_heap_monitor_config.json` - Configuration file
- `README.md` - Documentation
- `.gitignore` - Git ignore file
- GitHub integration scripts:
  - `push_to_github.bat` - Main script for GitHub integration
  - `setup_github_repo.bat` - Manual Git setup script
  - `create_github_repo.ps1` - Automated GitHub repository creation script
  - `github_token_guide.md` - Guide for GitHub tokens
  - `create_repo.ps1` - Script used to create the repository

## How to Use

1. **Running the Monitor**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor.ps1"
   ```

2. **Modifying Configuration**:
   - Edit `java_heap_monitor_config.json` to change settings
   - The script will automatically reload the configuration based on the `configReloadInterval` setting

3. **GitHub Integration**:
   - The project is already on GitHub at https://github.com/bill-gtl-group/JavaHeapMonitor
   - To clone the repository to another machine:
     ```
     git clone https://github.com/bill-gtl-group/JavaHeapMonitor.git
     ```

## Next Steps

Potential future enhancements:
- Add a web-based dashboard for monitoring
- Implement more advanced alerting mechanisms
- Add support for monitoring multiple Java processes
- Create a Windows service for continuous monitoring
