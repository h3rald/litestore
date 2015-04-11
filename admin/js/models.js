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
      }).then(function(content){ return u.markdown(content);});
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
  
  Doc.search = function(search, offset, limit){
    offset = offset || 0;
    limit = limit || 10;
    var docs = m.prop("");
    return m.request({
        method: "GET", 
        url: "/v1/docs?contents=false&search="+search+"&limit="+limit+"&offset="+offset,
      }).then(docs);
  };

  Doc.get = function(id) {
    var doc = m.prop("");
    return m.request({
        method: "GET", 
        url: "/v1/docs/"+id+"?raw=true"
      }).then(doc);
  };
  
  Doc.delete = function(id){
    return m.request({
        method: "DELETE", 
        url: "/v1/docs/"+id
      });
  };
  
  Doc.put = function(doc, contentType){
    xhrcfg = u.setContentType(doc, contentType);
    console.log("Doc.put - Saving Document:", doc);
    return m.request({
        method: "PUT", 
        url: "/v1/docs/"+doc.id,
        data: doc.data,
        serialize: function(data){return data;},
        config: xhrcfg
      });
  };
  
  Doc.patch = function(id, updatedTags){
    console.log(updatedTags);
    return Doc.get(id).then(function(doc){
      var tags = doc.tags;
      console.log(tags);
      var count = 0;
      var ops = [];
      tags.forEach(function(tag){
        if (updatedTags[count]){
          if (updatedTags[count] != tag){
            // update tag
            ops.push({"op": "replace", "path": "/tags/"+count, "value": updatedTags[count]});
          }
        } else {
          // delete tag
          ops.push({"op": "remove", "path": "/tags/"+count});
        }
        count++;
      });
      if (updatedTags.length > tags.length) {
        for (i = tags.length; i< updatedTags.length; i++){
          // add tag
          ops.push({"op": "add", "path": "/tags/"+i, "value": updatedTags[i]});
        }
      }
      return m.request({
        method: "PATCH",
        url: "/v1/docs/"+id,
        data: ops
      });
    });
  };
}());