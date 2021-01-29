tell application "Google Chrome"
	set i to 1
	set tabsToDelete to {}
	
	repeat with t in (tabs of (first window))
		if i is greater than (active tab index of (first window)) then
			set beginning of tabsToDelete to t
		end if
		set i to i + 1
	end repeat
	
	repeat with t in tabsToDelete
		close t
	end repeat
end tell
