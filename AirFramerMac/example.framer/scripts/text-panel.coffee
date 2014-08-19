# Dont forget to use the @ symbol to declare items globally
class @TextPanel extends Layer
  constructor: (opts) ->
    super opts
    @html = opts.text
    @style =
      "font-family": "Avenir"
      "font-size": "20pt"
      "padding": "20px"
    @draggable.enabled = true