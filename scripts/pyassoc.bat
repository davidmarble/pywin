:: Usage:
::     `pyassoc [original] [all_users]`

:: Default effect
::     The .py extension will be registered to run with `%pyhome%\pywin.bat`.
::     By default this change is made in the registry to HKEY_CURRENT_USER,
::     overriding any system-wide setting.
::
::     Note that registry settings have no effect on python under MSYS.

:: Parameters:
::     original - restore .py to launch with %pyhome%python.exe
::     all_users - if administrator, apply the change to HKEY_LOCAL_MACHINE.
::                 Note that other users can override this with their own 
::                 HKEY_CURRENT_USER values.
::
:: The variable %pyhome% is set by the following order:
::     1. If the environment variable PYTHONHOME is set, use it.
::     2. If the environment variable DEFAULTPYTHON is set, use it.
::        This is set when you call `pywin setdefault <version>`,
::        but only lasts for the current session.
::     3. The path the `pyassoc.bat` script is in.

@echo off

if defined VIRTUAL_ENV (
    call "%VIRTUAL_ENV%\Scripts\deactivate.bat"
)

:: Set pyhome
if defined PYTHONHOME (
    set "pyhome=%PYTHONHOME%\"
    goto MAIN
)
if defined DEFAULTPYTHON (
    set "pyhome=%DEFAULTPYTHON%\"
    goto MAIN
)
set "pyhome=%~dp0"

SETLOCAL EnableDelayedExpansion

:MAIN
:: Detect if the user is running in elevated mode.
:: Relies on requiring admin privileges to read LOCAL SERVICE account reg key.
set admin=0
reg.exe query "HKEY_USERS\S-1-5-19" >NUL 2>NUL
@if errorlevel 0 (
    set admin=1
)

:: By default, make changes to HKCU
set hkcu=HKEY_CURRENT_USER\Software\Classes
echo.

:: If not admin
::     if user tried all_users param
::         exit with error
::     register under HKEY_CURRENT_USER
:: else
::     if 'all_users' specified as argument
::         unset on HKEY_CURRENT_USER
::         register under HKEY_LOCAL_MACHINE
::         run redundant assoc and ftype
::     else
::         register under HKEY_CURRENT_USER
if "%~1"=="original" (
    if admin==0 (
        if "%~2"=="all_users" (
            echo.    Please try again as an administrator if you'd like to use that option.
            goto :END
        )
        call :setToPythonEXE %hkcu%
    ) else (
        if "%~2"=="all_users" (
            call :removeKeys %hkcu%
            call :setToPythonEXE HKEY_LOCAL_MACHINE\Software\Classes
            REM These are redundant but allow `assoc` and `ftype` to return correct results
            assoc .pyc=Python.CompiledFile >NUL 2>NUL
            ftype Python.CompiledFile="%pyhome%python.exe" "%%1" %%* >NUL 2>NUL
            assoc .py=Python.File >NUL 2>NUL
            ftype Python.File="%pyhome%python.exe" "%%1" %%* >NUL 2>NUL
        ) else (
            call :setToPythonEXE %hkcu%
        )
    )
    echo.
    echo.    .py files will launch with "%pyhome%python.exe"
    goto :END
)

if admin==0 (
    if "%~1"=="all_users" (
        echo.    Please try again as an administrator if you'd like to use that option.
        goto :END
    )
    call :setToPywin
) else (
    if "%~1"=="all_users" (
        call :removeKeys %hkcu%
        call :setToPywin HKEY_LOCAL_MACHINE\Software\Classes
        REM These are redundant but allow `assoc` and `ftype` to return correct results
        assoc .pyc=Python.CompiledFile >NUL 2>NUL
        ftype Python.CompiledFile="%pyhome%pywin.bat" "%%1" %%* >NUL 2>NUL
        assoc .py=Python.File >NUL 2>NUL
        ftype Python.File="%pyhome%pywin.bat" "%%1" %%* >NUL 2>NUL
    ) else (
        call :setToPywin %hkcu%
    )
    echo.    .py files will launch with "%pyhome%pywin.bat"
)

:END
ENDLOCAL
set pyhome=
goto :EOF

:: =========
:: Functions
:: =========

