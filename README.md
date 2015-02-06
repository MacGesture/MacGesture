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

关于`handle.lua`的更多说明请阅读**[wiki](https://github.com/CodeFalling/MacGesture/wiki/handle.lua)**
## TODO

- 通过配置文件读取手势和快捷键组合

- 增加设置界面

## 下载

[Releases](https://github.com/CodeFalling/MacGesture/releases)
=======
## ChangLog

- 0.1

第一版发布

- 2015-2-4-nightly

增加手势识别预览

- 0.2

增加`Lua`配置支持，用户可通过修改`handle.lua`来控制手势

- 0.2.1


