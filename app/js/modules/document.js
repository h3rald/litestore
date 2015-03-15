(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Document module
  app.document = {vm: {}};
  app.document.vm.init = function() {
    var vm = this;
    vm.id = m.prop(m.route.param("id"));
    vm.action = m.route.param("action");
    vm.readOnly = true;
    vm.contentType = m.prop("");
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
      }, vm.flashError);
    };
    vm.tags = [];
    switch (vm.action) {
      case 'create':
        vm.readOnly = false;
        vm.content = "";
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
      vm.editor.setReadOnly(false);
      vm.action = "edit";
      vm.flash("");
    };
    vm.save = function(){
      var doc = {};
      doc.id = vm.id();
      doc.data = vm.editor.getValue();
      doc.tags = vm.tags;
      var put = function(id){
        Doc.put(doc, vm.contentType()).then(function(){
          LS.flash({type: "success", content: "Document saved successfully."});
          m.route("/document/view/"+id);
        }, vm.flashError);
      };
      if (vm.action === "create") {
        doc.id = "app/"+vm.id();
        Doc.get(doc.id)
          .then(function(){
            vm.showFlash({type: "danger", content: "Document '"+doc.id+"' already exists."});
          }, function(){
            put(doc.id);
          });
      } else {
        put(doc.id);
      }
    };
    // sdfasgsagsagsagasgs
    vm.delete = function(){
      var msg = "Do you want to delete document '"+vm.id()+"'?";
      if (confirm(msg)) {
        Doc.delete(vm.id()).then(function(){
          LS.flash({type: "success", content: "Document '"+vm.id()+"' deleted successfully."});
          m.route("/info");
        }, vm.flashError);
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
        titleLeft = m("span", ["app/",m("input", {
          placeholder: "Document ID",
          onchange: m.withAttr("value", vm.id),
          size: 35,
          value: vm.id()
        })]);
        titleRight = m("span.pull-right", [m("input", {
          placeholder: "Content Type",
          onchange: m.withAttr("value", vm.contentType),
          size: 25,
          value: vm.contentType()
        })]);
    }
    var title = m("span",[titleLeft, titleRight]);
    return m("div", [
      m(".row", [u.toolbar({links: vm.tools()})]),
      m(".row", [u.panel({title: title, content:app.editor.view(vm)})])
    ]);
  };
  
    u.layout(app.document);
}()););
  };
  
    u.layout(app.document);
}());leLeft, titleRight]);
    return m("div", [
      m(".row", [u.toolbar({links: vm.tools()})]),
      m(".row", [u.panel({title: title, content:app.editor.view(vm)})])
    ]);
  };
  
    u.layout(app.document);
}()); return m("div", [
      m(".row", [u.toolbar({links: vm.tools()})]),
      m(".row", [u.panel({title: title, content:app.editor.view(vm)})])
    ]);
  };
  
    u.layout(app.document);
}());