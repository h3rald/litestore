/*
 * Dependencies:
 * - models.js
 * - utils.js
 */
(function(){
  'use strict';  
  var app = window.LS || (window.LS = {});
  var u = LS.utils;
  
  app.uploader = function(docid){
    
    var uploader = {vm: {}};
    var vm = uploader.vm;
    
    vm.docid = m.prop(docid);
    vm.file = m.prop();
    vm.id = u.guid();
    vm.modalId = "#upload-"+vm.id+"-modal";
    vm.btnId = "#upload-"+vm.id+"-btn";
    vm.reader = new FileReader();
    vm.contents = m.prop();
    vm.isText = m.prop(false);
    
    vm.reader.onloadstart = function() {
      vm.contents("");
      $(uploader.vm.modalId).find(".btn-primary").attr("disabled", true);
    };
    
    vm.reader.onloadend = function() {
      vm.contents(vm.reader.result);
      $(uploader.vm.modalId).find(".btn-primary").removeAttr("disabled");
    };

    vm.save = function() {
      var doc = {id: vm.docid()};
      doc.data = vm.contents().split(',')[1];
      if (vm.isText()) {
        doc.data = window.atob(doc.data);
      }
      return Doc.put(doc, vm.file().type).then(uploader.onSuccess, uploader.onFailure);
    };
    
    uploader.config = function(obj){
      return function(element, isInitialized, context){
        $(element).change(function(event){
          vm.file(element.files[0]);
          if (vm.reader.readyState != 1) {
            vm.reader.readAsDataURL(vm.file()); 
          }
        });
      };
    };
    
    uploader.showModal = function() {
      return u.showModal(uploader.vm.modalId);
    };
    
    uploader.onSuccess = function(data){
      // Callback
    };
    uploader.onFailure = function(data){
      // Callback
    };
    
    uploader.view = function(){
      var config = {
        title: "Upload Document",
        id: "upload-"+vm.id+"-modal",
        action: vm.save,
        actionText: "Upload",
        content: m("div", [
          m(".form-group", [
          m("label", "Document ID"),
            m("input.form-control", {
              placeholder: "Enter document ID",
              onchange: m.withAttr("value", vm.docid),
              size: 35,
              disabled: (docid === "") ? false : true,
              value: vm.docid()
            })
          ]),
          m(".form-group", [
            m("label", "File"),
            m("input.form-control#upload-"+vm.id+"-btn", {type:"file", config: uploader.config(vm)}),
            m("p.help-block", "Select a file to upload as document.")
          ]),
          m(".checkbox", [
            m("label", [
              m("input", {type: "checkbox", value: vm.isText(), onchange: m.withAttr("value", vm.isText)}), 
              "Text File"
            ]),
            m("p.help-block", "Select if the file to upload contains textual content.")
          ])
        ])
      };
      return u.modal(config);
    };
    return uploader;
  };
}());