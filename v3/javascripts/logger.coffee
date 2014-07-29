---
---

currentTab = null
logStartTime = null

String.prototype.capitalize = ->
	@charAt(0).toUpperCase() + @slice(1)

Date.prototype.getDateStr = ->
	"#{@getFullYear()}-#{@getMonth()+1}-#{@getDate()}"

addDurationToTimesheet = (domain, timesheet, duration)->
	timesheet[domain] = 0 unless timesheet[domain]
	timesheet[domain] = timesheet[domain] + duration
	return

pushRecordToArray = (recordArray, tab, startAt, duration)->
	# records = entries[domainStr]
	# records = [] unless result[domainStr]
	recordArray = [] unless recordArray
	recordArray.push { url: tab.url, title: tab.title, startAt: startAt, duration: duration }
	recordArray
	# recordsEntry = {}
	# recordsEntry[domainStr] = records
	# chrome.storage.sync.set recordsEntry


logTime = (newtab, stopLogging=false)->
	if !currentTab || !newtab
		currentTab = newtab
		return
	
	if currentTab
		if logStartTime
			# log time
			domainStr = parseDomain(currentTab.url).capitalize()
			duration = new Date() - logStartTime
			currentDate = new Date
			
			chrome.storage.sync.get null, (results)->
				console.log results
				# save records, easy to exceed quota, disabled now
				# entries = {}
				# domainRecords = pushRecordToArray(results[domainStr], currentTab, logStartTime, duration)
				# entries[domainStr] = domainRecords
				# chrome.storage.sync.set entries
				return if results.isPaused
				entries = {}

				timesheet = results.timesheet || {}
				addDurationToTimesheet(domainStr, timesheet, duration)
				entries.timesheet = timesheet

				# clear if it's a new date
				if results['lastLogTime'] && currentDate.getDateStr() != results.lastLogTime
					chrome.storage.sync.clear ->
						entries = {}
						currentTab = newtab
						entries.lastLogTime = currentDate.getDateStr()
						chrome.storage.sync.set entries			
					return
				
				console.log "Save #{domainStr} to timesheet for #{duration} ms. Total: #{timesheet[domainStr] / 1000} s"
				chrome.storage.sync.set entries

		if stopLogging
			logStartTime = null			
		else
			logStartTime = new Date() 

	currentTab = newtab
		


chrome.tabs.onActivated.addListener (e)->
	chrome.tabs.get e.tabId, (tab)->
		console.log "onActivated: #{tab.url}"
		logTime(tab)
		# console.log tab.url

chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab)->
	console.log "onUpdated: #{tab.url}"
	if changeInfo.status == 'loading'# && tab.active
		logTime(tab)
		# console.log tab.url

chrome.windows.onFocusChanged.addListener (windowId)->
	if windowId == chrome.windows.WINDOW_ID_NONE
		console.log 'onFocusChanged: NONE'
		logTime(currentTab, true)
	else
		chrome.tabs.query {windowId: windowId, active: true}, (tabs)->
			console.log "onFocusChanged: #{tabs[0].url}"
			logTime(tabs[0])

parseDomain = (url)->
	url.match(/:\/\/(?:www\.)?(.[^/]+)(.*)/)[1]