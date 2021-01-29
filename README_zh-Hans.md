
# MacGesture 2 ![tweet](https://img.shields.io/twitter/url/https/github.com/CodeFalling/MacGesture.svg?style=social)

![logo](logo.png)

macOS上一款高度可配置的全局鼠标手势软件。

** 有不止一个用户上报MacGesture在Sierra系统上运行不正常。如果你也发现同样的问题，也请在项目页面提交并且回滚到更旧的可用的版本。**

你可以在软件的关于里阅读这个自述文件。

# 特性

- 全局鼠标手势识别

- 可以根据App的包ID过滤（有些不包含包ID的App除外）

- 通过手势配置并发送快捷键

# 预览

![Preview](https://cloud.githubusercontent.com/assets/5436704/14278725/bb126d36-fb5b-11e5-9fe8-5990ea4c1c28.gif)

# 手势的格式

| 手势    | 缩写    |
|---------|---------|
| 左      | L       |
| 上      | U       |
| 右      | R       |
| 下      | D       |
| 鼠标右键| Z       |
| 滚轮向上| u       |
| 滚轮向下| d       |

手势可以包含通配符（“?”和“*”）。

被匹配到的第一个规则会生效

Z是“左”的拼音首字母，所以我们让Z代表鼠标左键事件。

鼠标滚轮事件可能随设备和系统设置变化而不同（比如Karabiner有反转滚轮方向的功能）

# Q&A

可以尽管提交问题

# 下载

从这里下载最新版本： https://github.com/MacGesture/MacGesture/releases

# 贴士

1. 如果你要实现这个功能：

鼠标右击，向上脱拽，然后每次鼠标滚轮向上触发“下一个标签页“，每次鼠标滚轮向下触发”上一个标签页“，期间不松开鼠标右键。

那么，按照如下创建规则：

| 手势    | 过滤               | 动作               | 说明       | 每次匹配时触发         |
|---------|--------------------|--------------------|------------|------------------------|
|U*d      | \*safari\|\*chrome | "shift-command-\]" | "Next Tab" | Checked                |
|U*u      | \*safari\|\*chrome | "shift-command-\[" | "Prev Tab" | Checked                |

# 使用许可

该项目遵循GPL（GNU通用公共许可证）。

图标由[DanRabbit](http://www.iconarchive.com/artist/danrabbit.html) 设计，许可证是 [GNU General Public License](https://en.wikipedia.org/wiki/GNU_General_Public_License) 。 

# 贡献者

- [CodeFalling](https://github.com/codefalling)
- [jiegec](https://github.com/jiegec)
- [zhangciwu](https://github.com/zhangciwu)

# 讨论

讨论可以加入qq群：498035635 (You can join the discussion in QQ Group 498035635).
