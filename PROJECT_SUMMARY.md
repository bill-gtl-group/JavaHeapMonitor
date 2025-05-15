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

- `java_heap_memory_monitor.ps1` - The original PowerShell script
- `java_heap_memory_monitor_fixed.ps1` - Fixed version with improved heap usage calculation
- `java_heap_monitor_config.json` - Configuration file
- `README.md` - Documentation
- `.gitignore` - Git ignore file
- GitHub integration scripts:
  - `push_to_github.bat` - Main script for GitHub integration
  - `setup_github_repo.bat` - Manual Git setup script
  - `create_github_repo.ps1` - Automated GitHub repository creation script
  - `github_token_guide.md` - Guide for GitHub tokens
  - `create_repo.ps1` - Script used to create the repository
- Utility scripts:
  - `run_fixed_monitor.bat` - Batch file to run the fixed monitor script

## How to Use

1. **Running the Monitor**:
   
   Original version:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor.ps1"
   ```
   
   Fixed version (recommended):
   ```
   run_fixed_monitor.bat
   ```
   or
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor_fixed.ps1"
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

## Heap Usage Calculation

The original script used only the Old Generation space utilization to determine heap usage, which could lead to discrepancies when compared with Java monitoring tools. The fixed version (`java_heap_memory_monitor_fixed.ps1`) calculates a more accurate total heap usage by:

1. Parsing all heap generation data from jstat output (Young and Old generations)
2. Calculating a weighted average to better represent total heap usage
3. Logging both individual generation usage and the calculated total for comparison

This provides a more accurate representation of the actual Java heap memory usage and aligns better with what Java monitoring tools display.

## Next Steps

Potential future enhancements:
- Add a web-based dashboard for monitoring
- Implement more advanced alerting mechanisms
- Add support for monitoring multiple Java processes
- Create a Windows service for continuous monitoring
- Further refine the heap usage calculation for even greater accuracy
