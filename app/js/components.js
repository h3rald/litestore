(function(){
  'use strict';  
  var app = window.LS || (window.LS = {});
  app.editor = {};


  app.editor.config = function(obj){
    return function(element, isInitialized, context){
      var e = element;
      var setHeight = function(){
        e.style.height = (window.innerHeight-250)+"px";
      };

      if (!isInitialized) {
        var editor = ace.edit(e);
        obj.editor = editor;
        e.style.position = "relative";
        setHeight();
        window.addEventListener("resize", setHeight);
        editor.setReadOnly(true);
        editor.setShowPrintMargin(false);
        editor.setTheme("ace/theme/github");
        editor.getSession().setMode("ace/mode/"+obj.mode);
        editor.getSession().setUseWrapMode(true);
      }
    };
  };

  /**
   * @param obj
   *  - content The content of the editor
   */
  app.editor.view = function(obj) {
    return m(".editor.panel.panal-default", {config: app.editor.config(obj)}, obj.content);
    
  };
  
}());
