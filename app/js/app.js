(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  
  app.flash = m.prop();
  app.system = m.prop();
  app.init = function(info){
    app.system(info);
    console.log(app.system());
    m.route.mode = "hash";

    m.route(document.body, "/info", {
      '/info': app.info,
      "/tags/:id": app.tags,
      "/document/:action/:id...": app.document,
      "/guide/:id": app.guide,
      "/new": app.create,
      "/search": app.search
    });
  };
  Info.get().then(app.init);
  
}());