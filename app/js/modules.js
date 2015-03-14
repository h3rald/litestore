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

  // Tags Module
  app.tags = {vm: {}};
  app.tags.vm.init = function(){
    this.id = m.route.param("id");
    this.docs = Doc.getByTag(this.id); 
  };
  app.tags.main = function(){
    var docs = app.tags.vm.docs();
    var title = m("h2", ["Tag: ", m("em", docs.tags)]);
    var table = m("table.table.table-bordered.table-hover", [
      m("thead", [
        m("tr", [
          m("th", "ID"),
          m("th", "Created"),
          m("th", "Modified"),
          m("th", "Tags")
        ])
      ]),
      m("tbody",  [
        docs.results.map(function(d){
          return m("tr", [
            m("td", u.doclink(d.id)),  
            m("td", u.date(d.created)),  
            m("td", u.date(d.modified)),  
            m("td", d.tags.map(function(t){return u.taglink(t);})),  
          ]);
        })
      ])
    ]);
    return m(".row", [
      title,
      m("p", "Total: "+docs.total),
      table
    ]);
  };

  // Document module
  app.document = {vm: {}};
  app.document.vm.init = function() {
    var vm = this;
    vm.id = m.prop(m.route.param("id"));
    vm.action = m.route.param("action");
    vm.readOnly = true;
    vm.contentType = m.prop("");
    vm.existingId = m.prop();
    vm.existingContentType = m.prop();
    vm.existingContent = m.prop();
    try {
      vm.ext = vm.id().match(/\.(.+)$/)[1];
    } catch(e) {
      vm.ext = "";
    }
    vm.getDoc = function(cb){
      vm.doc = Doc.get(vm.id());
      vm.doc.then(function(doc){
        vm.content = doc.data;
        vm.tags = doc.tags;
      });
    };
    vm.tags = [];
    switch (vm.action) {
      case 'create':
        vm.readOnly = false;
        if (vm.existingId()) {
          vm.id(vm.existingId());
          vm.contentType(vm.existingContentType());
          vm.content(vm.existingContent());
          vm.existingId = m.prop();
          vm.existingContentType = m.prop();
          vm.existingContent = m.prop();
        }
        break;
      case 'edit':
        vm.getDoc();
        vm.readOnly = false;
        break;
      case 'view':
        vm.getDoc();
        break;
    }
    switch (vm.ext){
      case 'js':
        vm.mode = "javascript";
        break;
      case 'css':
        vm.mode = "css";
        break;
      case 'html':
        vm.mode = "html";
        break;
      case 'json':
        vm.mode = "json";
        break;
      case 'md':
        vm.mode = "markdown";
        break;
      default:
        vm.mode = "text";
    }
    vm.edit = function(){
      m.route("/document/edit/"+vm.id());
    };
    vm.save = function(){
      var doc = {};
      doc.id = vm.id();
      doc.data = vm.editor.getValue();
      doc.tags = vm.tags;
      var put = function(){
        Doc.put(doc, vm.contentType()).then(function(){
          LS.flash({type: "success", content: "Document saved successfully."});
          m.route("/document/view/"+vm.id());
        });
      };
      if (vm.action === "create") {
        Doc.get(vm.id())
          .then(function(){
            LS.flash({type: "danger", content: "Document '"+vm.id()+"' already exists."});
            vm.existingContent(doc.data);
            vm.existingContentType(vm.contentType());
            vm.existingId(vm.id());
            m.route(m.route());
          }, function(){put();});
      } else {
        put();
      }
    };
    vm.delete = function(){
      var msg = "Do you want to delete document '"+vm.id()+"'?";
      if (confirm(msg)) {
        Doc.delete(vm.id()).then(function(){
          LS.flash({type: "success", content: "Document '"+vm.id()+"' deleted successfully."});
          m.route("/info");
        });
      } else {
        m.route("/document/view/"+vm.id());
      }
    };
    vm.cancel = function(){
      if (vm.action === "create"){
        m.route("/info");
      } else {
        m.route("/document/view/"+vm.id());
      }
    };
    vm.tools = function(){
      switch (vm.action){
        case "view":
          return [
            {title: "Edit", icon: "edit", action: vm.edit},
            {title: "Delete", icon: "trash", action: vm.delete}
          ];
        default:
          return [
            {title: "Save", icon: "save", action: vm.save},
            {title: "Cancel", icon: "times-circle", action: vm.cancel}
          ];
      }
    };
  };
  app.document.main = function(){
    var vm = app.document.vm;
    var titleLeft = vm.id();
    var titleRight = m("span.pull-right", vm.tags.map(function(t){return u.taglink(t);}));
    if (vm.action === "create"){
        titleLeft = m("input", {
          placeholder: "Specify document ID...",
          onchange: m.withAttr("value", vm.id),
          size: 35,
          value: vm.id()
        });
        titleRight = m("span.pull-right", [m("input", {
          placeholder: "Specify content type...",
          onchange: m.withAttr("value", vm.contentType),
          size: 20,
          value: vm.contentType()
        })]);
    }
    var title = m("span",[titleLeft, titleRight]);
    return m("div", [
      m(".row", [u.toolbar({links: vm.tools()})]),
      m(".row", [u.panel({title: title, content:app.editor.view(vm)})])
    ]);
  };


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
  u.layout(app.info);
  u.layout(app.tags);
  u.layout(app.document);

}());tags);
  u.layout(app.document);

}());));