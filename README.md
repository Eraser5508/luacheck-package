# luacheck package
## 目录
- [功能介绍](#功能介绍)
- [使用方法](#使用方法)
- [额外检查规则](#额外检查规则)
- [警告码对照表](#警告码对照表)
- [相关文档](#相关文档)
## 功能介绍
- 此工程为luacheck的整合包，可快速为vs code接入luacheck
- 需要结合VS Code的vscode-luacheck插件使用
- 包含最新版luacheck的所有检查规则，同时额外增加了某些自定义规则
## 使用方法
### 1. 在VS Code中搜索vscode-luacheck插件并安装
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_1.png" width="450"/></br>

### 2. 下载luacheck package到本地，双击打开工程中的auto_generate_config.bat文件，自动生成配置
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_2.png"></br>

### 3. 复制cmd窗口中的luacheck.bat路径，将其添加到PATH环境变量中
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_3.png"></br>
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_4.png"></br>

### 4. 在VS Code中打开lua文件，按 ctrl+shift+M 打开Problems栏，即可看到luacheck警告日志
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_5.png" width="500"/></br>

### 5. （可选）找到vscode-lua插件的安装位置，将Files文件夹中的extension.js、diagnostic.js文件覆盖原插件中的同名文件
- extension.js可解决编辑器代码提示缓慢的问题
- diagnostic.js可在编辑器Problems栏中显示luacheck警告码
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_6.png" width="1000"/></br>
<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/guide_image_7.png" width="1000"/></br>

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

- 既显式指定数组下标，又使用默认数组索引

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_914.png" width="800"/></br>

### 10. 二元运算符两边未加空格(915)

- 使用"+" "-" "<"等二元运算符时两边未加空格（乘幂运算符"^"除外）

<br/><img src="https://github.com/Eraser5508/luacheck-package/blob/master/Image/sample_image_915.png" width="800"/></br>

## 警告码对照表

 警告码|描述
 ------|-------
 011|A syntax error.
 021|An invalid inline option.
 022|An unpaired inline push directive.
 023|An unpaired inline pop directive.
 111|Setting an undefined global variable.
 112|Mutating an undefined global variable.
 113|Accessing an undefined global variable.
 121|Setting a read-only global variable.
 122|Setting a read-only field of a global variable.
 131|Unused implicitly defined global variable.
 142|Setting an undefined field of a global variable.
 143|Accessing an undefined field of a global variable.
 211|Unused local variable.
 212|Unused argument.
 213|Unused loop variable.
 221|Local variable is accessed but never set.
 231|Local variable is set but never accessed.
 232|An argument is set but never accessed.
 233|Loop variable is set but never accessed.
 241|Local variable is mutated but never accessed.
 311|Value assigned to a local variable is unused.
 312|Value of an argument is unused.
 313|Value of a loop variable is unused.
 314|Value of a field in a table literal is unused.
 321|Accessing uninitialized local variable.
 331|Value assigned to a local variable is mutated but never accessed.
 341|Mutating uninitialized local variable.
 411|Redefining a local variable.
 412|Redefining an argument.
 413|Redefining a loop variable.
 421|Shadowing a local variable.
 422|Shadowing an argument.
 423|Shadowing a loop variable.
 431|Shadowing an upvalue.
 432|Shadowing an upvalue argument.
 433|Shadowing an upvalue loop variable.
 511|Unreachable code.
 512|Loop can be executed at most once.
 521|Unused label.
 531|Left-hand side of an assignment is too short.
 532|Left-hand side of an assignment is too long.
 541|An empty do end block.
 542|An empty if branch.
 551|An empty statement.
 561|Cyclomatic complexity of a function is too high.
 571|A numeric for loop goes from #(expr) down to 1 or less without negative step.
 611|A line consists of nothing but whitespace.
 612|A line contains trailing whitespace.
 613|Trailing whitespace in a string.
 614|Trailing whitespace in a comment.
 621|Inconsistent indentation (SPACE followed by TAB).
 631|Line is too long.
 811|Nonstandard function name.
 812|Connect string with '..'.
 813|Use constant indirectly.
 814|Multiple same 'GetTable' instruction in same function.
 911|Use 'arg' as parameter name.
 912|Use semicolon to seperate statements.
 913|Specify the array subscript from '0' explicitly.
 914|Mix array and hash when constructing a table.
 915|Missing spaces on both sides of binary operator.

- 011-631为luacheck原有规则，811-915为额外自定规则

## 相关文档
- luacheck参数配置指南：https://luacheck.readthedocs.io/en/stable/
- luacheck源代码：https://github.com/mpeterv/luacheck
