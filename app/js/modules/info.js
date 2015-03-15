(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Info Module
  app.info = {vm: {}};
  app.info.vm.init = function() {
    this.content = Info.get();
  };
  app.info.main = function(){
    var vm = app.info.vm;
    var info = vm.content();
    var infolist = m("dl", [
          m("dt", "Version"),
          m("dd", info.version),
          m("dt", "Size"),
          m("dd", info.size),
          m("dt", "Loaded directory"),
          m("dd", info.directory),
          m("dt", "Mirroring"),
          m("dd", info.mirror),
          m("dt", "Read-only"),
          m("dd", info.read_only),
          m("dt", "Total Documents"),
          m("dd", info.total_documents),
          m("dt", "Total Tags"),
          m("dd", info.total_tags)
    ]);
    var taglist = m("ul", info.tags.map(function(tag){
        var key = Object.keys(tag)[0];
        return m("li", [m("a", {href: "/tags/"+key, config: m.route}, key+" ("+tag[key]+")")]);
        })
      );
    var v = m(".row", [
      m(".col-md-6", [u.panel({title: "Datastore Information", content: infolist})]),
      m(".col-md-6", [u.panel({title: "Tags", content: taglist})])
    ]);
    return v;
  };
  u.layout(app.info);

}());
