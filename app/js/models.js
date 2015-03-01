var Page = {};

Page.get = function(id) {
  var content = m.prop("");
  return m.request({
      method: "GET", 
      url: "md/"+id+".md",
      deserialize: function(value) {return value;}
    }).then(function(content){ return marked(content)});
}

var Info = {};

Info.get = function(){
  var content = m.prop("");
  return m.request({
      method: "GET", 
      url: "/v1/info"
    }).then(content);
}

