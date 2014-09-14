# Dont forget to use the @ symbol to declare items globally
class @Pulser extends Layer
  constructor: (opts) ->
    super opts
    @borderRadius = "50%"
    @grow()
  
  grow: () =>
    animation = @animate
      properties:
        scale: 3
        opacity: 0
      time: 1.3
      curve: "cubic-bezier(0, 0, .4, 1)"
    animation.on Events.AnimationEnd, () =>
      @scale = 1
      @opacity = 1
      Utils.delay .5, @grow


