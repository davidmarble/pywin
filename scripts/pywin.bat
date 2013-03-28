:: Usage options:
::     `pywin genlaunchers`
::         Search for python installations and create batch files in the same
::         directory where pywin is installed.
::
::         Note if you're using MSYS/MINGW32 this must be run again in the 
::         MSYS/MINGW32 shell, and you must have Windows >= Vista.
::
::     `pywin setdefault <version>`
::         Set the default python to <version>. Adds the right directory to
::         the front of the path. E.g. `pywin setdefault 3.3`.
::         This is only for the current cmd.exe session. If you want to change
::         the permanent default python, you need to change your system or
::         user path and make sure pywin is installed for that python version.
::
::         When calling this from MSYS/MINGW32, you must use a dot in front 
::         so the path changes propagate to your current shell.
::         E.g. `. pywin setdefault 3.3`
::
::     `pywin [<source file>]`
::         Launch the first version of python found among:
::         1. Any version specified after a #! in the first 2 lines of the source.
::            The interpreter will be invoked with any additional parameters.
::             examples:
::                 #! python3.3
::                 #! /usr/bin/python2.7 -v
::         2. If the environment variable VIRTUAL_ENV is set, use its python.exe.
::         3. If the environment variable PYTHONHOME is set, use its python.exe.
::         4. Default to the first python.exe found on the path.
::
::     `pywin -<version> [<source file>]`
::         Launch a specific version of python. E.g. `pywin -2.7`.
::         Note that specifying a version of python on the command line will 
::         override any version set in the header of the file.
::

@echo off

SETLOCAL EnableDelayedExpansion

for %%I in (charpos found pyreg pyver pyverline PY) do set %%I=

set "arg=%1"
set "pywindir=%~dp0"
for /f "usebackq tokens=*" %%a in (`python.exe -c "import sys;print(sys.exec_prefix)"`) do (
    set "PATHPYTHON=%%a"
)
if "%MSYSTEM%"=="MINGW32" (
    if "%MSYS_HOME%"=="" (
        echo.    MSYS_HOME must be defined, e.g. MSYS_HOME=/c/msysgit
        goto :EOF
    )
    set msys=%MSYS_HOME:/c/=C:\%
    set msys=!msys:/d/=D:\!
    set msys=!msys:/e/=E:\!
    set msys=!msys:/f/=F:\!
    set msys=!msys:/=\!
)

:: Find python installations in the registry and create shorcut launchers.
:: Check for 32-bit installations on 64-bit machines too.
if "%arg%"=="genlaunchers" (
    echo.
    if defined VIRTUAL_ENV (
        call "%VIRTUAL_ENV%\Scripts\deactivate.bat"
    )
    pushd "%~dp0"
    echo.    Generating launchers...
    echo.
    if "%MSYSTEM%"=="MINGW32" (
        del "%msys%\bin\python" >NUL 2>NUL
        del "%msys%\local\bin\python" >NUL 2>NUL
        mklink "%msys%\bin\python" "%PATHPYTHON%\python.exe" >NUL 2>NUL
        @if errorlevel 0 (
            echo.    %msys%\bin\python -^> %PATHPYTHON%\python.exe
        ) else (
            echo.  ERROR creating link: %msys%\local\bin\python -^> %PATHPYTHON%\python.exe
        )
        mklink "%msys%\local\bin\python" "%PATHPYTHON%\python.exe" >NUL 2>NUL
        @if errorlevel 0 (
            echo.    %msys%\local\bin\python -^> %PATHPYTHON%\python.exe
        ) else (
            echo.  ERROR creating link: %msys%\local\bin\python -^> %PATHPYTHON%\python.exe
        )
        REM Old way:
        REM echo #^^!/bin/sh > %MSYS_HOME%/bin/python
        REM echo python.exe $* >> %MSYS_HOME%/bin/python
        REM echo #^^!/bin/sh > %MSYS_HOME%/local/bin/python
        REM echo python.exe $* >> %MSYS_HOME%/local/bin/python
    )
    set "regkey=HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore"
    call :genLaunchers !regkey!
    set "regkey=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Python\PythonCore"
    call :genLaunchers !regkey!
    set "regkey=HKEY_CURRENT_USER\SOFTWARE\Python\PythonCore"
    call :genLaunchers !regkey!
    popd
    goto :EOF
)

