# MacGesture 2 ![tweet](https://img.shields.io/twitter/url/https/github.com/CodeFalling/MacGesture.svg?style=social)

[英文版 English Version](https://github.com/MacGesture/MacGesture/blob/release/README.md)

![logo](logo.png)

macOS上一款高度可配置的全局鼠标手势软件。

**有不止一个用户上报MacGesture在macOS High Sierra系统上运行不正常。如果你也发现同样的问题，也请在项目页面提交并且回滚到更旧的可用的版本。 **

***<u>寻求项目新的维护者</u>***

你可以在软件的关于里阅读这个自述文件。

# 下载

## 通过 Homebrew Cask

```
brew cask install macgesture
```

# 手动下载

从这里下载最新版本： https://github.com/MacGesture/MacGesture/releases


# 特性

- 全局鼠标手势识别

- 可以根据App的包ID过滤（有些不包含包ID的App除外）

- 通过手势配置并发送快捷键

# 预览

![Preview](https://cloud.githubusercontent.com/assets/5436704/14278725/bb126d36-fb5b-11e5-9fe8-5990ea4c1c28.gif)

# 手势的格式

| 手势   | 缩写   |
| ---- | ---- |
| 左    | L    |
| 上    | U    |
| 右    | R    |
| 下    | D    |
| 鼠标左键 | Z    |
| 滚轮向上 | u    |
| 滚轮向下 | d    |

手势可以包含通配符（“?”和“*”）。

被匹配到的第一个规则会生效。

Z是“左”的拼音首字母，所以我们让Z代表鼠标左键事件。

鼠标滚轮事件可能随设备和系统设置变化而不同（比如Karabiner有反转滚轮方向的功能）


# 已知问题

* 右键点击在一些Java应用中失效。

一个不完美的修复：
拿WebStorm作为例子，打开Preferences，在KeyMap中设置“Show Context Menu”的快捷键为“Button3 Click”。

* 不能设置一些全系统可用的快捷键。

原因：
macOS在MacGesture响应之前做出了相应处理。

修复：
先禁用快捷键（比如在系统配置->键盘->快捷键），然后在MacGesture中设置以后再重新启用快捷键。

注意：
即便用了以上的修复，一些快捷键仍然不能使用。当你遇到这个问题时，有两种可能的解决方案：
1. 修改快捷键为其它（比如Control+0, Control+9）。
2. 勾上“当 Control 按下时，抵消 Fn 键的作用”。

# Q&A

可以尽管提交问题

# 贴士

* 如果你要实现这个功能：

鼠标右击，向上脱拽，然后每次鼠标滚轮向上触发“下一个标签页“，每次鼠标滚轮向下触发”上一个标签页“，期间不松开鼠标右键。

那么，按照如下创建规则：

| 手势   | 过滤                 | 动作                 | 说明         | 每次匹配时触发 |
| ---- | ------------------ | ------------------ | ---------- | ------- |
| U*d  | \*safari\|\*chrome | "shift-command-\]" | "Next Tab" | Checked |
| U*u  | \*safari\|\*chrome | "shift-command-\[" | "Prev Tab" | Checked |

* 如果你想导入和导出MacGesture的配置文件：

推荐方法：

使用“通用”面板里的“导入”和“导出”按钮。

Geek使用的方法：（也是实际上代码用的方法）

打开一个Terminal，在你的旧电脑上这么做：

``` shell
defaults read com.codefalling.MacGesture backup.plist
```

然后把这个文件复制到新电脑上，然后：

``` shell
defaults import com.codefalling.MacGesture backup.plist
```

你应该可以看到你之前的设置回来了。如果没有的话，请在项目主页提交问题。

* 如果想要在某个规则中排除某个App：

可以在过滤中加上'!'，再加上你想要排除的App（仍然是通配符）。

比如，原来是：

| 手势   | 过滤   | 动作                 | 说明         | 每次匹配时触发 |
| ---- | ---- | ------------------ | ---------- | ------- |
| U*d  | \*   | "shift-command-\]" | "Next Tab" | Checked |

现在想在Safari中禁用这个手势，那么，它应该改成：

| 手势   | 过滤           | 动作                 | 说明         | 每次匹配时触发 |
| ---- | ------------ | ------------------ | ---------- | ------- |
| U*d  | \*\|!*safari | "shift-command-\]" | "Next Tab" | Checked |

就可以实现这个目标了。

# 使用许可

该项目遵循GPL（GNU通用公共许可证）。

图标由[DanRabbit](http://www.iconarchive.com/artist/danrabbit.html) 设计，许可证是 [GNU General Public License](https://en.wikipedia.org/wiki/GNU_General_Public_License) 。 

# 贡献者

- [CodeFalling](https://github.com/codefalling)
- [jiegec](https://github.com/jiegec)
- [zhangciwu](https://github.com/zhangciwu)

# 讨论

讨论可以加入qq群：498035635 (You can join the discussion in QQ Group 498035635).
