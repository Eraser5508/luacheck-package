local LFW_ROOT = site_config.LFW_ROOT
rocks_trees = {
    { name = [[system]],
         root      = LFW_ROOT..[[]],        -- same as LUAROCKS_ROCKS_TREE
         rocks_dir = LFW_ROOT..[[\rocks]],  -- same as LUAROCKS_ROCKS_SUBDIR
         bin_dir   = LFW_ROOT..[[]],        -- same as LUA_BINDIR
         lib_dir   = LFW_ROOT..[[\clibs]],
         lua_dir   = LFW_ROOT..[[\lua]],
    },
}
variables = {
    MSVCRT = 'MSVCR80',
    LUALIB = 'lua5.1.lib',
    WRAPPER = LFW_ROOT..[[\rclauncher.obj]],
    SEVENZ = LFW_ROOT..[[\tools\7z.exe]],
    CP = LFW_ROOT..[[\tools\cp.exe]],
    FIND = LFW_ROOT..[[\tools\find.exe]],
    LS = LFW_ROOT..[[\tools\ls.exe]],
    MD5SUM = LFW_ROOT..[[\tools\md5sum.exe]],
    MKDIR = LFW_ROOT..[[\tools\mkdir.exe]],
    MV = LFW_ROOT..[[\tools\mv.exe]],  -- not used, but meh
    PWD = LFW_ROOT..[[\tools\pwd.exe]],
    RMDIR = LFW_ROOT..[[\tools\rmdir.exe]],
    TEST = LFW_ROOT..[[\tools\test.exe]],
    UNAME = LFW_ROOT..[[\tools\uname.exe]],
    WGET = LFW_ROOT..[[\tools\wget.exe]]
}
verbose = false   -- set to 'true' to enable verbose output
