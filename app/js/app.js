(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  
  app.flash = m.prop();

  m.route.mode = "hash";

  m.route(document.body, "/info", {
    '/info': app.info,
    "/tags/:id": app.tags,
    "/document/:action/:id...": app.document,
    "/guide/:id": app.guide,
    "/new": app.create
  });
}());