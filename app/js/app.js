(function(){
  'use strict';
  var app = window.LS || (window.LS = {});

  m.route.mode = "hash";

  m.route(document.body, "/info", {
    '/info': app.info,
    "/tags/:id": app.tags,
    "/document/:id...": app.document,
    "/guide/:id": app.guide
  });
}());
