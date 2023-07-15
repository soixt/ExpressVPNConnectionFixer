@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

REM Initialize command array
setlocal enabledelayedexpansion
set "commands[0]=ipconfig /flushdns"
set "commands[1]=ipconfig /registerdns"
set "commands[2]=ipconfig /release"
set "commands[3]=ipconfig /renew"
set "commands[4]=netsh winsock reset"
set "descriptions[0]=Flush DNS cache"
set "descriptions[1]=Register DNS"
set "descriptions[2]=Release IP address"
set "descriptions[3]=Renew IP address"
set "descriptions[4]=Reset Winsock"

REM Initialize status array
for /L %%i in (0,1,4) do (
    set "status[%%i]=Not executed"
)

REM Execute commands and update status
for /L %%i in (0,1,4) do (
    call :RunCommand %%i
)

REM Display command summary as a list
echo.
echo Command Summary:
for /L %%i in (0,1,4) do (
    set "command=!commands[%%i]!"
    set "description=!descriptions[%%i]!"
    echo - Command: !command!
    echo   Description: !description!
    if !errorlevel! equ 0 (
        echo   Status: ^(Success^)
    ) else (
        echo   Status: ^(Failed^)
    )
    echo.
)

REM Prompt for restart or exit
echo To apply the changes completely, it is recommended to restart the PC.
echo Press 'r' to restart the PC or 'c' to exit the program.
choice /c rc /n /m "Press [R / C]: "

if errorlevel 2 (
    schtasks /create /sc once /tn "RestartPC" /tr "shutdown /r /t 0" /ru SYSTEM
    schtasks /run /tn "RestartPC"
)

exit

:RunCommand
REM Run a command and update its status
setlocal enabledelayedexpansion
set "command=!commands[%1]!"
set "description=!descriptions[%1]!"
echo.
echo Executing command: !command!
echo Description: !description!
!command!
if !errorlevel! equ 0 (
    set "status[%1]=Success"
) else (
    set "status[%1]=Failed"
)
endlocal
goto :EOF
