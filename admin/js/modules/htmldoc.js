(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // HTMLDoc Module
  app.htmldoc = {vm: {}};
  app.htmldoc.vm.init = function() {
    var vm = this;
    vm.id = m.prop(m.route.param("id"));
    vm.content = Doc.get(vm.id()).then(function(content){
      return $("<div>").html(content.data).html();
    }, vm.flashError);
    vm.view = function(){
      m.route("/document/view/"+vm.id());
    };
    vm.links = m.prop([{action: vm.view, title: "View Source", icon: "code"}]);
  };
  app.htmldoc.main = function(){
    return m("article.row", [
      u.toolbar({links: app.htmldoc.vm.links()}), 
      m.trust(app.htmldoc.vm.content())
    ]);
  };

  u.layout(app.htmldoc);

}());