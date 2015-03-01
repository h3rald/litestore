var app = app || {};
(function(){
  'use strict';

  m.route.mode = "hash";

  m.route(document.body, "/info", {
    '/info': app.info,
    "/pages/:page": app.guide
  });
}());
