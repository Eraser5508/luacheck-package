# luacheck package
## 目录
- [功能介绍](#功能介绍)
- [使用方法](#使用方法)
- [额外检查规则](#额外检查规则)
- [相关文档](#相关文档)
## 功能介绍
- 此工程为luacheck的整合包，可快速为vs code接入luacheck
- 需要结合VS Code的vscode-lua插件使用，配置相关文件路径后可直接生效
- 包含最新版luacheck的所有检查规则，同时额外增加了某些自定义规则
## 使用方法
### 1. 在VS Code中搜索vscode-lua插件并安装
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_1.png" width="350"/></br>

### 2. 打开设置界面，找到vscode-lua设置中的Luacheck Path选项，点击Edit in settings.json
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_2.png" width="350"/></br>
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_3.png" width="700"/></br>

### 3. 配置lua.luacheckPath字段，使其指向luacheck package中的luacheck.bat
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_4.png" width="550"/></br>

### 4. 打开luacheck.bat，修改其中路径相关的字段（有多个），使其指向自己电脑上luacheck package的相应位置
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_5.png" width="450"/></br>

### 5. 打开lua文件，按 ctrl+shift+M 打开Problems栏，如果以上路径配置正确，即可看到luacheck警告日志
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_6.png" width="500"/></br>

## 额外检查规则
### 1. 不标准的函数命名(811)
- 非大写字母开头的函数名
- 函数名为单个字符

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_811.png" width="800"/></br>

### 2. 不推荐的字符连接方式(812)
- 使用'..'连接字符串

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_812.png" width="800"/></br>

### 3. 没有直接使用常量(813)
- 将一个number数据放入table.XXX中
- 没有对table.xxx进行二次赋值
- 对table.xxx进行了引用

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_813.png" width="800"/></br>

### 4. 使用过多相同的GetTable操作(814)
- 在同一个function中
- 没有对table.xxx.xxx进行赋值
- 调用同一个table.xxx.xxx 2次及以上

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_814.png" width="800"/></br>

### 5. 在Tick中新建C++对象(815)
- 在Tick函数及其调用的函数中
- 调用外部函数新建C++对象

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_815.png" width="800"/></br>

### 6. 使用arg作为参数名(911)

- function中的参数名为"arg"

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_911.png" width="800"/></br>

### 7. 使用分号分隔语句(912)

- 使用";"分隔语句

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_912.png" width="800"/></br>

### 8. 显式指定数组下标从0开始(913)

- 对table[0]进行赋值

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_913.png" width="800"/></br>

### 9. 创建table时混用array与hash(914)

- 显式指定数组下标
- 使用默认数组索引

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_914.png" width="800"/></br>

## 相关文档
- luacheck参数配置指南：https://luacheck.readthedocs.io/en/stable/
- luacheck源代码：https://github.com/mpeterv/luacheck
