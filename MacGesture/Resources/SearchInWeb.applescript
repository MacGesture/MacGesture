tell application "System Events" to keystroke "c" using {command down}
delay 0.3 -- prolong or shorten it if needed
try
        set theData to (the clipboard as text)
        -- for Baidu, use http://www.baidu.com/s?word=
        -- for Google, use http://www.googe.com/search?q=
        -- for Bing, use http://www.bing.com/search?q=
        set theData to "http://www.baidu.com/s?word=" & quoted form of theData
        do shell script "open " & theData
on error
        display notification "Format not yet supported"
end try
