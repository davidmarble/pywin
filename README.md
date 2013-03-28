# pywin
**pywin** is a lightweight python 2.5-3.3 launcher and switcher for Windows command line and MSYS/MINGW32. It's similar to the [py.exe launcher/switcher available in python 3.3](http://docs.python.org/3/using/windows.html#launcher), but written with basic Windows batch scripts and a helper shell script for MSYS/MINGW32 support. I use bash and command line shell tools from [msysgit](http://msysgit.github.com/), based on MSYS/MINGW32, to do most of my python development on windows.

**pywin** supports several useful features defined in [PEP 397](http://www.python.org/dev/peps/pep-0397/), such as command line conventions and hash bang #! python version headers in source files. While pywin lacks some of py.exe's features, it has the basics and a few extras of its own.


## Requirements
* Windows >= XP for command prompt support
* Windows >= Vista for MSYS/MINGW support (requires `mklink` for symbolic links)
* At least one installation of python 2.5 up to 3.3 (though it's not useful without at least two)
* easy_install, pip, or git


## Installation

- Make sure the main python installation you want pywin to live under is in the PATH.
- With multiple python installations, it's recommended to have only the main and Scripts directories from one installation in your PATH. For example, `C:\Python27;C:\Python27\Scripts`.

#### easy_install
```sh
easy_install pywin
```

#### pip
```sh
pip install pywin
```

### from source
```sh
git clone git://github.com/davidmarble/pywin.git
cd pywin
python setup.py install
```


## Getting Started
```sh
# Assuming pywin was installed with Python27

C:\>pyassoc

    HKEY_CURRENT_USER\Software\Classes python keys created successfully.

    .py files will launch with "C:\Python27\pywin.bat"

C:\>pywin genlaunchers

    Generating launchers...

    C:\Python27\python2.7.bat -> C:\Python27\python.exe
    C:\Python27\python2.6.bat -> C:\Python26\python.exe
    C:\Python27\python2.5.bat -> C:\Python25\python.exe
    C:\Python27\python3.0.bat -> C:\Python30\python.exe
    C:\Python27\python3.1.bat -> C:\Python31\python.exe
    C:\Python27\python3.2.bat -> C:\Python32\python.exe
    C:\Python27\python3.3.bat -> C:\Python33\python.exe

C:\>pywin               # launch first python found in PATH

C:\>pywin -2.7          # launch python 2.7

C:\>pywin setdefault 3.3

    Setting default python for active session to: 3.3
    C:\Python33;C:\Python33\Scripts -- now at front of PATH

# Create a test file with a specified python version in the header
C:\>echo #! /usr/bin/python2.7 > test.py
C:\>echo import sys;print("\n  %s"%sys.exec_prefix) >> test.py
C:\>test.py
  
  C:\Python27

C:\>pywin -3.2 test.py  # launch test.py with python 3.2

  C:\Python32

```

## Overview
**pywin** and its associated scripts are installed in the main directory of the active python version (e.g. C:\Python27). There's no need to install it under more than one version of python (if you do, you'll have to run `pywin genlaunchers` for each version you install it under). Make sure that this main python directory is always on the path. Alternatively you can move the included scripts to another directory in your path.

### Auto-generate version-specific launchers
**pywin** can create individual launch scripts to directly access core python installations (e.g. python2.7). These can be called directly with or without arguments from the Windows command prompt and MSYS/MINGW bash prompt. To use this feature, call

```sh
pywin genlaunchers
```

Launchers are created for all machine-wide and user-specific python installations found in the Windows registry. Windows batch files will be added to the directory where **pywin** is located. MSYS/MINGW32 relies on Windows links created programmatically with `mklink`, which is why you must have Windows >= Vista installed to make use of this project.

### Launch a specific python version using pywin
```sh
pywin -2.7  # launch python 2.7
pywin -3.2 test.py  # launch test.py with python 3.2
```

### Automatically invoke the right python with a script header
Add a directive to the first or second line of a source file to have the correct interpreter called. Currently this only supports python launchers created by the `pywin genlaunchers` command. To use this feature, you must associate the .py extension with pywin.bat using the included `pyassoc` utility. 

```sh
pyassoc
```


## pywin

**NOTE:** `pywin` commands work from both Windows command line and MSYS/MINGW32 shell.

### genlaunchers

```sh
pywin genlaunchers
```
Search for python installations and create batch files in the same
directory where pywin is installed.

Note if you're using MSYS/MINGW32 this must be run again in the 
MSYS/MINGW32 shell, and you must have Windows >= Vista.

### setdefault

```sh
pywin setdefault <version>
```
Set the default python to `<major>.<minor>` version. Adds the right 
python home directory and its associated Scripts directory to
the front of PATH. Removes any other existing reference to a python
Scripts directory in PATH.

Example
```sh
# Existing PATH: C:\Windows\System32;C:\Windows;C:\Python27;C:\Python27\Scripts

pywin setdefault 3.3

# New PATH: C:\Python33;C:\Python33\Scripts;C:\Windows\System32;C:\Windows;C:\Python27;
# C:\Python27 is preserved so that pywin can be found.

```` 

`pywin setdefault` is only active for the current cmd.exe 
(or MSYS/MINGW32 shell) session. If you want to change the  
default python permanently, you need to change your system or
user PATH and make sure pywin is installed for that python version.

When calling this from MSYS/MINGW32, enter a dot first so the changes 
to $PATH propagate to your active shell. E.g. `. pywin setdefault 3.3`

### launch with version and/or source

```sh
pywin [-<version>] [<source file>]
```

Launch either a specific `<major>.<minor>` version of python, 
or a source file, or both. Note that specifying a version of python 
on the command line will override any version in the header of the 
source file.

Example
```sh
# launch python 2.7
pywin -2.7

# launch test.py with python 3.2
pywin -3.2 test.py

# launch test.py according to Version Search Order below
pywin test.py
```

#### Version Search Order

**pywin** will launch the first version of python found among:

1. Any version specified after a #! in the first 2 lines of the source.
   The interpreter will be invoked with any additional parameters.
   
    examples:
   
        #! python3.3
        #! /usr/bin/python2.7 -v

2. If the environment variable `VIRTUAL_ENV` is set, use that 
   virtualenv's `python.exe`.
3. If the environment variable `PYTHONHOME` is set, use its 
   `python.exe`.
4. If none of the above, fall back to the first `python.exe` 
   found on the path.

## pyassoc

```sh
pyassoc [original] [all_users]
```

With no arguments, `pyassoc` will register the .py extension 
to run with `%pyhome%\pywin.bat`. This change is made in the 
registry to `HKEY_CURRENT_USER`, so that when .py files are invoked,
any machine-wide setting is overridden.

Note that registry settings have no effect on launch .py files 
under MSYS/MINGW32.

#### Parameters
- **original** - restore .py registry settings to launch with `%pyhome%\python.exe`
- **all_users** - if administrator, apply changes to `HKEY_LOCAL_MACHINE` and
                  remove any `HKEY_CURRENT_USER` python keys.
                  Note that users can override this with their own 
                  `HKEY_CURRENT_USER` values.

#### %pyhome%
The variable `%pyhome%` used by `pyassoc` is set in this manner:

1. If the environment variable `PYTHONHOME` is set, use it.
2. If the environment variable `DEFAULTPYTHON` is set, use it.
   This is set when you call `pywin setdefault <version>`,
   but only lasts for the current session.
3. The path the `pyassoc.bat` script is in.
