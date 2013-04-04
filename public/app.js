// This is for the front page

function searchTermChanged() {
  if(!window.specs) return
  
  var query = document.getElementById("pod_search").value
  var filtered_results = [];
  var results = specs;
  
  if (query.length){
    for ( var i = 0; i < specs.length; i++ ){
  
      var library_name = specs[i]["name"];
      var score = library_name.score(query);
      
      if (score > 0.2){
        specs[i]["score"] = score
      	filtered_results.push( specs[i] )
      } 
    }

    // sort by score
    results = filtered_results.sort(function(a, b){
      return b["score"] - a["score"]
    })
    
    var showNotFound = (results.length != 0) ? "none" : "block"
    document.getElementById("no_results").style.display = showNotFound
  }


  
  var documents = ""
  for ( var i = 0; i < results.length; i++ ){
    var spec = results[i]
    documents += "<div class='library'><div class ='content'>"
    
    documents += "<h2><a href='" + spec["doc_url"] + "'>" + spec["name"] + "</a></h2>"
    documents += "<h3><a href='" + spec["homepage"] + "'>" + spec["user"] + "</a></h3>"
    documents += "<p>" + spec["summary"] + "</p>"
    documents += "<a href='" + spec["doc_url"] + "' class='button'>" + spec["main_version"] + "</a>"
    
    documents += "</div></div>"    
  }
  
  document.getElementById("loading").style.display = "none"
  document.getElementById("items").innerHTML = documents   
}
