extends Node

var checkList = ["secondlife.com", "id.secondlife.com", "marketplace.secondlife.com"]
var online = false
var firstStart = true
var oldSize = Vector2(0, 0)

var myVersion = {
	appName			= Globals.get("application/name"),
	major			= 0, 
	minor			= 0,
	patch			= 2,
	status			= "alpha",
	revision		= "unstable",
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
	basicImg			= load("res://assets/images/empty.png"),
	nullImg				= load("res://assets/images/no_image.png"),
	infoImg				= load("res://assets/images/info.png"),
	mpImg				= null,
	lastAnim			= "",
	infoImageSize_old	= Vector2(0, 0),
	infoImageSize_new	= Vector2(0, 0),
	infoImage_zoomed	= false,
	infoImage_treeID	= -1,
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
	parseDetails			= false,
	mainSearchSubmitID		= 0,
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
	filter_resultItems		= ['product-listing', 'footer-paginate'],
	filter_detailTitle		= ['<head>', '</head>'],
	filter_detailImgs		= ['<div id="main-image" class="span-4">', '<div class="modal'],
	filter_description		= ['<div id="product-description"', '<div id="product-contents"'],
	filter_detailCreds		= ['<p class="prices">', '"marketplace-sprite flag-item"'],
	filter_storeInfo		= ['<div id="merchant-box" class="clear">', '<div class="clear"></div>'],
	filter_storeInfo_search	= ['"/stores/', ''],
	filter_relatedItems		= ['<div id="product-related-items" class="clear span-8">', '<div id="sponsored-links">']
}

var threadList = []
var maxFilesLoading = 1
var filesLoaded = 0
var oldFilesCount = 0

var dlQueue = { count = 0, getNext = true, doneCollecting = false, doneProcessing = false, items = [], toFile = [] }

var curlOutput = []
var threadQueue = []

var logNode
var old_searchString = ""
var loadStatus = ""
var resetTagCounter = 0

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

var lastOptions = {
	changed			= false,
	categories		= -1,
	itemsCount		= -1,
	sortBy			= -1,
	keywords		= ""
}

var infoPanel
var prodCreds = []

var infoCreds = {
	loaded			= false,
	isStore			= false,
	title			= "",
	detailCreds		= [], # [price, demo, perms, useage]
	description		= "",
	infoImages		= [],
	storeInfo		= [],
	relatedItems	= [],
	relatedTitle	= "",
	shopItems		= [], # [prodName, prodLink, imageLink, price, storeName, storeLink]
	shopItemImages	= [],
	pages			= [1, 1], # [current, max]
	pageCount		= [],
	sortBy			= [],
	lastOptions		= {
		changed			= false,
		queued			= false,
		grabbed			= true,
		currPage		= 1,
		itemsCount		= 0,
		sortBy			= 0,
		keywords		= "",
		storeLink		= ""
	}
}

func _ready():
	client.main = StreamPeerTCP.new()
	client.peer = PacketPeerStream.new()
	pass

func init():
	debug.mainNode = get_node("/root/Node")
	logNode = get_node("consolePanel/Console")
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
	
	myVersion.licenseString += "\n\nExo 2.0 font family made by ndiscovered\nis licensed under the [url=http://scripts.sil.org/OFL]SIL Open Font License (OFL)[/url]"
	
	debug.writeLog("LOG:", false, false)
	checkNetwork(true)
	
	checkCache()
	
	get_node("imagePanel/infoImage").set_tooltip("")
	get_node("imagePanel/infoImage").set_normal_texture(settings.basicImg)
	# setPagesText()
	
	var logoName = "sl-mkt-logo.png"
	debug.writeLog("getting " + logoName)
	
	var args = ["-o", settings.cacheFolder + logoName, "http://slm-assets3.secondlife.com/assets/slm/sl-mkt-logo-c9535db2db237e9805a42625e777c278.png"]
	var resp = []
	OS.execute(settings.curlPath + "curl", args, true, resp)
	settings.mpImg = load(settings.cacheFolder + logoName)
	
	get_node("imagePanel/infoImage").set_normal_texture(settings.mpImg)
	removeCachedFile(logoName)
	
	get_node("cPanel/useSSL_btn").set_pressed(settings.useSSL)
	setOptionsButton(1)
	
	prodTreeNode = get_node("cPanel/prodTree")
	
	logNode.set_focus_mode(0)
	
	prodTreeNode.set_focus_mode(0)
	pMenuSize = get_node("PopupMenu").get_size()
	
	loadStatus = "loading search options"
	debug.writeLog(loadStatus)
	handleTree()
	
	getSource([false, [settings.featuredLink + "/products/search"]])
	pass

func addProtocoll(url = ""):
	var protURL = "http"
	if (settings.useSSL == true):protURL += "s"
	protURL += "://" + url
	return protURL

