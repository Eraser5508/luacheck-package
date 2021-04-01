local os = os
local site_config = {}
site_config.LFW_ROOT=os.getenv("LUA_DEV")
site_config.LUAROCKS_PREFIX=site_config.LFW_ROOT
site_config.LUA_INCDIR=site_config.LFW_ROOT..[[\include]]
site_config.LUA_LIBDIR=site_config.LFW_ROOT..[[\lib]]
site_config.LUA_BINDIR=site_config.LFW_ROOT
site_config.LUA_INTERPRETER=[[lua]]
site_config.LUAROCKS_SYSCONFDIR=site_config.LFW_ROOT
site_config.LUAROCKS_SYSCONFIG=site_config.LFW_ROOT..[[\luarocks_config.lua]]
site_config.LUAROCKS_ROCKS_TREE=site_config.LFW_ROOT
site_config.LUAROCKS_FORCE_CONFIG=true
site_config.LUAROCKS_ROCKS_SUBDIR=[[\rocks]]
site_config.LUA_DIR_SET=true
site_config.LUAROCKS_UNAME_S=[[WindowsNT]]
site_config.LUAROCKS_UNAME_M=[[x86]]
site_config.LUAROCKS_DOWNLOADER=[[wget]]
site_config.LUAROCKS_MD5CHECKER=[[md5sum]]
-- don't support multiple variants of the GCC runtimes 
--site_config.LUAROCKS_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[lib/$GCC_ARCH]] }, include="include" }'
--site_config.LUAROCKS_RUNTIME_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[lib/$GCC_ARCH]] }, include="include" }'
return site_config
