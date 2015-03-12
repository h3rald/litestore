(function(){
  window.Page = {};
  window.Info = {};
  window.Doc = {};
  var u = window.LS.utils;
  
  Page.get = function(id) {
    var content = m.prop("");
    return m.request({
        method: "GET", 
        url: "md/"+id+".md",
        deserialize: function(value) {return value;}
      }).then(function(content){ return marked(content);});
  };
  
  Info.get = function(){
    var content = m.prop("");
    return m.request({
        method: "GET", 
        url: "/v1/info"
      }).then(content);
  };
  
  Doc.getByTag = function(tag) {
    var docs = m.prop("");
    return m.request({
        method: "GET", 
        url: "/v1/docs?contents=false&tags="+tag
      }).then(docs);
  };
  
  Doc.get = function(id) {
    var doc = m.prop("");
    return m.request({
        method: "GET", 
        url: "/v1/docs/"+id+"?raw=true"
      }).then(doc);
  };
  
  Doc.put = function(doc){
    xhrcfg = u.getContentType(doc);
    return m.request({
        method: "PUT", 
        url: "/v1/docs/"+doc.id,
        data: doc.data,
        serialize: function(data){return data;},
        config: xhrcfg
      });
    };
}());
