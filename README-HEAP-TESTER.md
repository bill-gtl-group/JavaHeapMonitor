# Java Heap Tester

A simple GUI application for testing the Java Heap Monitor by controlling heap memory usage.

## Overview

The Java Heap Tester is a graphical tool that allows you to:

- Allocate memory in configurable block sizes
- Release memory in controlled amounts
- Monitor the current heap usage in real-time
- Test the Java Heap Monitor's response to different memory usage levels

This tool is particularly useful for testing the different versions of the Java Heap Monitor to see how they respond to various heap usage scenarios.

## Features

- **Real-time Heap Usage Display**: Shows current heap usage in MB and as a percentage
- **Configurable Memory Allocation**: Slider to control the size of memory blocks (10MB to 100MB)
- **Memory Control**: Buttons to allocate, release, or release all memory
- **Visual Feedback**: Progress bar changes color based on heap usage level (green, yellow, red)
- **Automatic Updates**: Heap usage display updates every second

## Usage

### Running the Application

1. Make sure you have Java Development Kit (JDK) installed
2. Run the provided batch file:
   ```
   run_heap_tester.bat
   ```

This will compile the Java source code and run the application with a 512MB maximum heap size.

### Using the Application

1. **View Current Heap Status**: The top panel shows the current heap usage
2. **Set Allocation Size**: Use the slider to set the size of memory blocks (10MB to 100MB)
3. **Allocate Memory**: Click "Allocate Memory" to add memory blocks of the selected size
4. **Release Memory**: Click "Release Memory" to free memory blocks of the selected size
5. **Release All**: Click "Release All" to free all allocated memory

### Testing the Java Heap Monitor

To test the Java Heap Monitor with this tool:

1. Start one of the Java Heap Monitor versions in a separate terminal:
   ```
   run_fixed_monitor.bat
   ```
   or
   ```
   run_old_gen_only_monitor.bat
   ```
   or
   ```
   run_actual_usage_monitor.bat
   ```

2. Run the Heap Tester:
   ```
   run_heap_tester.bat
   ```

3. Use the Heap Tester to allocate memory to different levels (e.g., 10%, 50%, 75%, 90%)
4. Observe how the different Java Heap Monitor versions respond to these changes

## Comparing Monitor Versions

This tool is particularly useful for comparing the behavior of the different Java Heap Monitor versions:

- **Original Version**: Monitors only Old Generation heap usage as a percentage of committed space
- **Fixed Version**: Monitors both Young and Old generations as a percentage of committed space
- **Old Generation Only Version**: Focuses only on Old Generation heap usage as a percentage of committed space
- **Actual Usage Version**: Measures the actual heap usage (used bytes) as a percentage of total capacity

By using the Heap Tester, you can see how these different versions report the same memory usage scenario, helping you choose the most appropriate version for your needs.

## Customizing the Heap Size

If you want to test with a different maximum heap size, you can modify the `run_heap_tester.bat` file and change the `-Xmx512m` parameter to a different value, such as `-Xmx256m` for 256MB or `-Xmx1g` for 1GB.
