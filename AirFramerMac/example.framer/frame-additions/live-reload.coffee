try
  @liveReload = new WebSocket("ws://#{window.location.host}/live-reload")
  @liveReload.onmessage = (msg) ->
    if msg.data == "reload"
      location.reload()