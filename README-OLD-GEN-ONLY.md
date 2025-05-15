# Java Heap Monitor - Old Generation Only

This is a modified version of the Java Heap Memory Monitor that only reports the Old Generation heap usage, not the combined heap usage (Young + Old generations).

## Why Old Generation Only?

In Java memory management, there are two main heap areas:

1. **Young Generation**: Contains newly created objects. This area is subject to frequent garbage collection and rapid changes in memory usage.

2. **Old Generation**: Contains long-lived objects that have survived multiple garbage collection cycles. This area is more stable and typically grows more slowly.

The original Java Heap Monitor script (`java_heap_memory_monitor.ps1`) only monitored the Old Generation usage, while the fixed version (`java_heap_memory_monitor_fixed.ps1`) calculated a weighted average of both Young and Old generations.

This version (`java_heap_memory_monitor_old_gen_only.ps1`) returns to monitoring only the Old Generation usage, which may provide a more stable and meaningful metric for alerting purposes, as the Young Generation usage can fluctuate rapidly due to frequent garbage collection.

## How It Works

The script uses the `jstat -gcutil` command to get heap utilization percentages. It specifically looks at the "O" column (index 3), which represents the Old Generation space utilization as a percentage of the space's current capacity.

This percentage represents the "heap used" portion of the Old Generation, not the "heap committed" (total allocated) portion.

## Usage

You can run the script using the provided batch file:

```
run_old_gen_only_monitor.bat
```

Or directly with PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor_old_gen_only.ps1"
```

## Configuration

The script uses the same configuration file (`java_heap_monitor_config.json`) as the other versions. You can modify the settings in this file to adjust the threshold, email settings, and other parameters.

## Comparison with Other Versions

1. **Original Script (`java_heap_memory_monitor.ps1`)**:
   - Monitors only Old Generation usage
   - Simple and focused

2. **Fixed Script (`java_heap_memory_monitor_fixed.ps1`)**:
   - Calculates a weighted average of Young and Old generations
   - More comprehensive but may be affected by Young Generation fluctuations

3. **Old Generation Only Script (`java_heap_memory_monitor_old_gen_only.ps1`)**:
   - Monitors only Old Generation usage like the original
   - Includes all the enhancements from the fixed version (alert retry, throttling, etc.)
   - Provides clearer messaging that it's monitoring Old Generation only

## When to Use This Version

Use this version when:

1. You want to focus on Old Generation usage, which is typically more stable and indicative of potential memory leaks or issues
2. You want to avoid false alerts caused by normal fluctuations in Young Generation usage
3. You want to monitor the "heap used" portion specifically, not the "heap committed" portion
