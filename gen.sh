#!/bin/sh
# Use discount here
markdown < README.md > ./MacGesture/Resources/en.lproj/README.html
markdown < README_zh-Hans.md > ./MacGesture/REsources/zh-Hans.lproj/README.html
cp logo.png ./MacGesture/Resources
