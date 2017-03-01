@echo off
set REBAR=%UserProfile%\.mix\rebar3
if not exist %REBAR% (mix local.rebar --force)
escript.exe %REBAR% %*
