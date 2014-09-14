# Use the scripts folder to automatically include any coffee script files
# Pulser is a class defined in that folder.
pulser = new Pulser
  width: 150
  height: 150
pulser.center()

# Use Resources to get widths and heights of images.
# Any images in the images folder will be added to this object.
resource = Resources["icon.png"]
layer = new Layer
  image: resource.path
  width: resource.width
  height:resource.height
layer.center() 

instructions = new Layer
  width: Screen.width
  height: 100
  backgroundColor: null
  y: Screen.height - 100
instructions.html = "Start in app.coffee inside the project folder in your favorite text editor"
instructions.style =
  color: "black"
  textAlign: "center"
  fontFamily: "Helvetica Neue"
  fontWeight: 100
  padding: "5px"
  fontSize: "20px"