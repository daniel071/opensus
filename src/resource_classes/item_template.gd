extends Resource
class_name ItemTemplate

# --Public Variables--
# the name of the item (for ex. "Wrench")
export var itemName: String
# the texture used by the item
export var texture: Texture
# scale to be applied to the texture
export var textureScale: Vector2 = Vector2(1, 1)

# --Private Variables--


# --Public Functions--
# configure an ItemResource based on this item template
func configureItemResource(itemResource: ItemResource):
	# transfer over general item info to itemResource
	for property in ["itemName", "texture", "textureScale"]:
		itemResource.set(property, get(property))