func setOptionsButton(setTo):
	get_node("cPanel/OptionButton").select(setTo)
	
	var toggleTo = false
	if (setTo == 0):toggleTo = true
	
	var setControl = get_node("cPanel/catButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("cPanel/sortbyButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("cPanel/itemsCountButton")
	setControl.set_disabled(toggleTo)
	
	setControl = get_node("cPanel/searchEdit")
	
	var placeholderText = "..."
	var newText = setControl.get_text()
	
	if (toggleTo == true):
		placeholderText = 'switch to "just search" if you want to find anything -->'
		newText = ""
	
	setControl.set_text(newText)
	
	setControl.set_editable(!toggleTo)
	setControl.set_focus_mode(!toggleTo)
	setControl.set_placeholder(placeholderText)
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
	var imgNode = get_node("imagePanel")
	settings.infoImageSize_old = imgNode.get_rect().size
	
	var vpSize = get_viewport().get_rect().size
	var newWidth = (vpSize.width - get_node("consolePanel").get_size().width) - 30
	
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
	
	if (settings.infoImage_zoomed == false):
		settings.infoImage_treeID = imgNode.get_position_in_parent()
	else:
		setAnim = "zoomOut"
	
	settings.infoImage_zoomed = !settings.infoImage_zoomed
	animPlayer.queue(setAnim)
	pass

func setImageIndex():
	var imgNode = get_node("imagePanel")
	var setIndex = settings.infoImage_treeID
	if (settings.infoImage_zoomed == true):setIndex = imgNode.get_parent().get_child_count() - 1
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
		strArray[i] = strArray[i].replace("&#174;", '®')
		strArray[i] = strArray[i].replace("&raquo;", '»')
		
		
		retArray.append(strArray[i])
	return retArray

func betterImage(link):
	
	var qualID = get_node("cPanel/imgQualityButton").get_selected()
	var qualityStr = "/" + get_node("cPanel/imgQualityButton").get_item_text(qualID) + "/"
	
	link = link.replace("/view_small/", qualityStr)
	link = link.replace("/view_large/", qualityStr)
	link = link.replace("/thumbnail/", qualityStr)
	
	var retLink = link
	return retLink

func thumbImage(maxWitdh, image):
	
	# var imgType = image.get_type()
	# print("imgType=" + str(imgType))
	
	# var fillImage = ImageTexture.new()
	# fillImage.create_from_image(image.get_data())
	
	var imgSize = Vector2(image.get_width(), image.get_height())
	var resizeFactor = imgSize.width / maxWitdh
	
	if (imgSize.height > imgSize.width):resizeFactor = imgSize.height / maxWitdh
	image.set_size_override(imgSize / resizeFactor)
	return image

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
	curlOutput = curlOutput.split("\n")
	
	threadList = []
	var results = []
	var dbgStr = ""
	
	var fItems = []
	var idx = 0
	
	var subArray = []
	var startIDX = -1
	var endIDX = -1
	
	var getImages = {
		featuredItems = false, resultItems = false, shopItems = false,
		detailImages = false, storeImage = false, relItems = false
	}
	
	var getCreds = []
	
	var setTags = []
	# resultTags [startTag, endTag, findLast, findLast, idxMod]
	
	for i in range(curlOutput.size()):
		
		if (searchCreds.loaded == false || searchCreds.loaded == true && searchCreds.parseDetails == true && infoCreds.isStore == true):
			
			if (curlOutput[i].find(searchCreds.filter_pItems[0]) != -1):
				subArray = getSegment(curlOutput, searchCreds.filter_pItems[0], searchCreds.filter_pItems[1], i)
				
				if (subArray[1] != -1):
					
					setTags = []
					setTags.append(['">', '</option>', true, false, 2])
					var pCount = fillArray(subArray[0], setTags)
					
					if (searchCreds.loaded == false):
						# searchCreds.pageCount = []
						searchCreds.pageCount = pCount
					else:
						if (searchCreds.parseDetails == true && infoCreds.isStore == true):
							infoCreds.pageCount = pCount
					
					i = subArray[1] + 1
			
			if (curlOutput[i].find(searchCreds.filter_sortBy[0]) != -1):
				subArray = getSegment(curlOutput, searchCreds.filter_sortBy[0], searchCreds.filter_sortBy[1], i)
				
				if (subArray[1] != -1):
					
					setTags = []
					setTags.append(['<option value="', '"', true, false, 15])
					setTags.append(['">', '</option>', true, false, 2])
					var sortBy = fillArray(subArray[0], setTags)
					
					if (searchCreds.loaded == false):
						# searchCreds.sortBy = []
						searchCreds.sortBy = sortBy
					else:
						if (searchCreds.parseDetails == true && infoCreds.isStore == true):
							infoCreds.sortBy = sortBy
					
					i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_cat[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_cat[0], searchCreds.filter_cat[1], i)
			
			if (subArray[1] != -1):
				
				setTags = []
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
					
					setTags = []
					setTags.append(['class="current">', '</em>', false, false, 16])
					setTags.append(['">', '</a> <a class="next_page"', false, false, 2])
					var pageCreds = fillArray(subArray[0], setTags)
					
					if (pageCreds.size() > 0):
						pageCreds = pageCreds[0]
						
						if (pageCreds.size() > 1):
							var modStr = pageCreds[1].split('">', false)
							pageCreds[1] = str(modStr[modStr.size() - 1])
						else:
							pageCreds.append(pageCreds[0])
						
						pageCreds[0] = int(pageCreds[0])
						pageCreds[1] = int(pageCreds[1])
						
						if (searchCreds.parseDetails == false):
							# searchCreds.pages = []
							searchCreds.pages = pageCreds
						else:
							# infoCreds.pages = []
							infoCreds.pages = pageCreds
						
						debug.writeLog(str(pageCreds[1]) + " pages found!")
		
		if (curlOutput[i].find(searchCreds.filter_resultItems[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_resultItems[0], searchCreds.filter_resultItems[1], i)
			
			if (subArray[1] != -1):
				if (searchCreds.loaded == true):
					var modStr = ""
					setTags = []
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
						
						if (searchCreds.parseDetails == false):
							searchCreds.resultItems = []
							searchCreds.resultItemImages = []
						else:
							infoCreds.shopItems = []
							infoCreds.shopItemImages = []
						
						var maxSize = prodImages.size()
						
						if (searchCreds.parseDetails == false):
							searchCreds.resultItemImages.resize(maxSize)
						else:
							infoCreds.shopItemImages.resize(maxSize)
						
						# [prodName, prodLink, imageLink, price, storeName, storeLink]
						var orderedArr = []
						
						for idx in range(maxSize):
							# orderedArr = []
							orderedArr = prodImages[idx]
							orderedArr += prodPrices[idx]
							orderedArr += prodStores[idx]
							
							if (searchCreds.parseDetails == false):
								searchCreds.resultItems.append(orderedArr)
							else:
								infoCreds.shopItems.append(orderedArr)
					
					if (searchCreds.parseDetails == false):getImages.resultItems = true
					else:getImages.shopItems = true
					
					i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_fItems[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_fItems[0], searchCreds.filter_fItems[1], i)
			
			if (subArray[1] != -1):
				# var testDbg = ""
				var modStr = ""
				
				setTags = []
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
		
		if (curlOutput[i].find(searchCreds.filter_detailTitle[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_detailTitle[0], searchCreds.filter_detailTitle[1], i)
			
			if (subArray[1] != -1):
				setTags = []
				setTags.append(['<meta name="title" content="', '"/>', false, false, 28])
				
				var titleStr = fillArray(subArray[0], setTags)
				
				if (titleStr.size() > 0):
					titleStr = titleStr[0][0]
					infoCreds.title = titleStr
		
		if (curlOutput[i].find(searchCreds.filter_detailCreds[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_detailCreds[0], searchCreds.filter_detailCreds[1], i)
			
			if (subArray[1] != -1):
				
				infoCreds.detailCreds = ["", "", "", ""] # [price, demo, perms, useage]
				
				setTags = []
				setTags.append(['<span class="price-ld">', '</span>', false, false, 23])
				var priceStr = fillArray(subArray[0], setTags)
				
				if (priceStr.size() > 0):
					priceStr = priceStr[0][0]
					infoCreds.detailCreds[0] = priceStr
				
				setTags = []
				setTags.append(['<a href="', '</a>', false, false, 9])
				var demoStr = fillArray(subArray[0], setTags)
				
				if (demoStr.size() > 0):
					demoStr = demoStr[0][0]
					
					if (demoStr.find('" class="demo-link">') != -1):
						
						var linkURL = settings.featuredLink + demoStr.split('" ')[0]
						var linkTxt = demoStr.split('">')[1].split('</a>')[0]
						
						demoStr = "[url=" + addProtocoll(linkURL) + "]" + linkTxt + "[/url]"
						demoStr += " or [url=" + linkURL + "]open here[/url]"
						infoCreds.detailCreds[1] = demoStr
				
				setTags = []
				setTags.append(['<span class="marketplace-sprite cmt ', '</span>', false, false, 36])
				var perms = fillArray(subArray[0], setTags)
				
				if (perms.size() > 0):
					var permsStr = ""
					
					for idx in range(perms.size()):
						perms[idx] = perms[idx][0]
						
						if (perms[idx].split('">')[0] == "permitted"):
							if (permsStr != ""):permsStr += ", "
							permsStr += perms[idx].split('">')[1]
					
					infoCreds.detailCreds[2] = permsStr
				
				var append = false
				var meshInfo = []
				
				for idx in range(subArray[0].size()):
					var thisLine = subArray[0][idx]
					
					if (thisLine.find('<span class="mesh-support">') != -1):append = true
					if (thisLine.find('</span>') != -1):append = false
					
					if (append == true):
						thisLine = thisLine.strip_edges()
						meshInfo.append(thisLine)
				
				if (meshInfo.size() > 0):
					infoCreds.detailCreds[3] = meshInfo[1]
				
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_detailImgs[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_detailImgs[0], searchCreds.filter_detailImgs[1], i)
			
			if (subArray[1] != -1):
				
				setTags = []
				setTags.append(['<img alt="', '" />', false, false, 10])
				
				var imgStrings = fillArray(subArray[0], setTags)
				infoCreds.infoImages = []
				
				for idx in range (imgStrings.size()):
					infoCreds.infoImages.append([imgStrings[idx][0].split('"')[0], imgStrings[idx][0].split('src="')[1], null])
				
				getImages.detailImages = true
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_description[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_description[0], searchCreds.filter_description[1], i)
			
			if (subArray[1] != -1):
				
				var setDescr = ""
				var append = false
				
				for idx in range(subArray[0].size()):
					
					if (subArray[0][idx].find('<p>') != -1):append = true
					if (subArray[0][idx].find('</div>') != -1):append = false
					
					if (append == true):
						
						var linkStart = subArray[0][idx].find('<a href="')
						
						if (linkStart != -1):
							var replacedLink = subArray[0][idx].right(linkStart + 9)
							
							var linkEnd = replacedLink.find('</a>')
							if (linkEnd != -1):
								replacedLink = replacedLink.left(linkEnd)
								
								var linkURL = replacedLink.split('"')[0]
								var linkTxt = replacedLink.split('">')[1]
								
								replacedLink = "[url=" + linkURL + "]" + linkTxt + "[/url]"
								subArray[0][idx] = subArray[0][idx].left(linkStart) + replacedLink + subArray[0][idx].right(subArray[0][idx].find('</a>') + 4)
						
						setDescr += subArray[0][idx] + "\n"
				
				setDescr = fixedStrings([setDescr])[0]
				
				setDescr = setDescr.replace("<p>", "").replace("</p>", "").replace("<br />", "").strip_edges()
				infoCreds.description = setDescr
				
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_storeInfo[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_storeInfo[0], searchCreds.filter_storeInfo[1], i)
			
			if (subArray[1] != -1):
				
				setTags = []
				setTags.append(['<h5>', '</h5>', false, false, 4])
				var altName = fillArray(subArray[0], setTags)[0][0]
				
				var oldName = [false, ""]
				
				if (altName.begins_with('<a href=') == true):
					var index = altName.find('"') + 1
					oldName = [true, altName.substr(index, altName.length() - index)]
					altName = altName.split('">')[1].split('</')[0]
				
				setTags = []
				setTags.append(['<img alt="', '" ', false, false, 10])
				setTags.append(['" src="', '" ', false, false, 7])
				var imageSrc = fillArray(subArray[0], setTags)
				
				infoCreds.storeInfo = ["", "", null, ""]
				
				if (imageSrc.size() == 0):
					infoCreds.storeInfo[0] = altName
				else:
					infoCreds.storeInfo[0] = imageSrc[0][0]
					infoCreds.storeInfo[1] = imageSrc[0][1]
					getImages.storeImage = true
				
				setTags = []
				setTags.append(['<span class="merchant-sold-by">', '</span>', false, false, 31])
				setTags.append(['<a href="', '</a></span>', false, false, 9])
				var soldBy = fillArray(subArray[0], setTags)
				
				var fillSoldBy = false
				
				if (soldBy.size() > 0):
					fillSoldBy = true
					soldBy = soldBy[0][0]
				
				if (oldName[0] == true):
					fillSoldBy = true
					soldBy = oldName[1]
				
				if (fillSoldBy == true):
					
					if (soldBy.begins_with("http") == true):
						var context = soldBy.split(' title="')[1]
						context = context.split('">')[0]
						soldBy = "[url=" + soldBy.split('" ')[0] + "]" + context + "[/url]"
						infoCreds.storeInfo[0] += "\n" + soldBy
				
				if (infoCreds.isStore == false):
					setTags = []
					setTags.append(['<a href="', '">', false, false, 9])
					var storeLink = fillArray(subArray[0], setTags)
					
					if (storeLink.size() > 0):
						
						for idx in range(storeLink.size()):
							storeLink[idx] = storeLink[idx][0]
							if (storeLink[idx].find('" ') != -1):
								storeLink[idx] = storeLink[idx].split('" ')[0]
							
							infoCreds.storeInfo[3] = settings.featuredLink + storeLink[idx]
					
				i = subArray[1] + 1
		
		if (curlOutput[i].find(searchCreds.filter_relatedItems[0]) != -1):
			subArray = getSegment(curlOutput, searchCreds.filter_relatedItems[0], searchCreds.filter_relatedItems[1], i)
			
			if (subArray[1] != -1):
				
				setTags = []
				setTags.append(['<h2>', '</h2>', false, false, 4])
				infoCreds.relatedTitle = fillArray(subArray[0], setTags)[0][0]
				
				setTags = []
				setTags.append(['"price selling">', '</span>', false, false, 16])
				var prices = fillArray(subArray[0], setTags)
				
				setTags = []
				setTags.append(['<a href="', '" /></a>', false, false, 9])
				var relItems = fillArray(subArray[0], setTags)
				
				if (prices.size() == relItems.size()):
					for idx in range(relItems.size()):
						
						var name = relItems[idx][0].split('<img alt="')[1].split('" src="')[0]
						var url = settings.featuredLink + relItems[idx][0].split('">')[0]
						var imgUrl = relItems[idx][0].split('" src="')[1]
						infoCreds.relatedItems.append([name, imgUrl, null, url, prices[idx][0]])
					getImages.relItems = true
				
				i = subArray[1] + 1
	
	var setButton = get_node("cPanel/catButton")
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
		
		get_node("cPanel/getButton").set_disabled(false)
		loadStatus = "ready"
		
		postLic = true
		
		setButton = get_node("cPanel/itemsCountButton")
		setButton.clear()
		
		for i in range(searchCreds.pageCount.size()):
			setButton.add_item(searchCreds.pageCount[i][0])
		
		setButton = get_node("cPanel/sortbyButton")
		setButton.clear()
		
		for i in range(searchCreds.sortBy.size()):
			setButton.add_item(searchCreds.sortBy[i][1])
	
	var url = ""
	var maxItems = 0
	var pBar = get_node("cPanel/ProgressBar")
	pBar.set_val(maxItems + 1)
	pBar.set_max(maxItems + 1)
	
	if (getImages.featuredItems == true):
		maxItems = searchCreds.featuredItemList.size()
		debug.writeLog(str(maxItems) + " Featured Items found")
		
		for i in range(maxItems):
			var name = "fi_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = searchCreds.featuredItemList[i][2].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getImages.resultItems == true):
		maxItems = searchCreds.resultItems.size()
		debug.writeLog(str(maxItems) + " Search Results found")
		
		for i in range(maxItems):
			var name = "ri_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = searchCreds.resultItems[i][2].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getImages.shopItems == true):
		maxItems = infoCreds.shopItems.size()
		debug.writeLog(str(maxItems) + " Shop Results found")
		
		for i in range(maxItems):
			var name = "si_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = infoCreds.shopItems[i][2].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getImages.detailImages == true):
		maxItems = infoCreds.infoImages.size()
		debug.writeLog(str(maxItems) + " product images found")
		
		for i in range(maxItems):
			var name = "prod_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = infoCreds.infoImages[i][1].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getImages.storeImage == true):
		debug.writeLog("store image found")
		
		var name = "store.jpg"
		var filename = settings.cacheFolder + name
		
		url = infoCreds.storeInfo[1].replace("https://", "")
		url = betterImage(url)
		getCreds.append([url, name, -1])
	
	if (getImages.relItems == true):
		maxItems = infoCreds.relatedItems.size()
		debug.writeLog(str(maxItems) + " product-related items found")
		
		for i in range(maxItems):
			# [name, imgUrl, null, url, price]
			var name = "rel_" + str(i) + ".jpg"
			var filename = settings.cacheFolder + name
			
			url = infoCreds.relatedItems[i][1].replace("https://", "")
			url = betterImage(url)
			getCreds.append([url, name, i])
	
	if (getCreds.size() > 0):
		getSource([true, getCreds])
	
	if (postLic == true):debug.writeLog(myVersion.licenseString, true, false)
	
	get_node("consolePanel/bodyButton").set_disabled(false)
	pass

func getSource(creds):
	
	creds.insert(1, threadList.size())
	
	var newThread = Thread.new()
	newThread.start(self, "threadFunc", creds)
	threadList.append([newThread, creds[0], false])
	pass

func threadFunc(userdata):
	
	# userdata = [toFile, threadID, urlList=[], nameList=[]/idList=[]]
	
	# userdata = [toFile, threadID, [creds]]
	# creds = [url, name, id]
	
	var pBar = get_node("cPanel/ProgressBar")
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
		curlOutput = results[0]
	else:
		removeCachedFile("links.txt", true)
		
		var fileDir = Directory.new()
		var goAhead = false
		var name = ""
		var fileName = ""
		var id = -1
		
		for i in range(creds.size()):
			pBar.set_val(i)
			loadStatus = "loading image " + str(i) + " of " + str(creds.size())
			
			name = creds[i][1]
			id = creds[i][2]
			fileName = settings.cacheFolder + name
			goAhead = fileDir.file_exists(fileName)
			
			if (goAhead == true):
				
				var tmpImg = load(fileName)
				
				if (name == "featured.jpg"):
					get_node("imagePanel/infoImage").set_normal_texture(tmpImg)
					get_node("imagePanel/infoImage").set_tooltip(id)
				elif (name == "store.jpg"):
					infoCreds.storeInfo[2] = tmpImg
				else:
					if (name.begins_with("fi_") == true):
						searchCreds.featuredItemImages[id] = tmpImg
					
					elif (name.begins_with("ri_") == true):
						searchCreds.resultItemImages[id] = tmpImg
					
					elif (name.begins_with("si_") == true):
						infoCreds.shopItemImages[id] = tmpImg
					
					elif (name.begins_with("prod_") == true):
						infoCreds.infoImages[id][2] = tmpImg
					
					elif (name.begins_with("rel_") == true):
						infoCreds.relatedItems[id][2] = tmpImg
				
				removeCachedFile(name)
			else:
				debug.writeLog("warning, " + fileName + " could not be loaded!")
				print("error on image " + str(i) + "\n" + str(creds[i]))
		
		pBar.set_val(creds.size())
		pBar.set_max(creds.size())
	
	if (searchCreds.parseDetails == false):handleTree()
	
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
	
	prodTreeNode.set_columns(1)
	
	prodTreeNode.set_column_title(0, "Products")
	prodTreeNode.set_column_expand(0, true)
	
	if (searchCreds.featuredItemList.size() > 0):
		var basetem = prodTreeNode.create_item(prodTreeRoot)
		basetem.set_text(0, "FEATURED ITEMS:")
	
		for i in range(searchCreds.featuredItemList.size()):
			
			# [prodName, prodLink, imageLink, price, storeName, storeLink]
			var newItem = prodTreeNode.create_item(basetem)
			
			# var fillImage = ImageTexture.new()
			var fillImage = settings.basicImg
			
			if (searchCreds.featuredItemImages.size() > i):
				if (searchCreds.featuredItemImages[i] != null):
					fillImage = thumbImage(maxImgWitdh, searchCreds.featuredItemImages[i])
			
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
			newItem.add_button(0, thumbImage(maxImgWitdh, settings.infoImg))
			
			prodTreeItems.append(newItem)
	
	if (searchCreds.resultItems.size() > 0):
		var basetem = prodTreeNode.create_item(prodTreeRoot)
		basetem.set_text(0, "FOUND ITEMS:")
		
		for i in range(searchCreds.resultItems.size()):
			
			# [prodName, prodLink, imageLink, price, storeName, storeLink]
			var newItem = prodTreeNode.create_item(basetem)
			var fillImage = settings.basicImg
			
			if (searchCreds.resultItemImages.size() > i):
				if (searchCreds.resultItemImages[i] != null):
					fillImage = thumbImage(maxImgWitdh, searchCreds.resultItemImages[i])
			
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
			newItem.add_button(0, thumbImage(maxImgWitdh, settings.infoImg))
			
			prodTreeItems.append(newItem)
	pass

func runSearch():
	if (checkNetwork() == false):
		debug.writeLog("obviously you have no internet connection!")
	
	else:
		curlOutput = []
		threadList = []
		
		var setPages = [1, 1]
		var setURL = settings.featuredLink
		# loadStatus = "... loading details, please be patient!"
		
		if (searchCreds.parseDetails == true):
			setURL = settings.website
			
			if (infoCreds.isStore == true):
				infoCreds.lastOptions.changed = false
				
				var btnID = -1
				var searchTags = ""
				
				if (infoCreds.loaded == true):
					if(infoCreds.storeInfo.size() > 0):
						if(infoCreds.storeInfo[3] != ""):
							setURL = infoCreds.storeInfo[3]
							infoCreds.lastOptions.storeLink = setURL
							
							if (infoCreds.pageCount.size() > 0):
								btnID = infoPanel.get_node("Panel/prodPanel/itemsCountButton").get_selected()
								if (btnID == -1):btnID = 0
								searchTags = "&search[per_page]=" + infoCreds.pageCount[btnID][0]
								
								if (btnID != infoCreds.lastOptions.itemsCount):
									infoCreds.lastOptions.changed = true
									infoCreds.lastOptions.itemsCount = btnID
							
							if (infoCreds.sortBy.size() > 0):
								btnID = infoPanel.get_node("Panel/prodPanel/sortbyButton").get_selected()
								if (btnID == -1):btnID = 0
								searchTags += "&search[sort]=" + infoCreds.sortBy[btnID][0]
								
								if (btnID != infoCreds.lastOptions.sortBy):
									infoCreds.lastOptions.changed = true
									infoCreds.lastOptions.sortBy = btnID
							
							var cText = infoPanel.get_node("Panel/prodPanel/searchEdit").get_text()
							
							if (infoCreds.lastOptions.keywords != cText):
								infoCreds.lastOptions.changed = true
								infoCreds.lastOptions.keywords = cText
							
							cText = cText.replace(" ", "+")
							searchTags += "&search[keywords]=" + cText
							
							btnID = infoPanel.get_node("Panel/prodPanel/pagesSlider").get_value()
							if (infoCreds.lastOptions.changed == true):
								btnID = 1
								infoCreds.pages = [1, 1]
							
							if (btnID != infoCreds.lastOptions.currPage):infoCreds.lastOptions.currPage = btnID
							
							searchTags = "/search?&search[page]=" + str(infoCreds.lastOptions.currPage) + searchTags
					setURL += searchTags
		
		else:
			get_node("consolePanel/bodyButton").set_disabled(true)
			
			searchCreds.featuredItemList = []
			searchCreds.featuredItemImages = []
			searchCreds.resultItems = []
			searchCreds.resultItemImages = []
			
			prodTreeItems.clear()
			prodTreeNode.clear()
			
			get_node("imagePanel/infoImage").set_normal_texture(settings.mpImg)
			get_node("imagePanel/infoImage").set_tooltip("")
			
			lastOptions.changed = false
			searchCreds.mainSearchSubmitID = 0
			
			if (get_node("cPanel/OptionButton").get_selected_ID() == 1):
				searchCreds.mainSearchSubmitID = 1
				
				var btnID = get_node("cPanel/catButton").get_selected()
				if (btnID != lastOptions.categories):
					lastOptions.changed = true
					lastOptions.categories = btnID
				
				var searchTags = "&search[category_id]=" + searchCreds.categories[btnID][0]
				
				if (btnID == 0):searchTags = ""
				
				btnID = get_node("cPanel/itemsCountButton").get_selected()
				if (btnID != lastOptions.itemsCount):
					lastOptions.changed = true
					lastOptions.itemsCount = btnID
				
				searchTags += "&search[per_page]=" + searchCreds.pageCount[btnID][0]
				
				btnID = get_node("cPanel/pagesSlider").get_value()
				if (btnID <= searchCreds.pages[1]):
					btnID = get_node("cPanel/pagesSlider").get_value()
				else:
					btnID = 1
				
				setPages = [btnID, searchCreds.pages[1]]
				searchTags += "&search[page]=" + str(btnID)
				
				btnID = get_node("cPanel/sortbyButton").get_selected()
				if (btnID != lastOptions.sortBy):
					lastOptions.changed = true
					lastOptions.sortBy = btnID
				
				searchTags += "&search[sort]=" + searchCreds.sortBy[btnID][0]
				
				var cText = get_node("cPanel/searchEdit").get_text()
				
				if (lastOptions.keywords != cText):
					lastOptions.changed = true
					lastOptions.keywords = cText
				
				if (lastOptions.changed == true):
					setPages = [1, 1]
				
				cText = cText.replace(" ", "+")
				searchTags += "&search[keywords]=" + cText
				setURL += "/products/search?" + searchTags
				
				settings.website = setURL
				searchCreds.pages = setPages
		
		infoCreds.lastOptions.grabbed = true
		var canProceed = true
		
		if (setURL != settings.featuredLink):
			var burnTag = "Location: https://marketplace.secondlife.com/"
			var checkTag = ""
			
			var args = ["-L", "-I", "-b", settings.cacheFolder + "cookies.txt", setURL]
			var resp = []
			OS.execute(settings.curlPath + "curl", args, true, resp)
			resp = resp[0].split("\n")
		
			for i in range(resp.size()):
				if (resp[i].begins_with("Location:") == true):
					checkTag = resp[i].strip_edges()
					
					if (checkTag == burnTag):
						canProceed = false
						resetTagCounter = 50
		
		if (canProceed == false):
			debug.writeLog("sorry, this product is unavailable")
			get_node("cPanel/ProgressBar/pLabel").set_text("sorry, this product is unavailable")
			
		else:
			settings.website = setURL
			loadStatus = "... loading details, please be patient!"
			debug.writeLog("loading  " + setURL)
			getSource([false, [setURL]])
			# dlSource(setURL, [])
	pass

func setPagesText():
	
	var pSlider = get_node("cPanel/pagesSlider")
	pSlider.set_value(float(searchCreds.pages[0]))
	pSlider.set_max(float(searchCreds.pages[1]))
	
	var setText = "Page " + str(searchCreds.pages[0]) + " of " + str(searchCreds.pages[1])
	if (searchCreds.pages[0] == 1 && searchCreds.pages[1] == 1):setText = "ready"
	
	loadStatus = setText
	pass

func handleInfoTrees():
	var maxImgWitdh = 80
	
	if (infoCreds.isStore == true):
		var shopTree = infoPanel.get_node("Panel/prodPanel/prodTree")
		var shopTreeItems = []
		shopTree.clear()
		
		var shopTreeRoot = shopTree.create_item()
		
		shopTree.set_hide_root(true)
		shopTree.set_select_mode(1)
		shopTree.set_hide_folding(true)
		shopTree.set_column_titles_visible(true)
		shopTree.set_allow_rmb_select(true)
		
		shopTree.set_columns(1)
		
		shopTree.set_column_title(0, "Shop Products")
		shopTree.set_column_expand(0, true)
		
		if (infoCreds.shopItems.size() > 0):
			var basetem = prodTreeNode.create_item(shopTreeRoot)
			basetem.set_text(0, "FOUND ITEMS:")
			
			for i in range(infoCreds.shopItems.size()):
				
				# [prodName, prodLink, imageLink, price, storeName, storeLink]
				var newItem = prodTreeNode.create_item(basetem)
				var fillImage = settings.basicImg
				
				if (infoCreds.shopItemImages.size() > i):
					if (infoCreds.shopItemImages[i] != null):
						fillImage = thumbImage(maxImgWitdh, infoCreds.shopItemImages[i])
				
				# newItem.set_editable(0, true)
				# newItem.set_cell_mode(0, 5)
				
				var newMeta = [i, "si"]
				
				# if (lastSelectedMeta != [] && i == lastSelectedMeta[0]):newMeta = lastSelectedMeta
				newItem.set_metadata(0, newMeta)
				
				var itemText = infoCreds.shopItems[i][0] + " | Price: " + infoCreds.shopItems[i][3]
				# if (newMeta[1] == 1):itemText = infoCreds.shopItems[i][4]
				newItem.set_text(0, itemText)
				
				newItem.set_icon(0, fillImage)
				newItem.set_icon_max_width(0, maxImgWitdh)
				# newItem.add_button(0, thumbImage(maxImgWitdh, settings.infoImg))
				
				shopTreeItems.append(newItem)
	
	else:
		var itemList = infoPanel.get_node("Panel/ItemList")
		itemList.set_select_mode(0)
		itemList.set_focus_mode(0)
		itemList.clear()
		
		var prodList = infoPanel.get_node("Panel/prodList")
		prodList.set_select_mode(0)
		prodList.set_focus_mode(0)
		prodList.clear()
		
		var maxItems = infoCreds.infoImages.size()
		
		itemList.set_icon_mode(1)
		itemList.set_max_columns(maxItems)
		# itemList.add_item("")
		
		if (maxItems > 0):
			for i in range(maxItems):
				var setImage = settings.nullImg
				if (infoCreds.infoImages[i][2] != null):
					setImage = thumbImage(itemList.get_size().height - 11, infoCreds.infoImages[i][2])
				itemList.add_item("", setImage)
		
		maxItems = infoCreds.relatedItems.size() # 8
		
		var columnWidth = (prodList.get_size().width / 8) - 5
		
		prodList.set_icon_mode(0)
		prodList.set_fixed_column_width(columnWidth)
		prodList.set_max_columns(maxItems)
		
		var itemText = ""
		var imgWitdh = prodList.get_size().height - 40
		
		if (columnWidth < imgWitdh):
			imgWitdh = columnWidth
		
		for i in range(2):
			for idx in range(maxItems):
				if (i == 0):
					
					# [name, imgUrl, [image], url, price]
					var setImage = settings.nullImg
					if (infoCreds.relatedItems[idx][2] != null):
						setImage = thumbImage(imgWitdh, infoCreds.relatedItems[idx][2])
					
					prodList.add_item(infoCreds.relatedItems[idx][0], setImage)
					prodList.set_item_tooltip(idx, str(itemText))
				elif (i == 1):
					prodList.add_item(infoCreds.relatedItems[idx][4])
					prodList.set_item_selectable(idx + maxItems, false)
					prodList.set_item_tooltip(idx + maxItems, "")
	
	pass

func handleInfoPanel(show = false, prodInfo = false, setTitle = "Title"):
	infoCreds.lastOptions.queued = !show
	
	if (show == true):
		# get_node("AnimationPlayer").queue("darkOn")
		infoPanel = get_node("ResourcePreloader").get_resource("infoPanel").instance()
		self.add_child(infoPanel, true)
		
		# infoPanel.get_node("Panel/infoLabel").set_scroll_follow(true)
		infoPanel.get_node("Panel/reloadButton").set_hidden(!prodInfo)
		infoPanel.get_node("Panel/openButton").set_hidden(!prodInfo)
		
		infoPanel.get_node("Panel/infoLabel").set_selection_enabled(true)
		infoPanel.get_node("Panel/infoLabel").set_focus_mode(0)
		infoPanel.get_node("Panel/prodImage").set_normal_texture(null)
		
		var setPos = Vector2(0, 0)
		var vpSize = get_viewport().get_rect().size
		var panelSize = infoPanel.get_node("Panel").get_size()
		setPos = (vpSize - panelSize) / 2
		
		infoPanel.get_node("Panel").set_pos(setPos)
		
		# var setPos = Vector2(10, 40) # iLabel.get_pos()
		var iLabel = infoPanel.get_node("Panel/infoLabel")
		iLabel.set_anchor_and_margin(MARGIN_BOTTOM, 1, 0)
		
		var setLabelRect = Rect2(10, 40, panelSize.width - 20, panelSize.height - 80)
		
		var setText = ""
		
		var setRelTitle = ""
		var shiftVar
		
		if (prodInfo == true):
			infoPanel.get_node("Panel/prodPanel").set_hidden(!infoCreds.isStore)
			infoPanel.get_node("Panel/reloadButton").set_hidden(infoCreds.isStore)
			
			iLabel.set_hidden(infoCreds.isStore)
			
			if (infoCreds.isStore == false):
				var myCol = "[color=#b9ffff]"
				
				setText = "[center][:: " + myCol + "Price[/color] " + infoCreds.detailCreds[0]
				setText += " :: " + myCol + "granted permissions[/color] " + infoCreds.detailCreds[2]
				
				if (infoCreds.detailCreds[3] != ""):
					setText += " :: " + myCol + "Mesh[/color] " + infoCreds.detailCreds[3]
				
				setText += " ::]"
				
				if (infoCreds.detailCreds[1] != ""):
					setText += "\n\n" + infoCreds.detailCreds[1]
				
				setText += "[/center]\n\n[:: Description ::]"
				
				shiftVar = infoPanel.get_node("Panel/ItemList").get_size().height + 10
				setLabelRect.pos.y += shiftVar
				# setLabelRect.size.height -= shiftVar
				
				shiftVar += infoPanel.get_node("Panel/prodList").get_size().height
				shiftVar += infoPanel.get_node("Panel/closeButton").get_size().height
				shiftVar += infoPanel.get_node("Panel/relTitleLabel").get_size().height
				# setLabelRect.pos.y += shiftVar
				setLabelRect.size.height -= shiftVar
				
				iLabel.set_anchor_and_margin(MARGIN_BOTTOM, 2, 0)
				
				setText += "\n\n" + str(infoCreds.description)
				
				setTitle = infoCreds.title
				setRelTitle = infoCreds.relatedTitle
			
			else:
				var setBtn = infoPanel.get_node("Panel/prodPanel/itemsCountButton")
				
				if (infoCreds.pageCount.size() > 0):
					setBtn.clear()
					for i in range(infoCreds.pageCount.size()):setBtn.add_item(infoCreds.pageCount[i][0])
					setBtn.select(infoCreds.lastOptions.itemsCount)
				
				setBtn = infoPanel.get_node("Panel/prodPanel/sortbyButton")
				if (infoCreds.sortBy.size() > 0):
					setBtn.clear()
					for i in range(infoCreds.sortBy.size()):setBtn.add_item(infoCreds.sortBy[i][1])
					setBtn.select(infoCreds.lastOptions.sortBy)
				
				if (infoCreds.lastOptions.keywords != ""):
					infoPanel.get_node("Panel/prodPanel/searchEdit").set_text(infoCreds.lastOptions.keywords)
				
				var pSlider = infoPanel.get_node("Panel/prodPanel/pagesSlider")
				pSlider.set_max(float(infoCreds.pages[1]))
				pSlider.set_value(float(infoCreds.pages[0]))
				
				infoPanel.get_node("Panel/prodPanel/ProgressBar/pLabel").set_text("Page " + str(infoCreds.pages[0]) + " of " + str(infoCreds.pages[1]))
				# setText = "Page " + str(searchCreds.pages[0]) + " of " + str(searchCreds.pages[1])
				
				if(infoCreds.storeInfo[3] == ""):
					
					if(infoCreds.lastOptions.storeLink != ""):
						infoCreds.storeInfo[3] = infoCreds.lastOptions.storeLink
					else:
						if (infoCreds.shopItems.size() > 0):
							infoCreds.storeInfo[3] = settings.featuredLink + infoCreds.shopItems[0][5]
				
				setTitle = infoCreds.storeInfo[0]
				setText = ""
			
			var buttontext = "[center]" + infoCreds.storeInfo[0] + "[/center]"
			
			infoPanel.get_node("Panel/storeLabel").append_bbcode(buttontext)
			
			if (infoCreds.storeInfo[2] == null):
				infoCreds.storeInfo[2] = settings.nullImg
			
			infoPanel.get_node("Panel/storeImage").set_normal_texture(infoCreds.storeInfo[2])
			infoPanel.get_node("Panel/prodImage").set_tooltip(setTitle)
			
			if (infoPanel.creds.infoSpanned == true):
				infoPanel.creds.infoSpanned = false
			
			handleInfoTrees()
		
		elif (prodInfo == false):
			
			for i in range(curlOutput.size()):
				setText += curlOutput[i] + "\n"
			
			if(infoPanel.creds.infoSpanned == false):
				infoPanel.creds.infoSpanned = true
		
		iLabel.set_pos(setLabelRect.pos)
		iLabel.set_size(setLabelRect.size)
		
		iLabel.clear()
		iLabel.append_bbcode(setText)
		infoPanel.get_node("Panel/titleLabel").set_text(setTitle)
		infoPanel.get_node("Panel/relTitleLabel").set_text(setRelTitle)
		
	pass

## callback functions follow:
func _on_Timer_timeout():
	
	if (firstStart == true):
		firstStart = false
		init()
	
	if (infoCreds.loaded == true):
		if (searchCreds.parseDetails == true):
			if (infoCreds.isStore == false):
				var cSize = get_viewport().get_rect().size
				if (oldSize != cSize):
					oldSize = cSize
					handleInfoTrees()
					
					# var nPath = infoPanel.get_path()
					# if (get_tree().get_root().has_node(nPath) == true):
						# if (infoPanel.creds.loaded == true):
							# handleInfoTrees()
				
				if (resetTagCounter > 0):resetTagCounter -= 1
				
				if (resetTagCounter == 1):
					get_node("cPanel/ProgressBar/pLabel").set_text("Page " + str(searchCreds.pages[0]) + " of " + str(searchCreds.pages[1]))
	
	if (infoCreds.lastOptions.queued == true && infoCreds.lastOptions.grabbed == true):
		lastOptions.grabbed = false
		infoCreds.lastOptions.queued = false
		
		infoCreds.loaded = false
		
		# get_node("AnimationPlayer").queue("darkOff")
		infoPanel.queue_free()
		
		infoCreds.title = ""
		infoCreds.relatedTitle = ""
		infoCreds.infoImages = []
		infoCreds.relatedItems = []
		infoCreds.shopItems = []
		infoCreds.shopItemImages = []
		# infoCreds.storeInfo = []
	
	var maxThreads = threadList.size()
	
	if (maxThreads > 0):
		var pBar = get_node("cPanel/ProgressBar")
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
				
				if(filesLoaded <= maxFilesLoading):
					pBar.set_val(filesLoaded)
					loadStatus = str(filesLoaded) + " of " + str(maxFilesLoading) + " images downloaded"
		
		if (threadsCompleted == maxThreads):
			threadList.clear()
			
			if (fileDownload == true):
				loadStatus = "loading finished!"
				debug.writeLog(loadStatus)
				setPagesText()
				
				if (searchCreds.parseDetails == true):handleInfoPanel(true, true)
				pBar.set_max(threadsCompleted)
				
			else:
				handleResults()
			
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
				get_node("imagePanel/infoImage").set_normal_texture(searchCreds.featuredItemImages[getItemID])
				get_node("imagePanel/infoImage").set_tooltip(searchCreds.featuredItemList[getItemID][0])
			
			elif (lastSelectedMeta[2] == "ri" && searchCreds.resultItemImages.size() > getItemID):
				get_node("imagePanel/infoImage").set_normal_texture(searchCreds.resultItemImages[getItemID])
				get_node("imagePanel/infoImage").set_tooltip(searchCreds.resultItems[getItemID][0])
	pass

func _on_prodTree_custom_popup_edited(arrow_clicked):
	if (Input.is_mouse_button_pressed(2) == true):
		var selectedItem = prodTreeNode.get_edited()
		var itemRect = prodTreeNode.get_custom_popup_rect()
		
		var pMenu = get_node("PopupMenu")
		pMenu.clear()
		
		pMenu.set_pos(itemRect.pos)
		pMenu.set_size(pMenuSize)
		
		if (lastSelectedMeta[0] != null):
			var getCreds = []
			
			if (searchCreds.mainSearchSubmitID == 0):
			# if (get_node("cPanel/OptionButton").get_selected_ID() == 0):
			# if (settings.website == settings.featuredLink):
				getCreds = searchCreds.featuredItemList[lastSelectedMeta[0]]
			else:
				getCreds = searchCreds.resultItems[lastSelectedMeta[0]]
			
			pMenu.add_check_item("select product --> " + getCreds[0] + " | Price: " + getCreds[3])
			pMenu.add_check_item("select shop --> " + getCreds[4])
			
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
	if (text != ""):
		searchCreds.parseDetails = false
		runSearch()
	get_node("cPanel/searchEdit").release_focus()
	pass

func _on_prodTree_button_pressed(item, column,id):
	var itemMeta = item.get_metadata(0)
	var getInfoStr
	prodCreds = []
	
	# var prodImage = ["", "", settings.mpImg]
	infoCreds.isStore = false
	
	if (itemMeta[2] == "fi"):
		
		prodCreds = searchCreds.featuredItemList[itemMeta[0]]
		
		# prodImage[0] = infoPanel.creds.title
		# prodImage[2] = searchCreds.featuredItemImages[itemMeta[0]]
		
		getInfoStr = searchCreds.featuredItemList[itemMeta[0]][1]
		if (itemMeta[1] == 1):
			infoCreds.isStore = true
			getInfoStr = settings.featuredLink + searchCreds.featuredItemList[itemMeta[0]][5]
		
	elif (itemMeta[2] == "ri"):
		
		prodCreds = searchCreds.resultItems[itemMeta[0]]
		
		# prodImage[0] = infoPanel.creds.title
		# prodImage[2] = searchCreds.resultItemImages[itemMeta[0]]
		
		getInfoStr = searchCreds.resultItems[itemMeta[0]][1]
		if (itemMeta[1] == 1):
			infoCreds.isStore = true
			getInfoStr = settings.featuredLink + searchCreds.resultItems[itemMeta[0]][5]
	
	settings.website = getInfoStr
	searchCreds.parseDetails = true
	runSearch()
	pass

func _on_ProgressBar_value_changed(value):
	
	# maybe needed later :P
	# var getPercent = round((get_node("cPanel/ProgressBar").get_val() * 100) / get_node("cPanel/ProgressBar").get_max())
	
	get_node("cPanel/ProgressBar/pLabel").set_text(loadStatus)
	pass

func _on_pagesSlider_input_event(ev):
	var setVal = -1
	
	if (Input.get_mouse_button_mask() == 1):
		if (ev.type == InputEvent.MOUSE_MOTION):
			setVal = get_node("cPanel/pagesSlider").get_val()
			get_node("cPanel/ProgressBar/pLabel").set_text("Page " + str(setVal) + " of " + str(searchCreds.pages[1]))
		
		if (ev.is_pressed() == false && ev.type == InputEvent.MOUSE_BUTTON):
			if (int(searchCreds.pages[0]) != setVal):
				searchCreds.pages[0] = setVal
				searchCreds.parseDetails = false
				runSearch()
				loadStatus = "... loading Page " + str(searchCreds.pages[0]) + " of " + str(searchCreds.pages[1])
	pass