:: Set the default python for this session.
if "%arg%"=="setdefault" (
    if defined VIRTUAL_ENV (
        call "%VIRTUAL_ENV%\Scripts\deactivate.bat"
    )
    set "arg=%2"
    if "!arg!"=="" (
        echo setdefault requires a python version, e.g. 2.7
        goto :EOF
    )
    pushd "%~dp0"
    if not "%DEFAULTPYTHON%"=="" (
        set "OLDDEFAULT=%DEFAULTPYTHON%"
    )
    REM Search for entered python and put it in front of the path
    for /f "usebackq tokens=*" %%a in (`dir /b`) do (
        if "%%a"=="python!arg!.bat" (
            for /f "usebackq tokens=*" %%f in (`findstr /n . python!arg!.bat ^| findstr /b 1:`) do (
                set found=1
                set "DEFAULTPYTHON=%%f"
                set "DEFAULTPYTHON=!DEFAULTPYTHON:~3,-15!"
            )
            echo.
            echo.    Setting default python to: !DEFAULTPYTHON!
        )
    )
    popd
    if "!found!"=="" (
        echo.
        echo.    Could not find %~dp0python!arg!.bat
        echo.    Perhaps you need to run `pywin genlaunchers`?
        goto :EOF
    )
    goto :NEWDEFAULT
)

:: If user passed in specific python version, find it and use it.
if not "%arg%"=="" (
    set "argprefix=%arg:~0,2%"
    if "!argprefix!"=="-2" (
        set "pyver=%arg:~1%"
        shift
        goto :EXPLICIT_SET
    )
    if "!argprefix!"=="-3" (
        set "pyver=%arg:~1%"
        shift
        goto :EXPLICIT_SET
    )
)

:HASHBANG
:: If script is being run and no specific version specified, check for #!
:: on the first two lines of the script and python command.
:: Argument may be enclosed in quotes
if not "%arg%"=="" (
    set "argsuffix=%arg:"=%"
    set "argsuffix=%argsuffix:~-3%"
    if "%argsuffix%"==".py" (
        for /f "usebackq tokens=*" %%f in (`findstr /n . %arg% ^| findstr /b 1:#!`) do (
            set "pyverline=%%f"
        )
        call :findStringFromEnd pyverline "python" charpos
        if not "!charpos!"=="" (
            goto :HASHBANG_SET
        )
        for /f "usebackq tokens=*" %%f in (`findstr /n . %arg% ^| findstr /b 2:#!`) do (
            set "pyverline=%%f"
        )
        call :findStringFromEnd pyverline "python" charpos
        if not "!charpos!"=="" (
            goto :HASHBANG_SET
        )
    )
)

:VIRTUALENV
:: Check if we have an active virtualenv
if defined VIRTUAL_ENV (
    set "PY=%VIRTUAL_ENV%\Scripts\python.exe"
    goto :RUN
)

:FIND_PYTHONHOME
:: Lastly, check for environment variable PYTHONHOME.
:: If it exists, use it, otherwise use the first python.exe found on the path.
if defined PYTHONHOME (
    set "PY=%PYTHONHOME%\python.exe"
    REM User may have put a virtualenv on the path
    if not exist !PY! (
        set "PY=%PYTHONHOME%\Scripts\python.exe"
    )
) else (
    set "PY=%PATHPYTHON%\python.exe"
)
goto :RUN

:EXPLICIT_SET
if not "!pyver!"=="" (
    set "PY=python!pyver!"
    goto :RUN
)

:HASHBANG_SET
:: Can't seem to find another way to get these two dynamic vars evaluated 
:: within the scope of 
set "PY=!pyverline:~%charpos%!"
goto :RUN

:RUN
set "args="
:concatArgs
if "%~1" neq "" (
  set args=%args% %1
  shift
  goto :concatArgs
)
if defined args set args=%args:~1%
ENDLOCAL & %PY% %args%
goto :EOF

:NEWDEFAULT
if "%OLDDEFAULT%"=="" (
    set "TEMPPATH=%DEFAULTPYTHON%;%PATH%"
) else (
    set "TEMPPATH=!PATH:%OLDDEFAULT%;=%DEFAULTPYTHON%;!"
)
ENDLOCAL & set "DEFAULTPYTHON=%DEFAULTPYTHON%" & set "PATH=%TEMPPATH%"
goto :EOF


:: =========
:: Functions
:: =========

:findStringFromEnd -- returns position of last occurrence of a string in another string, case sensitive, maximum string length is 1023 characters
:: Params:
::    %~1: in  - variable name of string to be searched
::    %~2: in  - string to be found
::    %~3: out - return variable name, will be set to position or undefined if 
::               string not found
:: Source: http://www.dostips.com
SETLOCAL EnableDelayedExpansion
set "pos="
set "str=!%~1!"
for /L %%a in (0,1,1023) do (
   set "s=!str:~%%a!"
   if /i "%~2!s:*%~2=!"=="!s!" set "pos=%%a"
)
ENDLOCAL & IF "%~3" NEQ "" SET "%~3=%pos%"
goto :EOF


