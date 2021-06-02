@echo off
echo 自动生成luacheck配置...
echo --------------------------
cd /d %~dp0
set file_path_1=%cd%\Lua
set file_path_2=%file_path_1:\=\\%
set head=@echo off
set config="%file_path_1%\lua53.exe" -e "package.path=\"%file_path_2%/luarocks/share/lua/5.3/?.lua;%file_path_2%/luarocks/share/lua/5.3/?/init.lua;\"..package.path;package.cpath=\"%file_path_2%/luarocks/lib/lua/5.3/?.dll;\"..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('luacheck','0.24.0-2')" "%file_path_1%\luarocks\lib\luarocks\rocks-5.3\luacheck\0.24.0-2\bin\luacheck" %%*
set luacheck_path=Lua\luarocks\bin
echo %head%>%luacheck_path%\luacheck.bat
echo %config%>>%luacheck_path%\luacheck.bat
echo luacheck.bat路径:
echo %cd%\%luacheck_path%
echo --------------------------
echo luacheck配置生成完毕！！！
pause