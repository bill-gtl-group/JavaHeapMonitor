# Java Heap Monitor - Actual Usage Version

This version of the Java Heap Monitor is specifically designed to measure the actual heap usage (used bytes) rather than the percentage of committed heap space.

## The Problem

The original Java Heap Monitor and the Old Generation Only version both use `jstat -gcutil` which reports utilization percentages. These percentages represent the "used" portion of the heap as a percentage of the "committed" portion for each generation.

This can lead to discrepancies between what the monitor reports and what other monitoring tools show. For example:

- If the JVM has a large committed heap space but is only using a small portion of it, the actual usage might be low (e.g., 14% of total available memory)
- However, the `jstat -gcutil` command might report a high percentage (e.g., 80%) because it's measuring the used portion as a percentage of the committed portion, not the total available memory

## The Solution

This version uses `jstat -gc` instead, which provides the actual sizes (in KB) of the used and committed spaces for each generation. It then:

1. Calculates the total heap used by summing the used spaces across all generations
2. Calculates the total heap capacity by summing the committed spaces
3. Computes the actual usage percentage as `(total used / total capacity) * 100`

This provides a more accurate representation of the actual heap usage that aligns better with what other monitoring tools report.

## Key Features

- Reports actual heap usage in KB and as a percentage
- Logs both the actual usage and the Old Generation usage for comparison
- Includes all the enhancements from the fixed version:
  - External configuration file
  - Alert retry logic
  - Alert throttling
  - Single normal alert
  - Configuration reloading
  - Debug mode

## Usage

Run the monitor using the provided batch file:

```
run_actual_usage_monitor.bat
```

Or directly with PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Develop\Java Heap Monitor\java_heap_memory_monitor_actual_usage.ps1"
```

## Configuration

The monitor uses the same configuration file (`java_heap_monitor_config.json`) as the other versions. The threshold setting in the configuration file now applies to the actual heap usage percentage rather than the Old Generation usage percentage.

## Log Output

The monitor logs both metrics for comparison:

```
2025-05-16 12:00:00 - Actual heap usage: 14.25% (Used: 512000 KB, Capacity: 3592000 KB)
2025-05-16 12:00:00 - Old Generation usage: 75.50% (Used: 453000 KB, Capacity: 600000 KB)
```

This allows you to see both the actual heap usage and the Old Generation usage side by side.

## When to Use This Version

Use this version when:

- You need to monitor the actual heap usage rather than just the Old Generation
- You're experiencing discrepancies between the Java Heap Monitor and other monitoring tools
- You want to avoid false alerts caused by high Old Generation percentages when the actual heap usage is low
