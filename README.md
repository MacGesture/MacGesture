# MacGesture

Mac 下的鼠标手势，主要为了在Safari中使用类似FireGesture的手势

## 截图

![preview](http://i2.tietuku.com/ffda461f64da80ef.gif)

## 预设手势

- ↑←	切换到左侧Tab
- ↑→	切换到右侧Tab
- ↓←	打开/关闭全屏模式
- ↓→	关闭当前tab
- →    	向前
- ←    	后退

## 定制

![menu](http://i2.tietuku.com/2df681c61e3fe807.png)

点菜单中的`Open handle.lua`可以打开配置文件，修改完成后选择`Reload handle.lua`重新加载配置文件。`release`中将预置一个`handle.lua`以支持预设手势，用户可以自行修改，在升级时注意备份。

**Notice** `Open handle.lua`将调用默认的文本编辑器（使用`open -t`）打开`handle.lua`，关于如何修改默认文本编辑器可以参阅[how does mountain lion set the default text editor for the open t](http://apple.stackexchange.com/questions/73823/how-does-mountain-lion-set-the-default-text-editor-for-the-open-t-terminal-co)

关于`handle.lua`的更多说明请阅读**[wiki](https://github.com/CodeFalling/MacGesture/wiki/handle.lua)**
## TODO

- 通过配置文件读取手势和快捷键组合

- 增加设置界面

## 下载

[Releases](https://github.com/CodeFalling/MacGesture/releases)

## Trouble Shotting

```
MacGesture Error
/Applications/MacGesture.app/Contents/Resources/handle.lua:11:unexpected symbol near char(226)
```

是由于lua脚本中有不识别的字符，而第一次修改代码的用户几乎一定会碰到这个问题，因为Mac自带的TextEditor默认开启了**智能引号**功能，会将引号自动修改成中文引号。

解决方案：

- 在`文本编辑器->偏好设置`中关闭`智能引号`

- **重启文本编辑器**

如图：
![pic](http://ww3.sinaimg.cn/large/005X3nOQjw1epbjd30jjdj30e90jbdi3.jpg)
如果觉得麻烦也可以在其他编辑器中写好再复制回来，关于其他已安装代码编辑器的功能将在今后完善。