:setToPywin
SETLOCAL
set "key=%~1"
reg.exe add "%key%\.py" /f /t REG_SZ /d "Python.File" >NUL 2>NUL
reg.exe add "%key%\Python.File" /f /t REG_SZ /d "Python File" >NUL 2>NUL
reg.exe add "%key%\Python.File\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\py.ico" >NUL 2>NUL
reg.exe add "%key%\Python.File\shell\Edit with IDLE\command" /f /t REG_SZ /d "\"%pyhome%pythonw.exe\" \"%pyhome%Lib\idlelib\idle.pyw\" -e \"%%1\"" >NUL 2>NUL
reg.exe add "%key%\Python.File\shell\open\command" /f /t REG_SZ /d "\"%pyhome%pywin.bat\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.File\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

reg.exe add "%key%\.pyc" /f /t REG_SZ /d "Python.CompiledFile" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile" /f /t REG_SZ /d "Python Compiled File" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\pyc.ico" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\shell\open\command" /f /t REG_SZ /d "\"%pyhome%pywin.bat\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

reg.exe add "%key%\.pyw" /f /t REG_SZ /d "Python.NoConFile" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile" /f /t REG_SZ /d "Python File (no console)" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\py.ico" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shell\Edit with IDLE\command" /f /t REG_SZ /d "\"%pyhome%pythonw.exe\" \"%pyhome%Lib\idlelib\idle.pyw\" -e \"%%1\"" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shell\open\command" /f /t REG_SZ /d "\"%pyhome%pyw.exe\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

@IF ERRORLEVEL 1 (
    echo.    FAILED to set .py files association.
) else (
    echo.    %key% python keys created successfully.
    echo.
)
ENDLOCAL
goto :EOF


:removeKeys
SETLOCAL EnableDelayedExpansion
set "key=%~1"
reg.exe delete "%key%\.py" /f >NUL 2>NUL
reg.exe delete "%key%\Python.File" /f >NUL 2>NUL
reg.exe delete "%key%\.pyc" /f >NUL 2>NUL
reg.exe delete "%key%\Python.CompiledFile" /f >NUL 2>NUL
reg.exe delete "%key%\.pyw" /f >NUL 2>NUL
reg.exe delete "%key%\Python.NoConFile" /f >NUL 2>NUL
echo.    %key% python keys removed.
ENDLOCAL
goto :EOF


:setToPythonEXE
SETLOCAL
set "key=%~1"
reg.exe add "%key%\.py" /f /t REG_SZ /d "Python.File" >NUL 2>NUL
reg.exe add "%key%\Python.File" /f /t REG_SZ /d "Python File" >NUL 2>NUL
reg.exe add "%key%\Python.File\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\py.ico" >NUL 2>NUL
reg.exe add "%key%\Python.File\shell\Edit with IDLE\command" /f /t REG_SZ /d "\"%pyhome%pythonw.exe\" \"%pyhome%Lib\idlelib\idle.pyw\" -e \"%%1\"" >NUL 2>NUL
reg.exe add "%key%\Python.File\shell\open\command" /f /t REG_SZ /d "\"%pyhome%python.exe\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.File\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

reg.exe add "%key%\.pyc" /f /t REG_SZ /d "Python.CompiledFile" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile" /f /t REG_SZ /d "Python Compiled File" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\pyc.ico" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\shell\open\command" /f /t REG_SZ /d "\"%pyhome%python.exe\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.CompiledFile\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

reg.exe add "%key%\.pyw" /f /t REG_SZ /d "Python.NoConFile" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile" /f /t REG_SZ /d "Python File (no console)" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\DefaultIcon" /f /t REG_SZ /d "%pyhome%DLLs\py.ico" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shell\Edit with IDLE\command" /f /t REG_SZ /d "\"%pyhome%pythonw.exe\" \"%pyhome%Lib\idlelib\idle.pyw\" -e \"%%1\"" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shell\open\command" /f /t REG_SZ /d "\"%pyhome%pyw.exe\" \"%%1\" %%*" >NUL 2>NUL
reg.exe add "%key%\Python.NoConFile\shellex\DropHandler" /f /t REG_SZ /d "{60254CA5-953B-11CF-8C96-00AA00B8708C}" >NUL 2>NUL

@IF ERRORLEVEL 1 (
    echo.    FAILED to set .py files association.
) else (
    echo.    %key% python keys created successfully.
    echo.
)
ENDLOCAL
goto :EOF
