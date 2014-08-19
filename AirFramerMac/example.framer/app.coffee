# Use Resources to get widths and heights of images
resource = Resources["framer-icon.png"]
layer = new Layer
  image: resource.path
  width: resource.width
  height:resource.height
  y: 300
  x: Screen.width / 2 - resource.width / 2

# Use the scripts folder to automatically include any coffee script files
# TextPanel is a class defined in that folder.
new TextPanel
  text: "Add CoffeeScript files to the scripts directory to include them automatically."
  width: Screen.width - 50
  height: 120

new TextPanel
  text: "Add images to the image folder to reference their paths and sizes"
  width: Screen.width - 50
  height: 100
  y: 130
