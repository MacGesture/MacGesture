# MacGesture ![tweet](https://img.shields.io/twitter/url/https/github.com/username0x0a/MacGesture.svg?style=social)

![logo](https://raw.githubusercontent.com/username0x0a/MacGesture/2020-update/logo.png)

Configurable global mouse gesture for macOS.

**Some issues may still occur on macOS High Sierra and newer. Please file issues if possible! 🙌**

You can read this README in About section of the App Preferences.

# Download

Download the latest ZIP release from [GitHub releases](https://github.com/username0x0a/MacGesture/releases) page.

# Features

- Global mouse gestures recognition

- Filter app by their bundle name

- Configure and send shortcut by gesture

# Gestures format

| Gesture | Acronym |
| ------- | ------- |
| Left    | L       |
| Up      | U       |
| Right   | R       |
| Down    | D       |
| Mouse L | Z       |
| Wheel U | u       |
| Wheel D | d       |

Gesture can contain wildcard matching(`?` and `*`).

The first rule matching will take effect.

Z is the acronym of pinyin of '左' which means 'left' in English.
So to distinguish 'clicking the left mouse' from 'dragging your mouse left-ward',
we chose 'Z'.

Wheel directions may vary according to system configurations or some system tweaks (Karabiner's Reverse Vertical Scrolling, for example).

# Known Issues

### Right click does not work in some Java applications.

An imperfect fix:
Take WebStorm for example, open Preferences, then KeyMap, set the shortcut of "Show Context Menu" to "Button3 Click"

### Cannot assign some system-wide shortcuts to rules.

Reason:
macOS respond to system-wide shortcuts before MacGesture.

Fix:
Disable the shortcut first (for example in System Preferences → Keyboard → Shortcuts), then assign the shortcut in MacGesture, and re-enable the shortcut.

Caveats:
Some shortcuts still do not work with the fix above. When you are encountering this, here are two possible solutions:
1. Change them to others (e.g. Control+0, Control+9).
2. Tick "Invert Fn When Control Is Pressed".

# Q&A

Feel free to open an issue on GitHub 👍

# Tips

### Mouse scroll gesture example

Right click, drag upwards, then every 'u' triggers a 'Next Tab', every 'd' triggers a 'Prev Tab', without releasing right mouse.

Then, create a rule like this:

| Gesture | Filter             | Action             | Note       | Trigger on every match |
| ------- | ------------------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*safari\|\*chrome | "shift-command-\]" | "Next Tab" | Checked                |
| U*u     | \*safari\|\*chrome | "shift-command-\[" | "Prev Tab" | Checked                |

### Exporting and importing MacGesture preferences

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

### Excluding an app in a certain rule

You can prepend '!', then the app you want to exclude (still wildcard).

For example, the original one:

| Gesture | Filter | Action             | Note       | Trigger on every match |
| ------- | ------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*     | "shift-command-\]" | "Next Tab" | Checked                |

Then, in order to exclude Safari, change this to:

| Gesture | Filter       | Action             | Note       | Trigger on every match |
| ------- | ------------ | ------------------ | ---------- | ---------------------- |
| U*d     | \*\|!*safari | "shift-command-\]" | "Next Tab" | Checked                |

Then you will see the expected behaviour.

# License

This project is made under [GNU General Public License](https://en.wikipedia.org/wiki/GNU_General_Public_License).

App icon & other icons designed by [username0x0a](https://github.com/username0x0a).

# Contributors

- [CodeFalling](https://github.com/codefalling) – original author
- [username0x0a](https://github.com/username0x0a) – maintainer
- [jiegec](https://github.com/jiegec)
- [zhangciwu](https://github.com/zhangciwu)
