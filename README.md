# luacheck package
## 功能介绍
- 此工程为luacheck的整合包，可快速为vs code接入luacheck
- 需要结合VS Code的vscode-lua插件使用，配置相关文件路径后可直接生效
- 包含最新版luacheck的所有检查规则，同时额外增加了某些自定义规则
## 使用方法
### 1. 配置vscode-lua插件
- 在VS Code中搜索vscode-lua插件并安装
- 打开设置界面，找到vscode-lua设置中的Luacheck Path选项，点击Edit in settings.json
- 配置lua.luacheckPath字段，使其指向luacheck package中的luacheck.bat
### 2. 配置luacheck.bat
- 打开luacheck.bat，修改其中路径相关的字段，使其指向自己电脑上luacheck package的相应位置
### 3. 完成
- 打开lua文件，按 ctrl+shift+M 打开Problems栏，如果以上路径配置正确，即可看到luacheck警告日志
## 相关文档
- luacheck参数配置指南：https://luacheck.readthedocs.io/en/stable/
- luacheck源代码：https://github.com/mpeterv/luacheck
