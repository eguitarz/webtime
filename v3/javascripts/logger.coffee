---
---

currentTab = null
logStartTime = null

String.prototype.capitalize = ->
	@charAt(0).toUpperCase() + @slice(1)

Date.prototype.getDateStr = ->
	"#{@getFullYear()}-#{@getMonth()+1}-#{@getDate()}"

logTime = (newtab, stopLogging=false)->
	if !currentTab || !newtab
		currentTab = newtab
		return
	
	if currentTab
		if logStartTime
			# log time
			domainStr = parseDomain(currentTab.url).capitalize()
			chrome.storage.sync.get domainStr, (result)->
				records = result[domainStr]
				records = [] unless result[domainStr]
				records.push { domain: domainStr, url: currentTab.url, startAt: logStartTime, duration: new Date() - logStartTime }
				recordsEntry = {}
				recordsEntry[domainStr] = records
				chrome.storage.sync.set recordsEntry
			
				chrome.storage.sync.get null, (results)->
					if results && results.lastLogTime
						currentDate = new Date
						if result.lastLogTime && currentDate.getDateStr() != result.lastLogTime.getDateStr()
							chrome.storage.sync.clear()
						entry = {}
						entry.lastLogTime = currentDate.getDateStr()
						chrome.storage.sync.set entry
					else
						entry = {}
						entry.lastLogTime = (new Date).getDateStr()
						chrome.storage.sync.set entry

		if stopLogging
			logStartTime = null			
		else
			logStartTime = new Date() 

	currentTab = newtab
		


chrome.tabs.onActivated.addListener (e)->
	chrome.tabs.get e.tabId, (tab)->
		logTime(tab)
		# console.log tab.url

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab)->
	if changeInfo.status == 'loading'# && tab.active
		logTime(tab)
		# console.log tab.url

chrome.windows.onFocusChanged.addListener (windowId)->
	if windowId == chrome.windows.WINDOW_ID_NONE
		logTime(currentTab, true)
	else
		chrome.tabs.query {windowId: windowId, active: true}, (tabs)->
			logTime(tabs[0])

parseDomain = (url)->
	url.match(/:\/\/(?:www\.)?(.[^/]+)(.*)/)[1]