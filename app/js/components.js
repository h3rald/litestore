(function(){
  'use strict';  
  var app = window.LS || (window.LS = {});
  app.editor = {};


  app.editor.config = function(obj){
    return function(element, isInitialized, context){
      var e = element;

      if (!isInitialized) {
        var editor = ace.edit(e);
        obj.editor = editor;
        e.style.position = "relative";
        editor.updateMode = function(filename) {
          var self = this;
          var ext = "";
          try {
            ext = filename.match(/\.(.+)$/)[1];
          } catch(e) {
            ext = "";
          }
          switch (ext){
            case 'js':
              obj.mode = "javascript";
              break;
            case 'css':
              obj.mode = "css";
              break;
            case 'html':
              obj.mode = "html";
              break;
            case 'json':
              obj.mode = "json";
              break;
            case 'md':
              obj.mode = "markdown";
              break;
            default:
              obj.mode = "text";
          }
          self.getSession().setMode("ace/mode/"+obj.mode);
        };
        editor.setOptions({ maxLines: Infinity });
        editor.setReadOnly(obj.readOnly);
        editor.setShowPrintMargin(false);
        editor.setTheme("ace/theme/github");
        editor.updateMode(obj.id());
        editor.getSession().setUseWrapMode(true);
        editor.getSession().setTabSize(2);
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
  
}());ontent);
  };
  
}());}, obj.content);
  };
  
}());