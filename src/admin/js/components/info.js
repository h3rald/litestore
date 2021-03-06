(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;

  // Info Module
  app.info = {vm: {}};
  app.info.vm.init = function() {};
  app.info.main = function(){
    var info = app.system;
    var li = function(title, content, hide) {
      if (hide) {
        return "";
      } else {
        return m("li", [m("span", title+": "), m("strong", content)]);
      }
    };
    var readonly = info.read_only ? m("span.label.label-success", "Yes") : m("span.label.label-danger", "No");
    var auth = info.auth ? m("span.label.label-success", "Yes") : m("span.label.label-danger", "No");
    var mirror = info.mount ? m("span.label.label-success", "Yes") : m("span.label.label-danger", "No");
    var infolist = m(".col-sm-6", [m("ul.list-unstyled", [
          li("Version", info.version),
          li("Datastore Version", info.datastore_version),
          li("API Version", info.api_version),
          li("Size", info.size),
          li("Serving Directory", info.directory, info.directory === null),
          li("Mirroring Changes", mirror),
          li("Log Level", info.log_level),
          li("Read-Only", readonly),
          li("Auth", auth),
          li("Additional Stores", info.additional_stores && info.additional_stores.join(", ") || "n/a"),
          li("Total Documents", m("span.badge", info.total_documents)),
          li("Total Tags", m("span.badge", info.total_tags)),
    ])]);
    var logo = m(".col-sm-6", [m("img", {src: "images/litestore.png"})]);
    var taglist = m("ul.list-unstyled", info.tags.map(function(tag){
        var key = Object.keys(tag)[0];
        return m("li", [u.tagbutton({name: key, n: tag[key], key: u.guid()})]);
        })
      );
    var v = m(".row", [
      m(".col-md-6", [u.panel({title: "Datastore Information", content: m(".row", [logo, infolist])})]),
      m(".col-md-6", [u.panel({title: "Tags", content: taglist})])
    ]);
    return v;
  };
  u.layout(app.info);

}())