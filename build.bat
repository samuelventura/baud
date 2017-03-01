@echo off
if not "%INCLUDE%"=="" goto COMP

call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat" amd64
set INCLUDE=%INCLUDE%C:\Program Files\erl8.0\erts-8.0\include;
cd %~dp0

:COMP
call nmake /F NMakefile %*
