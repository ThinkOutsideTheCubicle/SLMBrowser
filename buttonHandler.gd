extends BaseButton

var mainNode = null
var parentName = ""
	
func _ready():
	mainNode = get_node("/root/Node")
	parentName = get_parent().get_name()
	pass

func callPage(id, mainSearch):
	
	if (id >= 1):
		if(mainSearch == true):
			if(id <= mainNode.searchCreds.pages[1]):
				mainNode.searchCreds.pages[0] = id
				mainNode.setPagesText()
				
				mainNode.searchCreds.parseDetails = false
				mainNode.runSearch()
				mainNode.loadStatus = "... loading Page " + str(mainNode.searchCreds.pages[0]) + " of " + str(mainNode.searchCreds.pages[1])
		else:
			if(id <= mainNode.infoCreds.pages[1]):
				mainNode.searchCreds.pages[0] = id
				get_parent().get_node("pagesSlider").set_value(id)
				# setVal get_node("Panel/prodPanel/pagesSlider").get_val() + 1
				
				get_parent().get_node("ProgressBar/pLabel").set_text("Page " + str(id) + " of " + str(mainNode.infoCreds.pages[1]))
				mainNode.handleInfoPanel(false)
				mainNode.searchCreds.parseDetails = true
				mainNode.runSearch()
	pass

func callInfoPage():
	if(mainNode.infoCreds.storeInfo[3] != ""):
		mainNode.handleInfoPanel(false)
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	pass

func grabGoto(next):
	var newGoto = [mainNode.searchCreds.pages[0], true]
	if (parentName == "prodPanel"):newGoto = [mainNode.infoCreds.pages[0], false]
	if (next == true):newGoto[0] += 1
	else:newGoto[0] -= 1
	return newGoto

func _on_getButton_pressed():
	mainNode.searchCreds.pages = [1, 1]
	mainNode.setPagesText()
	mainNode.searchCreds.parseDetails = false
	mainNode.runSearch()
	pass

func _on_OptionButton_item_selected(ID):
	mainNode.setOptionsButton(ID)
	pass

func _on_useSSL_btn_toggled(pressed):
	mainNode.settings.useSSL = pressed
	pass

func _on_infoImage_pressed():
	mainNode.toggleImage()
	pass

func _on_infoButton_pressed():
	debug.writeLog(mainNode.myVersion.licenseString, true)
	pass

func _on_nextButton_pressed():
	var goto = grabGoto(true)
	callPage(goto[0], goto[1])
	pass

func _on_prevButton_pressed():
	var goto = grabGoto(false)
	callPage(goto[0], goto[1])
	pass

func _on_nextButton_button_down():
	self.get_node("TextureFrame").show()
	pass

func _on_prevButton_button_down():
	self.get_node("TextureFrame").show()
	pass

func _on_nextButton_button_up():
	self.get_node("TextureFrame").hide()
	pass

func _on_prevButton_button_up():
	self.get_node("TextureFrame").hide()
	pass

func _on_bodyButton_pressed():
	mainNode.handleInfoPanel(true, false, "<html body>")
	pass

func _on_closeButton_pressed():
	mainNode.handleInfoPanel(false)
	pass

func _on_prodImage_pressed():
	mainNode.infoPanel.get_node("AnimationPlayer").queue("hide")
	pass

func _on_openButton_pressed():
	OS.shell_open(mainNode.addProtocoll(mainNode.settings.website))
	pass

func _on_storeImage_pressed():
	if (mainNode.infoCreds.isStore == false && mainNode.infoCreds.storeInfo[3] != ""):
		
		mainNode.settings.website = mainNode.infoCreds.storeInfo[3]
		mainNode.handleInfoPanel(false)
		mainNode.infoCreds.isStore = true
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	pass

func _on_reloadButton_pressed():
	callInfoPage()
	pass

func _on_searchButton_pressed():
	print("infoCreds.storeInfo=" + str(mainNode.infoCreds.storeInfo))
	callInfoPage()
	pass
