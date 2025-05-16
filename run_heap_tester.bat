@echo off
echo Java Heap Tester
echo ===============

echo Compiling HeapTester.java...
javac HeapTester.java

if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed!
    pause
    exit /b 1
)

echo Starting HeapTester with 512MB max heap size...
java -Xmx512m HeapTester

pause
