(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;

  // Document module
  app.document = {vm: {}};
  app.document.vm.init = function() {
    var vm = this;
    vm.id = m.prop(m.route.param("id"));
    vm.action = m.route.param("action");
    vm.readOnly = true; 
    vm.contentType = m.prop("");
    vm.updatedTags = m.prop("");
    vm.content = "";
    vm.binary = false;
    vm.image = false;
    vm.tags = [];
    try {
      vm.ext = vm.id().match(/\.(.+)$/)[1];
    } catch(e) {
      vm.ext = "";
    }
    
    // Retrieve single document & update relevant variables
    vm.getDoc = function(cb){
      vm.doc = Doc.get(vm.id());
      vm.doc.then(function(doc){
        vm.content = doc.data;
        vm.tags = doc.tags;
        vm.updatedTags(vm.tags.filter(function(t){return !/^\$/.test(t)}).join(", "));
        if (vm.tags.filter(function(t){return t === "$format:binary"}).length > 0) {
          vm.binary = true;
          if (vm.tags.filter(function(t){return t === "$type:image"}).length > 0) {
            vm.image = true;
          }
        }
      }, vm.flashError);
    };
    
    // Reset some properties based on action
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
    
    // View document in editor
    vm.viewDocument = function(){
      if (vm.ext === "md" && vm.id().match(new RegExp("^admin\/md\/"))) {
        // If editing a documentation page, go back to the guide.
        m.route("/guide/"+vm.id().replace(/\.md$/, "").replace(new RegExp("^admin\/md\/"), ""));
      } else {
        m.route("/document/view/"+vm.id());
      }
    };
    
    // Set current document editable
    vm.edit = function(){
      vm.editor.setReadOnly(false);
      vm.action = "edit";
      vm.flash("");
    };
    
    // Save document
    vm.save = function(){
      var doc = {};
      doc.id = vm.id();
      doc.data = vm.editor.getValue();
      doc.tags = vm.tags;
      var put = function(){
        Doc.put(doc, vm.contentType()).then(function(){
          LS.flash({type: "success", content: "Document saved successfully."});
          vm.viewDocument();
        }, vm.flashError);
      };
      if (vm.action === "create") {
        doc.id = vm.id();
        vm.id(doc.id);
        Doc.get(doc.id)
          .then(function(){
            vm.showFlash({type: "danger", content: "Document '"+doc.id+"' already exists."});
          }, function(){
            put();
          });
      } else {
        put();
      }
    };
    
    // Delete Document
    vm.delete = function(){
      Doc.delete(vm.id()).then(function(){
        LS.flash({type: "success", content: "Document '"+vm.id()+"' deleted successfully."});
        // Tags may be changed, update infos
        Info.get().then(function(info){
          app.system = info;
           m.route("/info");
        });
      }, vm.flashError);
    };
    
    // Cancel editing
    vm.cancel = function(){
      if (vm.action === "create"){
        m.route("/info");
      } else {
        vm.viewDocument();
      }
    };
    
    // Patch document (update tags)
    vm.patch = function(){
      var sysTags = vm.tags.filter(function(t){return /^\$/.test(t)});
      var newTags = sysTags.concat(vm.updatedTags().split(/,\s*/));
      Doc.patch(vm.id(), newTags).then(function(){
        LS.flash({type: "success", content: "Tags for document '"+vm.id()+"' updated successfully."});
        Info.get().then(function(info){
          app.system = info;
          vm.viewDocument();
        });
      }, vm.flashError);
    };
    
    // File uploader callbacks.
    var onSuccess = function(data){
      vm.id(data.id);
      LS.flash({type: "success", content: "Document '"+vm.id()+"' uploader successfully."});
      Info.get().then(function(info){
        app.system = info;
        vm.viewDocument();
      });
    };
    
    var onFailure = function(data) { vm.flashError(data); };

    var modalId = u.guid();

    vm.uploader = u.uploader({docid: vm.id() || "", onSuccess: onSuccess, onFailure: onFailure, id: modalId});
    
    // Populate tools based on current action
    vm.tools = function(){
      if (app.system.read_only) {
        return [];
      }
      // Configure edit tags popover
      var cfg = {};
      cfg.title = "Edit Tags";
      cfg.contentId = "#edit-tags-popover";
      var tools = [];
      var show = function(){ u.showModal()}
      switch (vm.action){
        case "view":
          tools.push({title: "Upload", icon: "upload", action: vm.uploader.show()});
          if (!vm.binary) {
            tools.push({title: "Edit Content", icon: "edit", action: vm.edit});
          }
          tools.push({title: "Edit Tags", icon: "tags", action: u.showModal("#edit-tags-modal")});
          tools.push({title: "Delete", icon: "trash", action: u.showModal("#delete-document-modal")});
          break;
        default:
          tools.push({title: "Upload", icon: "upload", action: vm.uploader.show()});
          tools.push({title: "Save", icon: "save", action: vm.save});
          tools.push({title: "Cancel", icon: "times-circle", action: vm.cancel});
      }
      return tools;
    };
  };
  
  // Module main view
  app.document.main = function(){
    var vm = app.document.vm;
    var titleLeft = vm.id();
    var titleRight = m("span.pull-right", vm.tags.map(function(t){return u.taglink({name: t, key: u.guid()});}));
    // Delete confirmation dialog
    var deleteDialogCfg = {
      title: "Delete Document",
      id: "delete-document-modal",
      action: vm.delete,
      actionText: "Delete",
      content: m("p", "Do you want to delete document '"+vm.id()+"'?")
    };
    // Configuration for the Edit Tags dialog
    var editTagsDialogCfg = {
      title: "Add/Edit User Tags",
      id: "edit-tags-modal",
      action: vm.patch,
      actionText: "Update",
      content: m("div", [
        m("input", {
            type: "text", 
            class:"form-control", 
            onchange: m.withAttr("value", vm.updatedTags),
            value: vm.updatedTags(),
            placeholder: "Enter comma-separated tags..."
        }),
        m("div.tip", [
          m("p", "Tip") ,
          m("p", "Each user tag can contain letters, numbers, and any of the following special characters:"),
        m("p", "?, ~, :, ., @, #, ^, !, +, _, or -")
        ])
      ])
    };
    if (vm.action === "create"){
        titleLeft = m("span", [m("input", {
          placeholder: "Document ID",
          onchange: m.withAttr("value", function(value){
            vm.id(value);
            vm.editor.updateMode(value);
          }),
          size: 35,
          value: vm.id()
        })]);
        titleRight = m("span.pull-right", [m("input", {
          placeholder: "Content Type",
          onchange: m.withAttr("value", function(value){
            vm.contentType(value);
          }),
          size: 25,
          value: vm.contentType()
        })]);
    }
    var panelContent;
    if (vm.image){
      panelContent = m("div.text-center", [m("img", {src: app.host+"/docs/"+vm.id(), title: vm.id()})]);
    } else {
      panelContent = m.component(app.editor, vm);
    }
    var title = m("span",[titleLeft, titleRight]);
    
    return m("div", [
      vm.uploader,
      u.modal(deleteDialogCfg),
      u.modal(editTagsDialogCfg),
      m(".row", [u.toolbar({links: vm.tools()})]),
      m(".row", [u.panel({title: title, content:panelContent})])
    ]);
  };
  
  u.layout(app.document);
}());