:genLaunchers -- looks for python installations and creates Windows batch files and MSYS/MINGW32 symbolic links to launch each
::    %~1: in  - registry key where python installations can be found
set "rkey=%~1"
SETLOCAL EnableDelayedExpansion
reg.exe query %rkey% /s /f InstallPath >NUL 2>NUL
@if errorlevel 1 goto :EOF
for /f "usebackq tokens=*" %%a in (`reg.exe query %rkey% /s /f InstallPath`) do (
        set ln=%%a
        set ipath=!ln:InstallPath=!
        if not !ipath!==!ln! (
            set pyver=!ln:\InstallPath=!
            set pyver=!pyver:%rkey%\=!
            if "!pyver!"=="" (
                echo. ERROR: Found blank python version in registry key %rkey%
                goto :EOF
            )
            for /f "usebackq skip=2 tokens=3,*" %%b in (`reg.exe query !ln!`) do (
                set pyhome=%%b
                
                REM It'd be nice to use soft links to .exe files like this 
                REM commented code, but because of DLL issues this won't work.
                REM Also, mklink isn't in Windows XP. 
                REM For now just create batch files (below).

                REM del "python!pyver!.exe" >NUL 2>NUL
                REM mklink "python!pyver!.exe" "!pyhome!python.exe" >NUL 2>NUL
                REM @if errorlevel 0 (
                REM     echo.    %pywindir%python!pyver!.exe -^> !pyhome!python.exe
                REM ) else (
                REM     echo.  ERROR creating link: %pywindir%python!pyver!.exe -^> !pyhome!python.exe
                REM )

                REM Create batch file for Windows command prompt.
                echo @!pyhome!python.exe %%* > python!pyver!.bat
                echo.    %pywindir%python!pyver!.bat -^> !pyhome!python.exe

                if "%MSYSTEM%"=="MINGW32" (
                    REM Convert path to Windows-style from MSYS/MINGW32.
                    REM Add more drive letters if needed.
                    del "%msys%\local\bin\python!pyver!" >NUL 2>NUL
                    mklink "%msys%\local\bin\python!pyver!" "!pyhome!python.exe" >NUL 2>NUL
                    @if errorlevel 0 (
                        echo.    %msys%\local\bin\python!pyver! -^> !pyhome!python.exe
                    ) else (
                        echo.  ERROR creating link: %msys%\local\bin\python!pyver! -^> !pyhome!python.exe
                    )
                    
                    REM Create shell scripts primarily for setdefault use.
                    REM This is because it's impossible to read what windows 
                    REM symbolic links point to without other mingw32 utils
                    REM such as readlink.
                    set pyhome=!pyhome:C:=c!
                    set pyhome=!pyhome:D:=d!
                    set pyhome=!pyhome:E:=e!
                    set pyhome=!pyhome:F:=f!
                    set pyhome=/!pyhome:\=/!
                    echo #^^!/bin/sh > %msys%\local\bin\python!pyver!.sh
                    echo !pyhome!python.exe $* >> %msys%\local\bin\python!pyver!.sh
                    REM echo.    %msys%\local\bin\python!pyver! -^> !pyhome!python.exe

                    REM Add additional needed linked files
                    if "!pyver!"=="2.5" (
                        if not exist %msys%\local\bin\python25.dll (
                            mklink "%msys%\local\bin\python25.dll" "!pyhome!python25.dll" >NUL 2>NUL
                        )
                        if not exist %msys%\local\bin\msvcr71.dll (
                            mklink "%msys%\local\bin\msvcr71.dll" "!pyhome!msvcr71.dll" >NUL 2>NUL
                        )
                    )
                    if "!pyver!"=="3.0" (
                        if not exist %msys%\local\bin\python30.dll (
                            mklink "%msys%\local\bin\python30.dll" "!pyhome!python30.dll" >NUL 2>NUL
                        )
                        if not exist %msys%\local\bin\msvcr90.dll (
                            mklink "%msys%\local\bin\msvcr90.dll" "!pyhome!msvcr90.dll" >NUL 2>NUL
                        )
                    )
                    if "!pyver!"=="3.1" (
                        if not exist %msys%\local\bin\python31.dll (
                            mklink "%msys%\local\bin\python31.dll" "!pyhome!python31.dll" >NUL 2>NUL
                        )
                        if not exist %msys%\local\bin\msvcr90.dll (
                            mklink "%msys%\local\bin\msvcr90.dll" "!pyhome!msvcr90.dll" >NUL 2>NUL
                        )
                    )
                    if "!pyver!"=="3.2" (
                        if not exist %msys%\local\bin\python32.dll (
                            mklink "%msys%\local\bin\python32.dll" "!pyhome!python32.dll" >NUL 2>NUL
                        )
                        if not exist %msys%\local\bin\msvcr90.dll (
                            mklink "%msys%\local\bin\msvcr90.dll" "!pyhome!msvcr90.dll" >NUL 2>NUL
                        )
                    )
                    if "!pyver!"=="3.3" (
                        if not exist %msys%\local\bin\python33.dll (
                            mklink "%msys%\local\bin\python33.dll" "!pyhome!python33.dll" >NUL 2>NUL
                        )
                        if not exist %msys%\local\bin\msvcr100.dll (
                            mklink "%msys%\local\bin\msvcr100.dll" "!pyhome!msvcr100.dll" >NUL 2>NUL
                        )
                    )
                )
            )
        )
    )
)
ENDLOCAL
goto :EOF