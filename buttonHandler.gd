extends BaseButton

var mainNode = null

func _ready():
	mainNode = get_node("/root/Node")
	# print("path of " + self.get_name() + " => " + self.get_path())
	# print(self.get_name() + " is ready.")
	pass

func _on_getButton_pressed():
	mainNode.runSearch()
	pass

func _on_OptionButton_item_selected(ID):
	mainNode.setOptionsButton(ID)
	pass

func _on_useSSL_btn_toggled(pressed):
	# mainNode.setOptionsButton(pressed)
	mainNode.settings.useSSL = pressed
	pass

func _on_infoImage_pressed():
	mainNode.toggleImage()
	pass

func _on_infoButton_pressed():
	debug.writeLog(mainNode.myVersion.licenseString, true)
	pass

func _on_nextButton_pressed():
	var cPages = mainNode.searchCreds.pages
	cPages = [int(cPages[0]), int(cPages[1])]
	if (cPages[0] + 1 <= cPages[1]):
		cPages[0] += 1
		mainNode.searchCreds.pages[0] = str(cPages[0])
		mainNode.setPagesText()
		mainNode.runSearch()
	pass

func _on_prevButton_pressed():
	var cPages = mainNode.searchCreds.pages
	cPages = [int(cPages[0]), int(cPages[1])]
	if (cPages[0] - 1 >= 1):
		cPages[0] -= 1
		print("cPages=" + str(cPages))
		
		mainNode.searchCreds.pages[0] = str(cPages[0])
		mainNode.setPagesText()
		mainNode.runSearch()
	pass
