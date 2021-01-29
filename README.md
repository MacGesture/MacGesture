# MacGesture 2 ![tweet](https://img.shields.io/twitter/url/https/github.com/CodeFalling/MacGesture.svg?style=social)

[Chinese version 中文版](https://github.com/MacGesture/MacGesture/blob/release/README_zh-Hans.md)

![logo](logo.png)

Configurable global mouse gesture for macOS.

**Multiple issues are reported in macOS High Sierra. Please file issues and roll back to earlier versions before we fix all of them.**

<u>***LOOKING FOR NEW MAINTAINER***</u>

You can read this README in About section.

# Download

## Via Homebrew Cask

```
brew cask install macgesture
```

## Download Manually

Download the latest zip from https://github.com/MacGesture/MacGesture/releases

# Feature

- Global mouse gesture recognition

- Filter app by their bundle name (as a consequence, the apps without bundle identifiers are skipped and filtering by process name is on the road map)

- Configure and send shortcut by gesture

# Preview

![Preview](https://cloud.githubusercontent.com/assets/5436704/14278725/bb126d36-fb5b-11e5-9fe8-5990ea4c1c28.gif)

# The format of gesture

| Gesture | Acronym |
| ------- | ------- |
| Left    | L       |
| Up      | U       |
| Right   | R       |
| Down    | D       |
| Mouse L | Z       |
| Wheel U | u       |
| Wheel D | d       |

Gesture can contain wildcard matching('?' and '*').

The first rule matching will take effect.

Z is the acronym of pinyin of '左' which means 'left' in English.
So to distinguish 'clicking the left mouse' from 'dragging your mouse left-ward',
we chose 'Z'.

Wheel directions may vary according to system configurations or some system tweaks (Karabiner's Reverse Vertical Scrolling, for example).

# Known Issues

* Right click does not work in some Java applications.

An imperfect fix:
Take WebStorm for example, open Preferences, then KeyMap, set the shortcut of "Show Context Menu" to "Button3 Click"

* Cannot assign some system-wide shortcuts to rules.

Reason:
macOS respond to system-wide shortcuts before MacGesture.

Fix:
Disable the shortcut first (for example in System Preferences->Keyboard->Shortcuts), then assign the shortcut in MacGesture, and re-enable the shortcut.

Caveats:
Some shortcuts still do not work with the fix above. When you are encountering this, here are two possible solutions:
1. Change them to others (e.g. Control+0, Control+9).
2. Tick "Invert Fn When Control Is Pressed".

# Q&A

Feel free to open issue

# Tips

* If you want to achieve something like this:

Right click, drag upwards, then every 'u' triggers a 'Next Tab', every 'd' triggers a 'Prev Tab', without releasing right mouse.

Then, create a rule like this:

| Gesture | Filter             | Action             | Note       | Trigger on every match |
| ------- | ------------------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*safari\|\*chrome | "shift-command-\]" | "Next Tab" | Checked                |
| U*u     | \*safari\|\*chrome | "shift-command-\[" | "Prev Tab" | Checked                |

* If you want to export and import MacGesture preferences:

Recommended way:

Use the buttons 'Import' and 'Export' in the ‘General' Panel.

Geek-ish way: (the underlying way as well)

Open a terminal, Do this in your old computer:

``` shell
defaults read com.codefalling.MacGesture backup.plist
```

And then copy that file to your new computer, then:

``` shell
defaults import com.codefalling.MacGesture backup.plist
```

You should get your preferences back now. If is doesn't, file an issue on the project home.

* If you want to exclude an app in a certain rule:

You can prepend '!', then the app you want to exclude (still wildcard).

For example, the original one:

| Gesture | Filter | Action             | Note       | Trigger on every match |
| ------- | ------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*     | "shift-command-\]" | "Next Tab" | Checked                |

Then, in order to exclude Safari, change this to:

| Gesture | Filter       | Action             | Note       | Trigger on every match |
| ------- | ------------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*\|!*safari | "shift-command-\]" | "Next Tab" | Checked                |

Then you will see the expected behavior.

# License

This project is under GNU General Public License.

Icon is designed by [DanRabbit](http://www.iconarchive.com/artist/danrabbit.html) under [GNU General Public License](https://en.wikipedia.org/wiki/GNU_General_Public_License).

# Contributor

- [CodeFalling](https://github.com/codefalling)
- [jiegec](https://github.com/jiegec)
- [zhangciwu](https://github.com/zhangciwu)

# Discuss

讨论可以加入qq群：498035635 (You can join the discussion in QQ Group 498035635).
