# pywin
**pywin** is a lightweight version of the [py.exe windows launcher available in python 3.3](http://docs.python.org/3/using/windows.html#launcher) that works for Python 2.5-3.3. It's written primarily with basic Windows batch scripts and a helper shell script for MSYS/MINGW support. It supports several useful features defined in [PEP 397](http://www.python.org/dev/peps/pep-0397/), such as command line conventions and hash bang #! python version headers in source files. While pywin lacks some of py.exe's features, it has the basics and a few extras of its own.


## Requirements
* Windows >= XP for command prompt support
* Windows >= Vista for MSYS/MINGW support
* At least one installation of python 2.5 up to 3.3 (though it's not useful without at least two)
* easy_install, pip, or git


## Installation
#### easy_install
```bash
easy_install pywin
```

#### pip
```bash
pip install pywin
```

### from source
```bash
git clone git://github.com/davidmarble/pywin.git
cd pywin
python setup.py install
```


## Quick Tour
**pywin** and its associated scripts are installed in the main directory of the active python version (e.g. C:\Python27). There's no need to install it under more than one version of python (if you do, you'll have to run `pywin genlaunchers` for each version you install it under). Make sure that this main python directory is always on the path. Alternatively you can move the included scripts to another directory in your path.

### Auto-generate version-specific launchers
**pywin** can create individual launch scripts to directly access core python installations (e.g. python2.7). These can be called directly with or without arguments from the Windows command prompt and MSYS/MINGW bash prompt. To use this feature, call

```bash
pywin genlaunchers
```

Launchers are created for all machine-wide and user-specific python installations found in the Windows registry. Windows batch files will be added to the directory where **pywin** is located. MSYS/MINGW32 relies on Windows links created programmatically with `mklink`, which is why you must have Windows >= Vista installed to make use of this project.

### Launch a specific python version using pywin
```bash
pywin -2.7  # launch python 2.7
pywin -3.2 test.py  # launch test.py with python 3.2
```

### Automatically invoke the right python with a script header
Add a directive to the first or second line of a source file to have the correct interpreter called. Currently this only supports python launchers created by the `pywin genlaunchers` command. To use this feature, you must associate the .py extension with pywin.bat using the included `pyassoc` utility. 

```bash
pyassoc
```


## pywin

**NOTE:** `pywin` commands work from both Windows command line and MSYS/MINGW32 shell.

### genlaunchers

```bash
pywin genlaunchers
```
Search for python installations and create batch files in the same
directory where pywin is installed.

Note if you're using MSYS/MINGW32 this must be run again in the 
MSYS/MINGW32 shell, and you must have Windows >= Vista.

### setdefault

```bash
pywin setdefault <version>
```
Set the default python to <version>. Adds the right directory to
the front of the path. E.g. `pywin setdefault 3.3`.
This is only for the current cmd.exe session. If you want to change
the permanent default python, you need to change your system or
user path and make sure pywin is installed for that python version.

When calling this from MSYS/MINGW32, enter a dot first so the changes 
to $PATH propagate to your active shell. E.g. `. pywin setdefault 3.3`

### launch with version and/or source

```bash
pywin [-<version>] [<source file>]
```

Launch either a specific version of python. E.g. `pywin -2.7`, 
or a source file, or both. Note that specifying a version of python 
on the command line will override any version set in the header of 
the file.

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

```bash
pyassoc [original] [all_users]`
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
