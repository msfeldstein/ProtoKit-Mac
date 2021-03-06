// Generated by CoffeeScript 1.7.1
(function() {
  try {
    this.liveReload = new WebSocket("ws://" + window.location.host + "/live-reload");
    this.liveReload.onmessage = function(msg) {
      if (msg.data === "reload") {
        return location.reload();
      }
    };
  } catch (_error) {
    console.log("Live Reload Failed, gotta press that reload button :(");
  }

}).call(this);


window.Resources = {"icon.png":{"path":"images\/icon.png","width":151,"height":151}};

// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  this.Pulser = (function(_super) {
    __extends(Pulser, _super);

    function Pulser(opts) {
      this.grow = __bind(this.grow, this);
      Pulser.__super__.constructor.call(this, opts);
      this.borderRadius = "50%";
      this.grow();
    }

    Pulser.prototype.grow = function() {
      var animation;
      animation = this.animate({
        properties: {
          scale: 3,
          opacity: 0
        },
        time: 1.3,
        curve: "cubic-bezier(0, 0, .4, 1)"
      });
      return animation.on(Events.AnimationEnd, (function(_this) {
        return function() {
          _this.scale = 1;
          _this.opacity = 1;
          return Utils.delay(.5, _this.grow);
        };
      })(this));
    };

    return Pulser;

  })(Layer);

}).call(this);
// Generated by CoffeeScript 1.7.1
(function() {
  var instructions, layer, pulser, resource;

  pulser = new Pulser({
    width: 150,
    height: 150
  });

  pulser.center();

  resource = Resources["icon.png"];

  layer = new Layer({
    image: resource.path,
    width: resource.width,
    height: resource.height
  });

  layer.center();

  instructions = new Layer({
    width: Screen.width,
    height: 100,
    backgroundColor: null,
    y: Screen.height - 100
  });

  instructions.html = "Start in app.coffee inside the project folder in your favorite text editor";

  instructions.style = {
    color: "black",
    textAlign: "center",
    fontFamily: "Helvetica Neue",
    fontWeight: 100,
    padding: "5px",
    fontSize: "20px"
  };

}).call(this);
