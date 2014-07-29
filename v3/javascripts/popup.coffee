---
---

Array.prototype.max = ()->
  Math.max.apply(null, @)

Array.prototype.min = ()->
  Math.min.apply(null, @)

toSortedArray = (hash)->
	tuples = []
	for k, v of hash
		tuples.push [k, v]

	tuples.sort (a,b)->
		a = a[1]
		b = b[1]
		a - b

	return tuples

prettyTime = (ms, withSeconds=false)->
	prependZeros = (number, decimal)->
		zeros = ''
		zeros += '0' for i in [0..decimal]
		(zeros + number).slice(-decimal)
	append = (output, amount, unit, carry)->
		# special case
		if unit == 'm' && amount > 0 && amount < 1
			return output = '< 1m'
		amount = Math.floor(amount)
		if amount > 0
			amount = amount % carry
			# padding zeros only for ms
			if unit == 'ms'
				amount = prependZeros(amount, 3)
			output = output + "#{amount}#{unit} "
		return output


	seconds = Math.round(ms / 1000 + 0.5) # not for presenting

	output = append('', seconds / 86400, 'd', 1)
	output = append(output, seconds / 3600, 'h', 24)
	output = append(output, seconds / 60, 'm', 60)
	if withSeconds
		output = append(output, seconds, 's', 60) 
		output = append(output, ms, 'ms', 1000) 
	return output

# main
printDate = (jqElement, d)->
	console.log 'print date'
	# TODAY - JUL 26 - SAT
	month = d.getMonth()
	date = d.getDate()
	theDay = d.getDay()

	getMonthStr = (m)->
		['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m]

	getDayStr = (day)->
		['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day]

	console.log jqElement
	jqElement.text("TODAY - #{getMonthStr(month).toUpperCase()} #{date} - #{getDayStr(theDay).toUpperCase()}")

printDate($('#date'), new Date)
trackedTime = 0
isPaused = false
chrome.storage.sync.get null, (hash)->
	console.log hash
	isPaused = hash['isPaused'] || false
	for k, v of hash
		if k == 'timesheet'
			for domain, millis of v
				trackedTime += millis
			for entry, i in toSortedArray(v).reverse()
				# print first 10 items
				if i < 10
					percent = Math.ceil(entry[1] * 100 / trackedTime - 0.5)
					tmplate = '<div class="item">
	                <div class="review-first">
	                    <span class="domain">'+entry[0]+'</span>
	                </div>
	                <div class="review-mid">
	                    <div class="percentage"><div style="width:'+percent+'%"></div></div>
	                    <span>'+percent+'%</span>
	                </div>
	                <div class="review-end">
	                    <span class="time">'+prettyTime(entry[1])+'</span>
	                </div>
	            </div>'
					$('.footer-item').before(tmplate)
				else
					break
			$('#total-tracked').text prettyTime(trackedTime, true)
	initialize()

# increase tracked time
increaseTrackedTime = ->
	$('#total-tracked').text prettyTime(trackedTime, true)
	trackedTime += 7
	if trackedTime <= 86400000 && !isPaused
		setTimeout ->
			increaseTrackedTime()
		, 7

initialize = ->
	increaseTrackedTime()
	# check if paused
	$('#tracker').removeClass 'spinnable' if isPaused

# stop tracking
$('#tracker').on 'mouseup', ->
	$(@).toggleClass 'spinnable'
	isPaused = !isPaused
	increaseTrackedTime() if !isPaused
	chrome.storage.sync.set {isPaused: isPaused}