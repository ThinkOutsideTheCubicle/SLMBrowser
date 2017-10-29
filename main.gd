extends Node

var checkList = ["secondlife.com", "id.secondlife.com", "marketplace.secondlife.com"]
var online = false
var firstStart = true

var myVersion = {
	appName			= Globals.get("application/name"),
	major			= 0, 
	minor			= 0,
	patch			= 1,
	status			= "pre-alpha",
	revision		= "stable",
	string			= "",
	url				= "https://github.com/ThinkOutsideTheCubicle/SLMBrowser/",
	licenseString	= ""
}

var settings = {
	myOS				= OS.get_name(),
	myDir				= OS.get_executable_path().get_base_dir(),
	rootPath			= "",
	curlPath			= "",
	curlCache			= "",
	cacheFolder			= "",
	useSSL				= false,
	basicImg			= load("res://images/empty.png"),
	infoImg				= load("res://images/info.png"),
	mpImg				= null,
	lastAnim			= "",
	infoImageSize_old	= Vector2(0, 0),
	infoImageSize_new	= Vector2(0, 0),
	infoImage_zoomed	= false,
	featuredLink		= "marketplace.secondlife.com",
	website				= ""
}

var lastSelectedMeta = []
var lastSelectedNode = null

var prodTreeNode
var prodTreeRoot
var prodTreeItems = []
var pMenuSize

var searchCreds = {
	loaded					= false,
	pages					= [1, 1], # [current, max]
	featuredItemList		= [], # [prodName, prodLink, imageLink, price, storeName, storeLink]
	featuredItemImages		= [],
	resultItems				= [], # [prodName, prodLink, imageLink, price, storeName, storeLink]
	resultItemImages		= [],
	categories				= [], # [id, name]
	pageCount				= [],
	sortBy					= [],
	filter_pages			= ['<div class="column span-6 last footer-paginate">', '<div id="footer-with-shadow">'],
	filter_cat				= ['<select id="top_search_category_id"', '</p>'],
	filter_logo				= ['<div class="features">', '</div>'],
	filter_fItems			= ['<h2>Featured Items</h2>', '<div id="recently-purchased'],
	filter_pItems			= ['<select id="per_page"', '</span>'],
	filter_sortBy			= ['<select id="search_sort_id"', '</span>'],
	filter_resultItems		= ['product-listing', 'footer-paginate']
}

var threadList = []
var maxFilesLoading = 1
var filesLoaded = 0
var oldFilesCount = 0

var dlQueue = { count = 0, getNext = true, doneCollecting = false, doneProcessing = false, items = [], toFile = [] }

var curlOutput = []
var threadQueue = []

var logNode
var searchLine
var old_searchString = ""

var client = {
	main			= null,
	localNet		= [false, "", ""], # connected, local IP, router/gateway IP
	peer			= null,
	currHost		= "",
	started			= false,
	joined			= false,
	connected		= false,
	connecting		= false
}

func _ready():
	client.main = StreamPeerTCP.new()
	client.peer = PacketPeerStream.new()
	pass

func init():
	debug.mainNode = get_node("/root/Node")
	logNode = get_node("ConsoleFrame/Console")
	logNode.set_scroll_follow(true)
	logNode.set_selection_enabled(true)
	
	debug.loadingDone = true
	
	myVersion.license = myVersion.url + "blob/master/LICENSE"
	myVersion.releases = myVersion.url + "releases"
	
	myVersion.string = myVersion.appName + " v" + str(myVersion.major) + "." + str(myVersion.minor) + "." + str(myVersion.patch) + " " + myVersion.status + " (" + myVersion.revision + ")"
	OS.set_window_title(myVersion.string + " | " + OS.get_name())
	
	myVersion.licenseString = "~~~[:: IMPORTANT ::]~~~\n"
	myVersion.licenseString += myVersion.string + "\n[url=" + myVersion.url + "]Source[/url] [url=" + myVersion.license + "]License[/url] [url=" + myVersion.releases + "]Releases[/url]\n\n"
	
	var gdsLink = "https://github.com/godotengine/godot"
	var llLink = "https://www.lindenlab.com"
	
	myVersion.licenseString += "Godot Version: " + OS.get_engine_version().values()[2] + "\n[url=" + gdsLink + "]Source[/url] [url=" + gdsLink + "/releases]Releases[/url] [url=https://godotengine.org]Homepage[/url]"
	myVersion.licenseString += "\n\nSecond Life® ([url=" + llLink + "]Linden Lab®[/url])\n[url=" + llLink + "/tos]Terms of Service[/url] [url=" + llLink + "/legal/second-life-terms-and-conditions]Terms and Conditions[/url] [url=" + llLink + "/privacy]Privacy Policy[/url]"
	
	debug.writeLog("LOG:", false, false)
	checkNetwork(true)
	
	checkCache()
	
	get_node("infoImage").set_tooltip("")
	get_node("infoImage").set_normal_texture(settings.basicImg)
	setPagesText()
	
	var logoName = "sl-mkt-logo.png"
	debug.writeLog("getting " + logoName)
	
	var args = ["-o", settings.cacheFolder + logoName, "http://slm-assets3.secondlife.com/assets/slm/sl-mkt-logo-c9535db2db237e9805a42625e777c278.png"]
	var resp = []
	OS.execute(settings.curlPath + "curl", args, true, resp)
	settings.mpImg = load(settings.cacheFolder + logoName)
	
	get_node("infoImage").set_normal_texture(settings.mpImg)
	removeCachedFile(logoName)
	
	get_node("searchPanel/useSSL_btn").set_pressed(settings.useSSL)
	setOptionsButton(settings.useSSL)
	
	prodTreeNode = get_node("prodTree")
	
	logNode.set_focus_mode(0)
	
	prodTreeNode.set_focus_mode(0)
	pMenuSize = get_node("PopupMenu").get_size()
	
	searchLine = get_node("searchPanel/searchEdit")
	
	debug.writeLog("loading search options")
	handleTree()
	
	getSource([false, [settings.featuredLink + "/products/search"]])
	pass

