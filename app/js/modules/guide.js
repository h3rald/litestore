(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Guide Module
  app.guide = {vm: {}};
  app.guide.vm.init = function() {
    this.id = m.route.param("id");
    this.content = Page.get(this.id);
  };
  app.guide.main = function(){
    return m("article.row", m.trust(app.guide.vm.content()));
  };

  u.layout(app.guide);

}());