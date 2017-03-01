if not "%INCLUDE%"=="" goto COMP

call "C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat"
set INCLUDE=%INCLUDE%C:\Program Files\erl8.0\erts-8.0\include;
cd %~dp0

:COMP
cl /W4 /LD /MD /Fepriv/baud_nif.dll src/baud_nif.c src/baud_win32.c
