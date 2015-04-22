(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  
  app.flash = m.prop();
  app.system = {};
  m.route.mode = "hash";
  
  app.init = function(info){
    app.system = info;
    m.route(document.body, "/info", {
      "/info": app.info,
      "/tags/:id": app.tags,
      "/html/:id...": app.htmldoc,
      "/document/:action/:id...": app.document,
      "/guide/:id": app.guide,
      "/new": app.create,
      "/search/:q": app.search,
      "/search/:q/:page": app.search,
      "/search/:q/:page/:limit": app.search
    });
  };
  Info.get().then(app.init);
  
}());