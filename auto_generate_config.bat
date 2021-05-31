@echo off
echo 自动生成luacheck配置...
echo --------------------------
cd /d %~dp0
set file_path_1=%cd%\Lua
set file_path_2=%file_path_1:\=\\%
set head=@echo off
set config="%file_path_1%\lua" -e "package.path=\"%file_path_2%\\lua/?.lua;%file_path_2%\\lua/?/init.lua;%file_path_2%\\2.2\\lua\\?.lua;\"..package.path; package.cpath=\"%file_path_2%\\clibs/?.dll;\"..package.cpath" -e "local k,l,_=pcall(require,\"luarocks.loader\") _=k and l.add_context(\"luacheck\",\"0.24.0-2\")" "F:\Github Workspace\luacheck-package\Lua\rocks\luacheck\0.24.0-2\bin\luacheck" %%*
set luacheck_path=Lua\luacheck.bat
echo %head%>%luacheck_path%
echo %config%>>%luacheck_path%
echo 生成luacheck.bat:%cd%\%luacheck_path%
echo --------------------------
set lua_dev_env=%file_path_1%
set lua_path_env=%file_path_1%\lua
set path_env=%file_path_1%
echo 设置环境变量 LUA_DEV %lua_dev_env%
setx /m LUA_DEV "%lua_dev_env%">nul 2>nul
if not %errorlevel% == 0 (
    echo 配置生成错误：请使用管理员模式运行！！！
	goto end
)
echo 设置环境变量 LUA_PATH %lua_path_env%
setx /m LUA_PATH "%lua_path_env%">nul 2>nul
echo 设置环境变量 Path %path_env%
echo %path%>luacheck_temp.txt
find "%path_env%" luacheck_temp.txt>nul 2>nul
if not %errorlevel% == 0 (
    setx /m path "%path%;%path_env%">nul 2>nul
)
del luacheck_temp.txt
echo --------------------------
echo luacheck配置生成完毕！！！
:end
pause