func addProtocoll(url = ""):
	var protURL = "http"
	if (settings.useSSL == true):protURL += "s"
	protURL += "://" + url
	return protURL

func setOptionsButton(setTo):
	
	settings.useSSL = setTo
	
	var toggleTo = false
	if (setTo == 0):toggleTo = true
	
	var setControl = get_node("searchPanel/catButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("searchPanel/sortbyButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("searchPanel/itemsCountButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("searchPanel/searchEdit")
	
	var placeholderText = "..."
	var newText = setControl.get_text()
	
	if (toggleTo == true):
		placeholderText = 'switch to "just search" if you want to find anything -->'
		newText = ""
	
	setControl.set_text(newText)
	
	setControl.set_editable(!toggleTo)
	setControl.set_focus_mode(!toggleTo)
	setControl.set_placeholder(placeholderText)
	
	get_node("searchPanel/OptionButton").select(!toggleTo)
	pass

func checkNetwork(printMsg=false):
	
	var output = []
	var currOS = OS.get_name()
	var addr = IP.get_local_addresses()
	var msg = "checking network\n\ncurrOS: " + str(currOS) + " | model=" + OS.get_model_name() + "\nuserdir=" + OS.get_data_dir()
	
	client.localNet = [false, "", ""]
	online = false
	
	if (currOS == "X11"):
		OS.execute("ip", ["route"], true, output)
		if (output.size() > 0):
			if (output[0] == ""):
				client.localNet = [false, "", "not connected!"]
			else:
				client.localNet[0] = true
				client.localNet[1] = output[0].split("src ")[1].split(" ")[0]
				client.localNet[2] = output[0].split("via ")[1].split(" ")[0]
	
	if (client.localNet[0] == false):
		
		if (currOS == "Windows"):
			if (addr.size() > 1):
				client.localNet[0] = true
				client.localNet[1] = addr[2]
				client.localNet[2] = "n/a"
		
		elif (currOS == "Android"):
			if (addr.size() > 2):
				client.localNet[0] = true
				client.localNet[1] = addr[1]
				client.localNet[2] = "n/a"
	
	if (client.localNet[0] == true):
		online = true
		
		if (client.localNet[1].is_valid_ip_address() == true):
			msg += "\n" + str(client.localNet[1]) + " is valid IP"
			
			if (client.localNet[2].is_valid_ip_address() == true):
				msg += "\n" + str(client.localNet[2]) + " is valid IP"
	
	if (printMsg == true):debug.writeLog(msg + "\nparsed local IP: " + str(client.localNet[1]) + "\nparsed Gateway/Router: " + str(client.localNet[2]) + "\n\nDEBUG:\naddr=" + str(addr) + "\nonline=" + str(online))
	return online

func checkCache():
	var exPath = OS.get_executable_path()
	var dbgMsg = "" # "exPath.get_base_dir=" + exPath.get_base_dir() + "\n"
	
	if (exPath.get_file().basename().split(".", false)[0].to_lower() == "godot"):settings.rootPath = "res:/"
	else:settings.rootPath = exPath.get_base_dir()
	
	var myDir = [Directory.new(), settings.rootPath]
	
	if (settings.myOS == "Windows"):
		myDir[1] += "\\cache\\"
	elif (settings.myOS == "X11"):
		if (myDir[1] == "res:/"):myDir[1] = "." # for editor only
		myDir[1] += "/cache/"
	
	if (myDir[0].dir_exists(myDir[1]) == false):
		var err = myDir[0].make_dir_recursive(myDir[1])
		dbgMsg += "creating cache folder | err=" + str(err) + " (0 = OK)\n"
	
	settings.cacheFolder = myDir[1]
	dbgMsg += "cache-folder=" + str(settings.cacheFolder)
	
	if (settings.myOS == "Windows"):
		settings.curlPath = settings.rootPath + "\\curl\\"
		settings.curlCache = ".\\cache\\"
	elif (settings.myOS == "X11"):
		settings.curlPath = ""
		settings.curlCache = "./cache/"
	
	dbgMsg += "\ncurlPath=" + str(settings.curlPath) + "\ncurlCache=" + str(settings.curlCache)
	debug.writeLog(dbgMsg)
	pass

func toggleImage():
	var imgNode = get_node("infoImage")
	settings.infoImageSize_old = imgNode.get_rect().size
	
	var vpSize = get_viewport().get_rect().size
	var newWidth = (vpSize.width - get_node("ConsoleFrame").get_size().width) - 30
	
	settings.infoImageSize_old = Vector2(newWidth, 220)
	settings.infoImageSize_new = vpSize - Vector2(20, 20)
	
	var animPlayer = get_node("AnimationPlayer")
	var cAnim = animPlayer.get_animation("zoomIn")
	
	cAnim.track_set_key_value(0, 0, settings.infoImageSize_old) # size
	cAnim.track_set_key_value(0, 1, settings.infoImageSize_new) # size
	
	cAnim = animPlayer.get_animation("zoomOut")
	
	cAnim.track_set_key_value(0, 0, settings.infoImageSize_new) # size
	cAnim.track_set_key_value(0, 1, settings.infoImageSize_old) # size
	
	# var setRect = settings.infoImageSize_old
	var setAnim = "zoomIn"
	
	if (settings.infoImage_zoomed == true):
		setAnim = "zoomOut"
	
	settings.infoImage_zoomed = !settings.infoImage_zoomed
	animPlayer.queue(setAnim)
	pass

func setImageIndex():
	var imgNode = get_node("infoImage")
	var setIndex = imgNode.get_parent().get_child_count() - 1
	var dbgVar = imgNode.get_position_in_parent()
	
	if (settings.infoImage_zoomed == false):setIndex = 1
	imgNode.get_parent().move_child(imgNode, setIndex)
	pass

func getSegment(baseStrArr, startStr, endStr, startIndex = 0):
	var returnArray = []
	var endIndex = -1
	
	for i in range(startIndex, baseStrArr.size()):
		if (baseStrArr[i].find(endStr) != -1):
			endIndex = i
			break
	
	if (endIndex != -1):
		for i in range(startIndex, endIndex):
			returnArray.append(baseStrArr[i])
	
	returnArray = [returnArray, endIndex]
	return returnArray

func fixedStrings(strArray):
	var retArray = []
	
	for i in range(strArray.size()):
		strArray[i] = strArray[i].replace("&amp;", '&')
		strArray[i] = strArray[i].replace("&quot;", '"')
		strArray[i] = strArray[i].replace("&#039;", "'")
		strArray[i] = strArray[i].replace("&#x27;", "'")
		strArray[i] = strArray[i].replace("&lt;", '<')
		strArray[i] = strArray[i].replace("&gt;", '>')
		
		retArray.append(strArray[i])
	return retArray

func betterImage(link):
	
	var qualID = get_node("searchPanel/imgQualityButton").get_selected()
	var qualityStr = "/" + get_node("searchPanel/imgQualityButton").get_item_text(qualID) + "/"
	
	link = link.replace("/view_small/", qualityStr)
	link = link.replace("/view_large/", qualityStr)
	link = link.replace("/thumbnail/", qualityStr)
	
	var retLink = link
	return retLink

func fillArray(sourceArray, resultTags):
	
	# resultTags [startTag, endTag, findLast, findLast, idxMod]
	
	var cutIDX = [-1, -1]
	var returnArray = []
	var result = []
	
	for idx in range(sourceArray.size()):
		
		for i in range(resultTags.size()):
			if (i == 0):
				result = []
				cutIDX = [-1, -1]
			
			var currTag = resultTags[i]
			
			cutIDX[0] = sourceArray[idx].find(currTag[0])
			if (currTag[2] == true):cutIDX[0] = sourceArray[idx].find_last(currTag[0])
			
			if (cutIDX[0] != -1):
				cutIDX[0] += currTag[4]
				
				cutIDX[1] = sourceArray[idx].find(currTag[1], cutIDX[0])
				if (currTag[3] == true):cutIDX[1] = sourceArray[idx].find_last(currTag[1])
			
			var resString = sourceArray[idx].substr(cutIDX[0], cutIDX[1] - cutIDX[0]).strip_edges()
			if (resString != ""):result.append(resString)
			
			if (i == resultTags.size() - 1 && result.size() > 0):
				result = fixedStrings(result)
				returnArray.append(result)
	return returnArray

func handleResults():
	# searchCreds.featuredItemImages = []
	curlOutput = curlOutput[0].split("\n")
	
	threadList = []
	var results = []
	var dbgStr = ""
	
	var fItems = []
	var idx = 0
	
	var subArray = []
	var startIDX = -1
	var endIDX = -1
	
	var getImages = { featuredItems = false, resultItems = false }
	var getCreds = []
	
	for i in range(curlOutput.size()):
		
		if (searchCreds.loaded == false):
			if (curlOutput[i].find(searchCreds.filter_pItems[0]) != -1):
				subArray = getSegment(curlOutput, searchCreds.filter_pItems[0], searchCreds.filter_pItems[1], i)
				
				if (subArray[1] != -1):
					
					# resultTags [startTag, endTag, findLast, findLast, idxMod]
					var setTags = []
					setTags.append(['">', '</option>', true, false, 2])
					
					searchCreds.pageCount = []
					searchCreds.pageCount = fillArray(subArray[0], setTags)
					
					i = subArray[1] + 1
			
			if (curlOutput[i].find(searchCreds.filter_sortBy[0]) != -1):
				subArray = getSegment(curlOutput, searchCreds.filter_sortBy[0], searchCreds.filter_sortBy[1], i)
				
				if (subArray[1] != -1):
					
					var setTags = []
					setTags.append(['<option value="', '"', true, false, 15])
					setTags.append(['">', '</option>', true, false, 2])
					
					searchCreds.sortBy = []
					searchCreds.sortBy = fillArray(subArray[0], setTags)
					
					i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_cat[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_cat[0], searchCreds.filter_cat[1], i)
			
			if (subArray[1] != -1):
				
				var setTags = []
				setTags.append(['<option value="', '">', false, false, 15])
				setTags.append(['">', '</option>', true, false, 2])
				
				searchCreds.categories = []
				searchCreds.categories = fillArray(subArray[0], setTags)
				
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_logo[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_logo[0], searchCreds.filter_logo[1], i)
			
			if (subArray[1] != -1):
				var linkStart = -1
				var fLine = ""
			
				for idx in range(subArray[0].size()):
					linkStart = subArray[0][idx].find('<a href="')
					
					if (linkStart != -1):
						fLine = subArray[0][idx]
						break
				
				results = ["", "", ""]
				
				if (linkStart > -1):
					linkStart += 9
					results[0] = fLine.substr(linkStart, fLine.find('" ', linkStart) - linkStart)
					
					linkStart = fLine.find('src="') + 5
					results[1] = fLine.substr(linkStart, fLine.find('" ', linkStart) - linkStart)
					results[1] = results[1].replace("https://", "")
					
					var endID = results[1].find("?")
					if (endID != -1):results[1] = results[1].substr(0, endID)
					
					linkStart = fLine.find('<img alt="') + 10
					results[2] = fLine.substr(linkStart, fLine.find('" ', linkStart) - linkStart)
					
					results = fixedStrings(results)
					
					getCreds.append([results[1], "featured.jpg", results[2]])
				
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_pages[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_pages[0], searchCreds.filter_pages[1], i)
			
			if (subArray[1] != -1):
				if (searchCreds.loaded == true):
					searchCreds.pages = []
					
					var setTags = []
					setTags.append(['class="current">', '</em>', false, false, 16])
					setTags.append(['">', '</a> <a class="next_page"', false, false, 2])
					var pageCreds = fillArray(subArray[0], setTags)[0]
					
					if (pageCreds.size() > 1):
						var modStr = pageCreds[1].split('">', false)
						pageCreds[1] = str(modStr[modStr.size() - 1])
					else:
						pageCreds.append(pageCreds[0])
					
					searchCreds.pages = pageCreds
					debug.writeLog(str(searchCreds.pages[1]) + " pages found!")
					setPagesText()
		
		if (curlOutput[i].find(searchCreds.filter_resultItems[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_resultItems[0], searchCreds.filter_resultItems[1], i)
			
			if (subArray[1] != -1):
				if (searchCreds.loaded == true):
					var modStr = ""
					var setTags = []
					setTags.append(['" class="product-title">', '</a>', false, false, 24])
					var altNames = fillArray(subArray[0], setTags)
					
					setTags = []
					
					setTags.append(['<a href="', '" class="product-image"', false, false, 9])
					setTags.append(['<img alt="', '" src="', false, false, 10])
					setTags.append(['" src="', '" /></a>', false, false, 7])
					var prodImages = fillArray(subArray[0], setTags)
					
					var orderedArr = []
					
					for idx in range(prodImages.size()):
						prodImages[idx][0] = settings.featuredLink + prodImages[idx][0]
						
						if (prodImages[idx].size() < 2):
							print("resultItems prodImages[" + str(idx) + "]=\n" + str(prodImages[idx]))
							prodImages[idx].insert(0, str(altNames[idx]))
						
						if (prodImages[idx][1] == "View_small"):prodImages[idx][1] = str(altNames[idx])
						
						orderedArr = []
						orderedArr.append(prodImages[idx][1])
						orderedArr.append(prodImages[idx][0])
						orderedArr.append(prodImages[idx][2])
						
						prodImages[idx] = orderedArr
					
					setTags = []
					setTags.append(['<span class="price">', '</span>', false, false, 20])
					var prodPrices = fillArray(subArray[0], setTags)
					
					setTags = []
					setTags.append(['"/stores/', '</a>', false, false, 1])
					var prodStores = fillArray(subArray[0], setTags)
					
					for idx in range(prodStores.size()):
						modStr = prodStores[idx][0].split('">')
						
						prodStores[idx][0] = modStr[1]
						prodStores[idx].append(modStr[0])
					
					var sameSize = false
					if (prodImages.size() == prodStores.size() && prodStores.size() == prodPrices.size()):sameSize = true
					
					if (sameSize == true):
						# debug.writeLog(testDbg)
						
						searchCreds.resultItems = []
						searchCreds.resultItemImages = []
						
						var maxSize = prodImages.size()
						searchCreds.resultItemImages.resize(maxSize)
						# [prodName, prodLink, imageLink, price, storeName, storeLink]
						var orderedArr = []
						
						for idx in range(maxSize):
							# orderedArr = []
							orderedArr = prodImages[idx]
							orderedArr += prodPrices[idx]
							orderedArr += prodStores[idx]
							
							searchCreds.resultItems.append(orderedArr)
					
					getImages.resultItems = true
					i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_fItems[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_fItems[0], searchCreds.filter_fItems[1], i)
			
			if (subArray[1] != -1):
				# var testDbg = ""
				var modStr = ""
				
				var setTags = []
				setTags.append(['" class="product-title">', '</a>', false, false, 24])
				var altNames = fillArray(subArray[0], setTags)
				
				setTags = []
				setTags.append(['<a href="', '?ple=h"', false, false, 9])
				setTags.append(['<img alt="', '" src="', false, false, 10])
				setTags.append(['" src="', '" /></a>', false, false, 7])
				
				var prodImages = fillArray(subArray[0], setTags)
				var orderedArr = []
				
				for idx in range(prodImages.size()):
					prodImages[idx][0] = settings.featuredLink + prodImages[idx][0]
					if (prodImages[idx][1] == "View_small"):prodImages[idx][1] = str(altNames[idx])
					
					if (prodImages[idx].size() < 2):
						print("prodImages[" + str(idx) + "]=\n" + str(prodImages[idx]))
						prodImages[idx].insert(0, str(altNames[idx]))
						
					orderedArr = []
					orderedArr.append(prodImages[idx][1])
					orderedArr.append(prodImages[idx][0])
					orderedArr.append(prodImages[idx][2])
					
					prodImages[idx] = orderedArr
				
				setTags = []
				setTags.append(['<span class="price">', '</span>', false, false, 20])
				var prodPrices = fillArray(subArray[0], setTags)
				
				setTags = []
				setTags.append(['"/stores/', '</a>', false, false, 1])
				var prodStores = fillArray(subArray[0], setTags)
				
				for idx in range(prodStores.size()):
					modStr = prodStores[idx][0].split('">')
					
					prodStores[idx][0] = modStr[1]
					prodStores[idx].append(modStr[0])
				
				var sameSize = false
				if (prodImages.size() == prodStores.size() && prodStores.size() == prodPrices.size()):sameSize = true
				
				if (sameSize == true):
					# debug.writeLog(testDbg)
					
					searchCreds.featuredItemList = []
					searchCreds.featuredItemImages = []
					
					var maxSize = prodImages.size()
					searchCreds.featuredItemImages.resize(maxSize)
					# [prodName, prodLink, imageLink, price, storeName, storeLink]
					var orderedArr = []
					
					for idx in range(maxSize):
						# orderedArr = []
						orderedArr = prodImages[idx]
						orderedArr += prodPrices[idx]
						orderedArr += prodStores[idx]
						
						searchCreds.featuredItemList.append(orderedArr)
					
					getImages.featuredItems = true
					i = subArray[1] + 1
	
	var setButton = get_node("searchPanel/catButton")
	setButton.clear()
	
	debug.writeLog(str(searchCreds.categories.size()) + " Categories found")
	
	for i in range(searchCreds.categories.size()):
		var addStr = searchCreds.categories[i][0]
		
		#debug purposes
		if (searchCreds.categories[i].size() > 1):
			addStr += " - " + searchCreds.categories[i][1]
		
		setButton.add_item(addStr)
	
	var postLic = false
	
	if (searchCreds.loaded == false):
		searchCreds.loaded = true
		
		get_node("searchPanel/getButton").set_disabled(false)
		debug.writeLog("loading done!")
		
		postLic = true
		
		setButton = get_node("searchPanel/itemsCountButton")
		setButton.clear()
		
		for i in range(searchCreds.pageCount.size()):
			setButton.add_item(searchCreds.pageCount[i][0])
		
		setButton = get_node("searchPanel/sortbyButton")
		setButton.clear()
		
		for i in range(searchCreds.sortBy.size()):
			setButton.add_item(searchCreds.sortBy[i][1])
	
	var url = ""
	var pBar = get_node("ProgressBar")
	pBar.set_val(0)
	
	if (getImages.featuredItems == true):
		
		pBar.set_max(searchCreds.featuredItemList.size())
		debug.writeLog(str(searchCreds.featuredItemList.size()) + " Featured Items found")
		
		for i in range(searchCreds.featuredItemList.size()):
			pBar.set_val(i)
			
			var name = "fi_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = searchCreds.featuredItemList[i][2].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getImages.resultItems == true):
		pBar.set_max(searchCreds.resultItems.size())
		debug.writeLog(str(searchCreds.resultItems.size()) + " Search Results found")
		
		for i in range(searchCreds.resultItems.size()):
			pBar.set_val(i)
			
			var name = "ri_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = searchCreds.resultItems[i][2].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getCreds.size() > 0):
		getSource([true, getCreds])
	
	if (postLic == true):debug.writeLog(myVersion.licenseString, true, false)
	pass

func getSource(creds):
	
	creds.insert(1, threadList.size())
	# print("creds=" + str(creds))
	
	var newThread = Thread.new()
	newThread.start(self, "threadFunc", creds)
	threadList.append([newThread, creds[0], false])
	
	# print("threadList=" + str(threadList))
	pass

func threadFunc(userdata):
	
	# userdata = [toFile, threadID, urlList=[], nameList=[]/idList=[]]
	
	# userdata = [toFile, threadID, [creds]]
	# creds = [url, name, id]
	
	var pBar = get_node("ProgressBar")
	var toFile = userdata[0]
	var myID = userdata[1]
	var creds = userdata[2]
	
	debug.writeLog("thread " + str(myID) + " started. | toFile=" + str(toFile))
	
	for i in range(creds.size()):creds[i][0] = addProtocoll(creds[i][0])
	
	pBar.set_val(0)
	pBar.set_max(creds.size())
	
	var args = ["-L", "-g", "-b", settings.cacheFolder + "cookies.txt", "-c", settings.cacheFolder + "cookies.txt", creds[0]]
	
	if (toFile == true):
		
		maxFilesLoading = creds.size()
		debug.writeLog("downloading " + str(maxFilesLoading) + " images via cURL, please be patient!")
		
		args = ["-g", "-K", settings.curlCache + "links.txt"]
		var fileString = ""
		
		for i in range(creds.size()):
			fileString += "-o " + settings.curlCache + creds[i][1] + '\nurl="' + creds[i][0] + '"\n'
		
		var newFile = File.new()
		newFile.open(settings.cacheFolder + "links.txt", newFile.WRITE)
		newFile.store_string(fileString)
		newFile.close()
		debug.writeLog("links to links.txt stored, downloading files ..")
		
	var results = []
	OS.execute(settings.curlPath + "curl", args, true, results)
	
	if (toFile == false):
		curlOutput = results
	else:
		removeCachedFile("links.txt", true)
		
		var fileDir = Directory.new()
		var goAhead = false
		var name = ""
		var fileName = ""
		var id = -1
		
		for i in range(creds.size()):
			pBar.set_val(i)
			
			name = creds[i][1]
			id = creds[i][2]
			fileName = settings.cacheFolder + name
			goAhead = fileDir.file_exists(fileName)
			
			if (goAhead == true):
				
				var tmpImg = load(fileName)
				
				if (name == "featured.jpg"):
					get_node("infoImage").set_normal_texture(tmpImg)
					get_node("infoImage").set_tooltip(id)
				
				if (name.begins_with("fi_") == true):
					searchCreds.featuredItemImages[id] = tmpImg
				
				if (name.begins_with("ri_") == true):
					searchCreds.resultItemImages[id] = tmpImg
				removeCachedFile(name)
			else:
				debug.writeLog("warning, " + fileName + " could not be loaded!")
				print("error on image " + str(i) + "\n" + str(creds[i]))
	handleTree()
	threadList[myID][2] = true
	return 0

func removeCachedFile(name, dbgMode = false):
	var dir = Directory.new()
	var err = dir.file_exists(settings.cacheFolder + name)
	var dbgMsg = name + " is "
	
	if (err == true):
		dbgMsg += "existing and has "
		
		err = dir.remove(settings.cacheFolder + name)
		
		if (err == 1):dbgMsg += "NOT "
		dbgMsg += "been sucessfully deleted!"
	else:dbgMsg += "NOT existing!"
	
	if (dbgMode == true):debug.writeLog(dbgMsg + " (err=" + str(err) + ")")
	pass

func handleTree():
	var maxImgWitdh = 60
	
	prodTreeItems.clear()
	prodTreeNode.clear()
	prodTreeRoot = prodTreeNode.create_item()
	
	prodTreeNode.set_hide_root(true)
	prodTreeNode.set_select_mode(1)
	prodTreeNode.set_hide_folding(true)
	prodTreeNode.set_column_titles_visible(true)
	prodTreeNode.set_allow_rmb_select(true)
	
	# prodTreeNode.set_single_select_cell_editing_only_when_already_selected(true)
	
	prodTreeNode.set_columns(1)
	
	# prodTreeNode.set_column_title(0, "Store")
	# prodTreeNode.set_column_expand(0, false)
	# prodTreeNode.set_column_min_width(0, maxImgWitdh + 20)
	
	prodTreeNode.set_column_title(0, "Products")
	prodTreeNode.set_column_expand(0, true)
	# prodTreeNode.set_column_min_width(0, 50)
	
	# prodTreeNode.set_column_title(2, "Store")
	# prodTreeNode.set_column_expand(2, false)
	# prodTreeNode.set_column_min_width(2, 250)
	
	# prodTreeNode.set_column_title(2, "Price")
	# prodTreeNode.set_column_expand(2, false)
	# prodTreeNode.set_column_min_width(2, 150)
	
	if (searchCreds.featuredItemList.size() > 0):
		var basetem = prodTreeNode.create_item(prodTreeRoot)
		basetem.set_text(0, "FEATURED ITEMS:")
	
		for i in range(searchCreds.featuredItemList.size()):
			
			# [prodName, prodLink, imageLink, price, storeName, storeLink]
			var newItem = prodTreeNode.create_item(basetem)
			
			# var fillImage = ImageTexture.new()
			var fillImage = settings.basicImg
			
			var arrImage = null
			
			if (searchCreds.featuredItemImages.size() > i):
				if (searchCreds.featuredItemImages[i] != null):
					arrImage = searchCreds.featuredItemImages[i].get_data()
			
			if (arrImage != null):
				fillImage = ImageTexture.new()
				fillImage.create_from_image(arrImage)
				
				var imgSize = Vector2(arrImage.get_width(), arrImage.get_height())
				var resizeFactor = imgSize.width / maxImgWitdh
				if (imgSize.height > imgSize.width):resizeFactor = imgSize.height / maxImgWitdh
				fillImage.set_size_override(imgSize / resizeFactor)
			
			newItem.set_editable(0, true)
			newItem.set_cell_mode(0, 5)
			
			var newMeta = [i, 0, "fi"]
			
			if (lastSelectedMeta != [] && i == lastSelectedMeta[0]):newMeta = lastSelectedMeta
			newItem.set_metadata(0, newMeta)
			
			var itemText = searchCreds.featuredItemList[i][0] + " | Price: " + searchCreds.featuredItemList[i][3]
			if (newMeta[1] == 1):itemText = searchCreds.featuredItemList[i][4]
			newItem.set_text(0, itemText)
			
			newItem.set_icon(0, fillImage)
			newItem.set_icon_max_width(0, maxImgWitdh)
			
			fillImage = ImageTexture.new()
			fillImage.create_from_image(settings.infoImg.get_data())
			fillImage.set_size_override(Vector2(maxImgWitdh, maxImgWitdh))
			
			newItem.add_button(0, fillImage)
			
			prodTreeItems.append(newItem)
	
	if (searchCreds.resultItems.size() > 0):
		var basetem = prodTreeNode.create_item(prodTreeRoot)
		basetem.set_text(0, "FOUND ITEMS:")
		
		for i in range(searchCreds.resultItems.size()):
			
			# [prodName, prodLink, imageLink, price, storeName, storeLink]
			var newItem = prodTreeNode.create_item(basetem)
			var fillImage = settings.basicImg
			
			var arrImage = null
			
			if (searchCreds.resultItemImages.size() > i):
				if (searchCreds.resultItemImages[i] != null):
					arrImage = searchCreds.resultItemImages[i].get_data()
			
			if (arrImage != null):
				fillImage = ImageTexture.new()
				fillImage.create_from_image(arrImage)
				
				var imgSize = Vector2(arrImage.get_width(), arrImage.get_height())
				var resizeFactor = imgSize.width / maxImgWitdh
				if (imgSize.height > imgSize.width):resizeFactor = imgSize.height / maxImgWitdh
				fillImage.set_size_override(imgSize / resizeFactor)
			
			newItem.set_editable(0, true)
			newItem.set_cell_mode(0, 5)
			
			var newMeta = [i, 0, "ri"]
			
			if (lastSelectedMeta != [] && i == lastSelectedMeta[0]):newMeta = lastSelectedMeta
			newItem.set_metadata(0, newMeta)
			
			var itemText = searchCreds.resultItems[i][0] + " | Price: " + searchCreds.resultItems[i][3]
			if (newMeta[1] == 1):itemText = searchCreds.resultItems[i][4]
			newItem.set_text(0, itemText)
			
			newItem.set_icon(0, fillImage)
			newItem.set_icon_max_width(0, maxImgWitdh)
			
			fillImage = ImageTexture.new()
			fillImage.create_from_image(settings.infoImg.get_data())
			fillImage.set_size_override(Vector2(maxImgWitdh, maxImgWitdh))
			
			newItem.add_button(0, fillImage)
			prodTreeItems.append(newItem)
	pass

var lastOptions = {
	changed			= false,
	categories		= -1,
	itemsCount		= -1,
	sortBy			= -1,
	keywords		= ""
}

func runSearch():
	if (checkNetwork() == false):
		debug.writeLog("obviously you have no internet connection!")
	
	else:
		curlOutput = []
		threadList = []
		
		searchCreds.featuredItemList = []
		searchCreds.featuredItemImages = []
		searchCreds.resultItems = []
		searchCreds.resultItemImages = []
		
		prodTreeItems.clear()
		prodTreeNode.clear()
		
		get_node("infoImage").set_normal_texture(settings.mpImg)
		get_node("infoImage").set_tooltip("")
		
		lastOptions.changed = false
		
		var setPages = [1, 1]
		var setURL = settings.featuredLink
		
		var btnID = get_node("searchPanel/OptionButton").get_selected_ID()
		
		if (btnID == 1):# searchLine.get_text() != ""
			
			btnID = get_node("searchPanel/catButton").get_selected()
			if (btnID != lastOptions.categories):
				lastOptions.changed = true
				lastOptions.categories = btnID
			
			var searchTags = "&search[category_id]=" + searchCreds.categories[btnID][0]
			
			if (btnID == 0):searchTags = ""
			
			btnID = get_node("searchPanel/itemsCountButton").get_selected()
			if (btnID != lastOptions.itemsCount):
				lastOptions.changed = true
				lastOptions.itemsCount = btnID
			
			searchTags += "&search[per_page]=" + searchCreds.pageCount[btnID][0]
			
			btnID = get_node("Panel/pagesBox").get_value()
			if (btnID <= float(searchCreds.pages[1])):
				btnID = get_node("Panel/pagesBox").get_value()
			else:
				btnID = 1
			
			setPages = [btnID, searchCreds.pages[1]]
			
			searchTags += "&search[page]=" + str(btnID)
			
			btnID = get_node("searchPanel/sortbyButton").get_selected()
			if (btnID != lastOptions.sortBy):
				lastOptions.changed = true
				lastOptions.sortBy = btnID
			
			searchTags += "&search[sort]=" + searchCreds.sortBy[btnID][0]
			
			var cText = get_node("searchPanel/searchEdit").get_text()
			
			if (lastOptions.keywords != cText):
				lastOptions.changed = true
				lastOptions.keywords = cText
			
			if (lastOptions.changed == true):
				setPages = [1, 1]
			
			searchTags += "&search[keywords]=" + cText
			setURL += "/products/search?" + searchTags
		
		settings.website = setURL
		searchCreds.pages = setPages
		
		setPagesText()
		
		debug.writeLog("loading " + setURL)
		getSource([false, [setURL]])
		# dlSource(setURL, [])
	pass

func setPagesText():
	var pBox = get_node("Panel/pagesBox")
	var textArr = ["Page " + str(searchCreds.pages[0]), "of " + str(searchCreds.pages[1])]
	
	pBox.set_value(float(searchCreds.pages[0]))
	pBox.set_max(float(searchCreds.pages[1]))
	
	pBox.set_tooltip(textArr[0] + " " + textArr[1])
	pBox.set_suffix(textArr[0])
	pBox.set_suffix(textArr[1])
	
	var pSlider = get_node("Panel/pagesSlider")
	pSlider.set_value(float(searchCreds.pages[0]))
	pSlider.set_max(float(searchCreds.pages[1]))
	pass

func _on_Timer_timeout():
	
	if (firstStart == true):
		firstStart = false
		init()
	
	var maxThreads = threadList.size()
	
	if (maxThreads > 0):
		var pBar = get_node("ProgressBar")
		var fileDownload = false
		
		for i in range(maxThreads):
			
			var tItem = threadList[i]
			if (tItem[1] == true):fileDownload = true
			
			if (tItem[2] == true && tItem.size() == 3):
				threadList[i].append(true)
				threadList[i][0].wait_to_finish()
		
		var threadsCompleted = 0
		for i in range(maxThreads):
			if (threadList[i][0].is_active() == false):
				threadsCompleted += 1
		
		if (searchCreds.loaded == true):
			filesLoaded = 0
			
			var tmpDir = Directory.new()
			
			if (tmpDir.open(settings.cacheFolder + "/") == OK):
				tmpDir.list_dir_begin()
				var file_name = tmpDir.get_next()
				
				while (file_name != ""):
					if (tmpDir.current_is_dir() == false && file_name != "cookies.txt" && file_name != "links.txt"):
						filesLoaded += 1
					file_name = tmpDir.get_next()
			else:
				print("An error occurred when trying to access the path.")
			
			if (filesLoaded > 0 && oldFilesCount < filesLoaded):
				oldFilesCount = filesLoaded
				# print("filesLoaded=" + str(filesLoaded))
				
				if(filesLoaded <= maxFilesLoading):
					pBar.set_val(filesLoaded)
		
		if (threadsCompleted == maxThreads):
			threadList.clear()
			
			if (fileDownload == true):
				# handleTree()
				debug.writeLog("loading finished!")
			else:handleResults()
			
			pBar.set_val(maxThreads)
			pBar.set_max(maxThreads)
			
			filesLoaded = 0
			oldFilesCount = 0
	pass

func _on_AnimationPlayer_animation_started(name):
	settings.lastAnim = name
	
	if (settings.lastAnim == "zoomIn"):
		setImageIndex()
	pass

func _on_AnimationPlayer_finished():
	if (settings.lastAnim == "zoomOut"):
		setImageIndex()
	pass

func _on_prodTree_item_selected():
	if (lastSelectedNode != prodTreeNode.get_selected()):
		lastSelectedNode = prodTreeNode.get_selected()
		
		lastSelectedMeta = lastSelectedNode.get_metadata(0)
		
		if (lastSelectedMeta != null):
			var getItemID = lastSelectedMeta[0]
			
			if (lastSelectedMeta[2] == "fi" && searchCreds.featuredItemImages.size() > getItemID):
				get_node("infoImage").set_normal_texture(searchCreds.featuredItemImages[getItemID])
				get_node("infoImage").set_tooltip(searchCreds.featuredItemList[getItemID][0])
			
			elif (lastSelectedMeta[2] == "ri" && searchCreds.resultItemImages.size() > getItemID):
				get_node("infoImage").set_normal_texture(searchCreds.resultItemImages[getItemID])
				get_node("infoImage").set_tooltip(searchCreds.resultItems[getItemID][0])
	pass

func _on_prodTree_custom_popup_edited(arrow_clicked):
	if (Input.is_mouse_button_pressed(2) == true):
		var selectedItem = prodTreeNode.get_edited()
		var itemRect = prodTreeNode.get_custom_popup_rect()
		
		var pMenu = get_node("PopupMenu")
		pMenu.clear()
		
		pMenu.set_pos(itemRect.pos)
		pMenu.set_size(pMenuSize)
		
		var getCreds = searchCreds.resultItems
		if (settings.website == settings.featuredLink):
			getCreds = searchCreds.featuredItemList
		
		pMenu.add_check_item("select product --> " + getCreds[lastSelectedMeta[0]][0] + " | Price: " + getCreds[lastSelectedMeta[0]][3])
		pMenu.add_check_item("select shop --> " + getCreds[lastSelectedMeta[0]][4])
		
		pMenu.set_item_checked(0, false)
		pMenu.set_item_checked(1, false)
		
		pMenu.set_item_checked(lastSelectedMeta[1], true)
		pMenu.popup()
	pass

func _on_PopupMenu_item_pressed(ID):
	lastSelectedMeta[1] = ID
	handleTree()
	pass

func _on_Console_meta_clicked(meta):
	OS.shell_open(meta)
	pass

func _on_searchEdit_focus_enter():
	# searchLine.select_all()
	pass 

func _on_searchEdit_text_entered(text):
	if (text != ""):debug.writeLog("text=" + text)
	searchLine.release_focus()
	pass

func _on_prodTree_button_pressed(item, column,id):
	var itemMeta = item.get_metadata(0)
	var getInfoStr
	
	if (itemMeta[2] == "fi"):
		getInfoStr = searchCreds.featuredItemList[itemMeta[0]][1]
		if (itemMeta[1] == 1):getInfoStr = settings.featuredLink + searchCreds.featuredItemList[itemMeta[0]][5]
		# openInfo.append(getInfoStr)
	elif (itemMeta[2] == "ri"):
		getInfoStr = searchCreds.resultItems[itemMeta[0]][1]
		if (itemMeta[1] == 1):getInfoStr = settings.featuredLink + searchCreds.resultItems[itemMeta[0]][5]
		# openInfo.append(getInfoStr)
	
	getInfoStr = addProtocoll(getInfoStr)
	debug.writeLog("opening " + getInfoStr)
	
	OS.shell_open(getInfoStr)
	pass

func _on_pagesSlider_value_changed(value):
	get_node("Panel/pagesBox").set_value(value)
	pass
