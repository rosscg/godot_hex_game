########################################

# From Unit.gd _ready():

# Functionality used for units which occupy multiple cells (WIP):
#	occupied_cells_local = PoolVector2Array([Vector2(0, 0)])
#	for i in occupied_cells_local:
#		occupied_cells.append(tilemap.get_cell_from_coordinates(self.position) + i)
#    var imageTexture = TextureRect.ImageTexture.new()
#    var dynImage = Image.new()
#    dynImage.create(256,256,false,Image.FORMAT_DXT5)
#    dynImage.fill(Color(1,0,0,1))
#    imageTexture.create_from_image(dynImage)
#    self.texture = imageTexture

# Paint FoW light
# Engine currently doesn't support multiple 2d light masks.
#	self.light = Light2D.new()
#	self.light.texture = mask_tex
#	self.light.range_item_cull_mask = map.get_node("MapImageFOW").light_mask
#	self.light.mode = 3
#	self.light.enabled = true
#	self.light.scale = Vector2(10, 10)
#	self.add_child(light)

########################################
