@echo off
REM Universal C# Compiler with Auto .NET Framework Installation
REM By RadekCasual on github
setlocal enabledelayedexpansion

title Universal C# Compiler

echo.
echo ================================================
echo    Universal C# Compiler - v1.0
echo    Made by RadekCasual on github
echo ================================================
echo.

REM Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    set "ADMIN=false"
) else (
    set "ADMIN=true"
)

REM File selection function
echo Opening file selection window...
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'C# Files (*.cs)|*.cs|All Files (*.*)|*.*'; $f.Title = 'Wybierz plik C# do kompilacji'; if($f.ShowDialog() -eq 'OK') { $f.FileName } else { 'CANCEL' }" > temp_file.txt

set /p SELECTED_FILE=<temp_file.txt
del temp_file.txt >nul 2>&1

if "%SELECTED_FILE%"=="CANCEL" (
    echo No file selected. Job done.
    pause
    exit /b 1
)

if not exist "%SELECTED_FILE%" (
    echo The selected file does not exist: %SELECTED_FILE%
    pause
    exit /b 1
)

echo Selected file: %SELECTED_FILE%
echo.

REM Checking if .NET Framework is installed
echo Checking if .NET Framework is installed...
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1
if %errorLevel% neq 0 (
    echo .NET Framework 4.x is not installed or is an very old version.
    goto :install_dotnet
) else (
    echo  .NET Framework was found.
    goto :find_compiler
)

:install_dotnet
echo.
echo .NET Framework requires installation, please wait...
if "%ADMIN%"=="false" (
    echo Administrator privileges required to install .NET Framework
    echo Rerun this script as administrator.
    pause
    exit /b 1
)

echo Downloading .NET Framework 4.8.1...
powershell -Command "try { $wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://go.microsoft.com/fwlink/?LinkId=2203304', '%TEMP%\dotnet-installer.exe'); Write-Host 'Download complete.' } catch { Write-Host 'Download error:' $_.Exception.Message; exit 1 }"

if not exist "%TEMP%\dotnet-installer.exe" (
    echo Failed to download the .NET Framework installer.
    pause
    exit /b 1
)

echo Installing .NET Framework
echo This may take a few minutes...
"%TEMP%\dotnet-installer.exe" /quiet /norestart

if %errorLevel% equ 0 (
    echo .NET Framework installed successfully!
) else if %errorLevel% equ 1641 (
    echo .NET Framework installed. Restart required.
) else if %errorLevel% equ 3010 (
    echo .NET Framework installed. Restart required.
) else (
    echo Error installing .NET Framework. Error code: %errorLevel%
    pause
    exit /b 1
)

REM Cleaning the temporary file
del "%TEMP%\dotnet-installer.exe" >nul 2>&1

:find_compiler
echo.
echo Searching C# compiler...

REM List of possible compiler locations
set "COMPILER_FOUND=false"
set "COMPILER_PATH="

REM Visual Studio 2022
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

REM Visual Studio 2019
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe" (
    set "COMPILER_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

REM .NET Framework compilers
if exist "%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "COMPILER_PATH=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if exist "%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "COMPILER_PATH=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    set "COMPILER_FOUND=true"
    goto :compile
)

if "%COMPILER_FOUND%"=="false" (
    echo C# compiler not found!
    echo Install Visual Studio or Build Tools for Visual Studio.
    echo Link: https://visualstudio.microsoft.com/downloads/
    pause
    exit /b 1
)

:compile
echo Compiler found: %COMPILER_PATH%
echo.

REM Preparing file names
for %%F in ("%SELECTED_FILE%") do (
    set "SOURCE_DIR=%%~dpF"
    set "SOURCE_NAME=%%~nF"
    set "OUTPUT_FILE=%%~dpnF.exe"
)

echo Compiling: %SOURCE_NAME%.cs
echo Path: %SOURCE_DIR%
echo Output file: %OUTPUT_FILE%
echo.

REM Compilation
"%COMPILER_PATH%" /target:exe /platform:anycpu /optimize+ /out:"%OUTPUT_FILE%" "%SELECTED_FILE%"

if %errorLevel% equ 0 (
    echo.
    echo ================================================
    echo    COMPILATION COMPLETED SUCCESSFULLY!
    echo ================================================
    echo.
    echo Executable file: %OUTPUT_FILE%
    
    REM Checking the file size
    if exist "%OUTPUT_FILE%" (
        for %%A in ("%OUTPUT_FILE%") do (
            echo File Size: %%~zA byte
        )
    )
    
    echo.
    set /p RUN_CHOICE=Do you want to run the compiled program? (y/n): 
    if /i "!RUN_CHOICE!"=="y" (
        echo Starting program...
        start "" "%OUTPUT_FILE%"
    )

) else (
    echo.
    echo ================================================
    echo    COMPILATION ERROR!
    echo ================================================
    echo.
    echo Please check the source code and try again.
    echo Error code: %errorLevel%
)

echo.
echo Thanks for using the Universal C# Compiler!
pause
exit /b 0