var app = app || {};

(function(){
  'use strict';

  // Info Module
  app.info = {vm: {}};
  app.info.vm.init = function() {
    this.content = Info.get();
  };
  app.info.main = function(){
    var info = app.info.vm.content();
    var infolist = m("dl", [
          m("dt", "Version"),
          m("dd", info.version),
          m("dt", "Size"),
          m("dd", info.size),
          m("dt", "Total Documents"),
          m("dd", info.total_documents),
          m("dt", "Total Tags"),
          m("dd", info.total_tags)
    ]);
    var taglist = m("ul", info.tags.map(function(tag){
        var key = Object.keys(tag)[0];
        return m("li", [m("a", {href: "#"}, key+" ("+tag[key]+")")])
        })
      );
    var v = m(".row", [
      m(".col-md-6", [u.panel({title: "Datastore Information", content: infolist})]),
      m(".col-md-6", [u.panel({title: "Tags", content: taglist})])
    ])
    return v;
  };


  // Guide Module
  app.guide = {vm: {}};
  app.guide.vm.init = function() {
    this.pageid = m.prop(m.route.param("page"));
    this.content = Page.get(this.pageid());
  };
  app.guide.main = function(){
    return m("article.row", m.trust(app.guide.vm.content()));
  };


  u.layout(app.guide);
  u.layout(app.info);

}());
