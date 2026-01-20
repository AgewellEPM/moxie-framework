@echo off
REM SimpleMoxieSwitcher Windows Build Script (CMD version)
REM Batch script to build the application

setlocal enabledelayedexpansion

echo SimpleMoxieSwitcher Windows Build Script
echo ========================================
echo.

REM Check for .NET SDK
echo Checking .NET SDK...
dotnet --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: .NET SDK not found. Please install .NET 8.0 SDK.
    exit /b 1
)
for /f "tokens=*" %%i in ('dotnet --version') do set DOTNET_VERSION=%%i
echo Found .NET SDK version: %DOTNET_VERSION%
echo.

REM Parse command line arguments
set CONFIGURATION=Release
set CLEAN=0
set RUN=0

:parse_args
if "%1"=="" goto :build
if /i "%1"=="Debug" set CONFIGURATION=Debug
if /i "%1"=="Release" set CONFIGURATION=Release
if /i "%1"=="clean" set CLEAN=1
if /i "%1"=="run" set RUN=1
shift
goto :parse_args

:build
REM Clean if requested
if %CLEAN%==1 (
    echo Cleaning previous builds...
    if exist SimpleMoxieSwitcher\bin rmdir /s /q SimpleMoxieSwitcher\bin
    if exist SimpleMoxieSwitcher\obj rmdir /s /q SimpleMoxieSwitcher\obj
    dotnet clean
    echo Clean completed.
    echo.
)

REM Restore NuGet packages
echo Restoring NuGet packages...
dotnet restore
if errorlevel 1 (
    echo ERROR: Failed to restore NuGet packages.
    exit /b 1
)
echo NuGet packages restored.
echo.

REM Build the solution
echo Building solution...
echo Configuration: %CONFIGURATION%
dotnet build SimpleMoxieSwitcher.sln --configuration %CONFIGURATION% --verbosity minimal
if errorlevel 1 (
    echo ERROR: Build failed.
    exit /b 1
)
echo Build completed successfully.
echo.

REM Run if requested
if %RUN%==1 (
    echo Starting application...
    set EXE_PATH=SimpleMoxieSwitcher\bin\%CONFIGURATION%\net8.0-windows10.0.19041.0\SimpleMoxieSwitcher.exe
    if exist !EXE_PATH! (
        start "" "!EXE_PATH!"
        echo Application started.
    ) else (
        echo ERROR: Executable not found at !EXE_PATH!
        exit /b 1
    )
)

echo.
echo Build script completed successfully!
echo ========================================
endlocal