/*
 * Dependencies:
 * - models.js
 * - utils.js
 */
(function(){
  'use strict';  
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  var w = app.widgets;
  
  /**
   * @param {Object} obj
   * @param {string} obj.docid
   * @param {string} obj.id
   * @param {Function} obj.onSuccess
   * @param {Function} obj.onFailure
   */
  app.uploader = function(obj){

    var modalId = "#upload-"+obj.id+"-modal";
    var uploader = {};
    
    uploader.config = function(obj){
      return function(element, isInitialized, context){
        $(element).change(function(event){
          obj.file(element.files[0]);
          if (obj.reader.readyState != 1) {
            obj.reader.readAsDataURL(obj.file()); 
          }
        });
      };
    };
    
    uploader.controller = function(args) {
      var vm = this;

      vm.docid = m.prop(args.docid);
      vm.file = m.prop();
      vm.id = args.id; 
      vm.btnId = "#upload-"+vm.id+"-btn";
      vm.reader = new FileReader();
      vm.contents = m.prop();
      vm.isText = m.prop(false);

      vm.reader.onloadstart = function() {
        vm.contents("");
        $(modalId).find(".btn-primary").attr("disabled", true);
      };

      vm.reader.onloadend = function() {
        vm.contents(vm.reader.result);
        $(modalId).find(".btn-primary").removeAttr("disabled");
      };

      vm.save = function() {
        var doc = {id: vm.docid()};
        doc.data = vm.contents().split(',')[1];
        if (vm.isText()) {
          doc.data = window.atob(doc.data);
        }
        return Doc.put(doc, vm.file().type).then(args.onSuccess, args.onFailure);
      };
      return vm;
    }
    
    uploader.view = function(ctrl, args){
      var config = {
        title: "Upload Document",
        id: "upload-"+ctrl.id+"-modal",
        action: ctrl.save,
        actionText: "Upload",
        content: m("div", [
          m(".form-group", [
          m("label", "Document ID"),
            m("input.form-control", {
              placeholder: "Enter document ID",
              onchange: m.withAttr("value", ctrl.docid),
              size: 35,
              disabled: (ctrl.docid() === "") ? false : true,
              value: ctrl.docid()
            })
          ]),
          m(".form-group", [
            m("label", "File"),
            m("input.form-control#upload-"+ctrl.id+"-btn", {type:"file", config: uploader.config(ctrl)}),
            m("p.help-block", "Select a file to upload as document.")
          ]),
          m(".checkbox", [
            m("label", [
              m("input", {type: "checkbox", value: ctrl.isText(), onchange: m.withAttr("value", ctrl.isText)}), 
              "Text File"
            ]),
            m("p.help-block", "Select if the file to upload contains textual content.")
          ])
        ])
      };
      return w.modal(config);
    };

    var instance = m.component(uploader, obj);
    instance.show = function() {
      return u.showModal(modalId);
    };
    return instance;
  };
}());
