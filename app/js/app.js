
var Page = {}

Page.get = function(id) {
  var content = m.prop("");
  return m.request({
      method: "GET", 
      url: "md/"+id+".md",
      deserialize: function(value) {return value;}
    }).then(function(content){ return marked(content)});
}

var litestore = {
    controller: function() {
      this.pageid = m.route.param("page");
      this.content = Page.get(this.pageid);
    },
    view: function(controller) {
      $('#nav-links').find('.active').removeClass('active');
      $('#nav-'+controller.pageid).addClass('active');
      return m("article", m.trust(controller.content()));
    }
}

m.route.mode = "hash";

m.route(document.getElementsByTagName("main")[0], "/overview", {
    "/:page": litestore
});
