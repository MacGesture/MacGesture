# MacGesture

![logo](https://raw.githubusercontent.com/MacGesture/MacGesture/master/logo.png)

Configurable global mouse gestures for macOS.

> You can read this `README` file in **About** section in App Preferences.

## Installation

### Automatic Update

MacGesture will regularly check for updates and prompt you when new version is available. 👍

### Manually

Download the latese release bundle from [GitHub releases](https://github.com/MacGesture/MacGesture/releases) page.

### Homebrew

Simply use `brew install --cask macgesture`. 🙌

## Features

- Global mouse gestures recognition
- Configurable shortcut invocation by gesture
- App filtering based on bundle identifiers

## Gestures Format

| Gesture      | Acronym |
| ------------ | :-----: |
| Move Left    |   `L`   |
| Move Up      |   `U`   |
| Move Right   |   `R`   |
| Move Down    |   `D`   |
| Left Button  |   `Z`   |
| Wheel Up     |   `u`   |
| Wheel Dp     |   `d`   |

Gestures can contain wildcard matching (`?` and `*`).

The first rule matching will take effect.

`Z` is the acronym of pinyin of `左` which means “left” in English. So to distinguish _clicking the left mouse button_ from _dragging your mouse to the left_, we chose letter `Z`.

Wheel directions may vary according to system configuration (Natural scroll direction setting) or some system tweaks (Karabiner's Reverse Vertical Scrolling, for example).

## Known Issues

### Right click does not work in some Java applications

An imperfect fix:
Take WebStorm for example, open Preferences, then KeyMap, set the shortcut of “Show Context Menu” to `Button3 Click`.

### Cannot assign some system-wide shortcuts to rules

Reason:
macOS respond to system-wide shortcuts before MacGesture.

Fix:
Disable the shortcut first (for example in System Preferences → Keyboard → Shortcuts), then assign the shortcut in MacGesture, and re-enable the shortcut.

Caveats:
Some shortcuts still don't work with the fix above. When you are encountering this, here are two possible solutions:

- Change them to others (e.g. ⌃0, ⌃9).
- Tick “Invert Fn When Control Is Pressed” option.

## Tips

### Mouse scroll gesture example

The following table covers probably the most basic scenario of usage:

| Gesture | Filter             | Action   | Note     | Trigger on every match |
| :-----: | :----------------- | :------: | :------: | :--------------------- |
| `D`     | `*safari\|*chrome` |    ⌘T    | New Tab  | –                      |
| `DR`    | `*safari\|*chrome` |    ⌘W    | Close    | –                      |

By setting these rules, you can empower mouse gestures to open new and close currently focused tabs in Sarari and Chrome Browsers. Simply:

- press the right button, drag mouse down, and release
	- opens a new tab in the current browser window
- press the right button, drag mouse down, then to the right, and release
	- this will result in closing the currently focused tab in the active browser window

How neat! 🙌

Now, to quickly cycle between the selected tabs even without releasing the right mouse button, you can set the gesture to be triggered on every match using the checkbox at the end of the Rule line.

So by defining the following rules:

| Gesture | Filter             | Action   | Note     | Trigger on every match |
| :-----: | :----------------- | :------: | :------: | :--------------------- |
| `U*u`   | `*safari\|*chrome` |   ⇧⌘\[   | Prev Tab | –                      |
| `U*d`   | `*safari\|*chrome` |   ⇧⌘\]   | Next Tab | –                      |

you can simply:

- right click, drag mouse upwards, and every `u` (mouse wheel scroll up) triggers a **Prev Tab** action
- right click, drag mouse upwards, and every `d` (mouse wheel scroll down) triggers a **Next Tab** action.

### Exporting and importing MacGesture preferences

#### Recommended way

Use “Import” and “Export” buttons in the **General** Panel.

#### Geek-ish way

Open the _Terminal_ app, Do this in your old computer:

```shell
defaults read com.codefalling.MacGesture backup.plist
```

And then copy that file to your new computer, then:

```shell
defaults import com.codefalling.MacGesture backup.plist
```

All settings should be successfully brought over. If that's not the case please file an issue.

### Excluding an app in a certain rule

You can prepend `!`, then the app you want to exclude (still wildcard).

For example, the original one:

| Gesture | Filter             | Action   | Note     | Trigger on every match |
| :-----: | :----------------- | :------: | :------: | :--------------------- |
| `U*d`   | `*`                |   ⇧⌘\]   | Next Tab | Checked                |

Then, in order to exclude Safari, change this to:

| Gesture | Filter             | Action   | Note     | Trigger on every match |
| :-----: | :----------------- | :------: | :------: | :--------------------- |
| `U*d`   | `*|!*safari`       |   ⇧⌘\]   | Next Tab | Checked                |

Then you will experience the expected behaviour.

## Found a Bug?

Feel free to open [an issue on GitHub](https://github.com/MacGesture/MacGesture/issues)! 👍

## Contributors

- [CodeFalling](https://github.com/xcodebuild) – original author
- [username0x0a](https://github.com/username0x0a) – maintainer
- [jiegec](https://github.com/jiegec)
- [zhangciwu](https://github.com/zhangciwu)

## License

This project is made under [GNU General Public License](https://en.wikipedia.org/wiki/GNU_General_Public_License).

App icon & other icons designed by [username0x0a](https://github.com/username0x0a).
