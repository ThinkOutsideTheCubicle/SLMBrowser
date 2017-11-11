extends Node

var creds = { infoSpanned = false }

var mainNode

func _ready():
	mainNode = get_node("/root/Node")
	mainNode.infoCreds.loaded = true
	pass

func _on_ItemList_item_selected(index):
	
	if (mainNode.infoCreds.infoImages.size() > index):
		get_node("Panel/prodImage").set_normal_texture(mainNode.infoCreds.infoImages[index][2])
		get_node("Panel/prodImage").set_tooltip(mainNode.infoCreds.infoImages[index][0])
		get_node("Panel/ItemList").release_focus()
		get_node("Panel/ItemList").unselect(index)
		get_node("AnimationPlayer").queue("show")
	pass

func _on_prodList_item_selected(index):
	
	if (mainNode.infoCreds.relatedItems.size() > index):
		mainNode.settings.website = mainNode.infoCreds.relatedItems[index][3]
		mainNode.handleInfoPanel(false)
		
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	pass

func _on_ItemList_focus_enter():
	get_node("Panel/ItemList").release_focus()
	pass

func _on_infoLabel_meta_clicked(meta):
	if (meta.begins_with("http") == true):
		OS.shell_open(meta)
	else:
		mainNode.settings.website = meta
		mainNode.handleInfoPanel(false)
		
		mainNode.infoCreds.isStore = false
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	pass

func _on_storeLabel_meta_clicked(meta):
	OS.shell_open(meta)
	pass

func _on_prodTree_item_selected():
	var selMeta = get_node("Panel/prodPanel/prodTree").get_selected().get_metadata(0)
	
	if (selMeta[1] == "si"):
		mainNode.settings.website = mainNode.infoCreds.shopItems[selMeta[0]][1]
		mainNode.handleInfoPanel(false)
		
		mainNode.infoCreds.isStore = false
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	pass

func _on_searchEdit_text_entered(text):
	if (text != ""):
		# print("text=" + str(text))
		
		mainNode.handleInfoPanel(false)
		mainNode.infoCreds.isStore = true
		mainNode.searchCreds.parseDetails = true
		mainNode.runSearch()
	get_node("Panel/prodPanel/searchEdit").release_focus()
	pass

func _on_pagesSlider_input_event(ev):
	var setVal = -1
	
	if (Input.get_mouse_button_mask() == 1):
		if (ev.type == InputEvent.MOUSE_MOTION):
			setVal = get_node("Panel/prodPanel/pagesSlider").get_val()
			get_node("Panel/prodPanel/ProgressBar/pLabel").set_text("Page " + str(setVal) + " of " + str(mainNode.infoCreds.pages[1]))
		
		if (ev.is_pressed() == false && ev.type == InputEvent.MOUSE_BUTTON):
			mainNode.handleInfoPanel(false)
			mainNode.searchCreds.parseDetails = true
			mainNode.runSearch()
	pass