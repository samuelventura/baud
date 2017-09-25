@echo off
rem Run with: cmd /K c:\Users\samuel\Documents\github\baud\setenv.bat
rem Does not work when launched with start from another cmd window
rem Launch from Windows start menu text box
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
cd %~dp0
