@Resources = JSON.parse Utils.domLoadDataSync "./resources.json"
scriptManifest = JSON.parse Utils.domLoadDataSync "./scripts.json"
for key, value of scriptManifest
  scriptData = Utils.domLoadDataSync("scripts/#{key}");
  inject = () ->
    eval CoffeeScript.compile(scriptData, {bare: true});
  inject()

