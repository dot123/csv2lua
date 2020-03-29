@echo off
if "%1"=="h" goto begin
start mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit
:begin
taskkill /f /t /im Csv2Lua.exe
call "./Csv2Lua.exe" 
