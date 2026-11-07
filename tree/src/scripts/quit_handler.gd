class_name RQuitHandler
extends RefCounted

static func request(app: Node, tree: SceneTree) -> String:
	if RPlatformService.allow_native_quit():
		tree.quit()
		return "quit_requested"
	app.call("_show_menu")
	return RBrowserQuit.explanation()
