(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;

  // Guide Module
  app.guide = {vm: {}};
  app.guide.vm.init = function() {
    var vm = this;
    vm.id = m.prop(m.route.param("id"));
    vm.content = Page.get(vm.id()).then(function(content){return content}, vm.flashError);
    vm.edit = function(){
      m.route("/document/edit/"+app.system.directory+"/md/"+vm.id()+".md");
    };
    vm.links = app.system.read_only ? m.prop([]) : m.prop([{action: vm.edit, title: "Edit", icon: "edit"}]);
  };
  app.guide.main = function(){
    return m("article.row", [
      u.toolbar({links: app.guide.vm.links()}), 
      m.trust(app.guide.vm.content())
    ]);
  };

  u.layout(app.guide);

}());
