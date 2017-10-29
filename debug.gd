extends Node

var mainNode
var currentLog = ""
var loadingDone = false
var getLoadedLog = true
var logFolderCheckDone = false

func _ready():
	pass

func writeLog(message, useBB=false, useDate=true):
	message = "\n" + message
	
	if (useDate == true):message = "\n[::" + getNowString(true, true) + "::]" + message
	
	currentLog += message
	
	if (loadingDone == true):
		var logNode = mainNode.logNode
		
		if (useBB == true):logNode.append_bbcode(message)
		else:logNode.add_text(message)
		
		logNode.newline()
		logNode.update()
		# logNode.grab_focus()
	pass

func getNowString(date, time, tSep = "-"):
	# [dst, second, month, day, hour, year, minute, weekday]
	var dt = OS.get_datetime()
	var retStr = ""
	
	if (date):
		if (dt.day < 10):retStr += "0"
		retStr += str(dt.day) + "-"
		if (dt.month < 10):retStr += "0"
		retStr += str(dt.month) + "-" + str(dt.year)
	
	if (date && time):retStr += "_"
	
	if (time):
		if (dt.hour < 10):retStr += "0"
		retStr += str(dt.hour) + tSep
		if (dt.minute < 10):retStr += "0"
		retStr += str(dt.minute) + tSep
		if (dt.second < 10):retStr += "0"
		retStr += str(dt.second)
	
	return retStr