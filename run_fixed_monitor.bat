@echo off
echo Java Heap Monitor - Fixed Version
echo This script uses the improved heap usage calculation method
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0java_heap_memory_monitor_fixed.ps1"
