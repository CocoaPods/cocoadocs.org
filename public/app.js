// set the query based on the q=X syntax
var query_bits = window.location.search.split("q=")
if(query_bits.length > 1){
  var search_term = query_bits[1]
  document.getElementById("pod_search").value = search_term
}

var old_query;
function searchTermChanged() {

  var query = document.getElementById("pod_search").value
  old_query = query
  
  var filtered_results = []
  var results

  
  if (query.length) {
    window.history.replaceState( {} , 'CocoaDocs', 'http://cocoadocs.org/?q=' + query );
    
    document.getElementById("about").style.display = "none"

    if(window.specs) {
      for ( var i = 0; i < specs.length; i++ ){
        var library_name = specs[i]["name"];
        var score = library_name.score(query);
    
        if (score > 0.2){
          specs[i]["score"] = score
        	filtered_results.push( specs[i] )
        } 
      }
    }

    if(window.appledocs) {
      for ( var i = 0; i < appledocs.length; i++ ){
        var doc_name = appledocs[i]["name"];
        var score = doc_name.score(query);

        // Look in the titles
        if (score > 0.4){
          appledocs[i]["score"] = score - (0.3)
        	filtered_results.push( appledocs[i] )
        
        } else {

          // Also do a per-framework search
          var doc_name = appledocs[i]["framework"];
          var score = doc_name.score(query);
          if (score > 0.4) {
            appledocs[i]["score"] = score - (0.3)
        	  filtered_results.push( appledocs[i] )
          }
        }
      }
    } else {
      window.history.replaceState( {} , 'CocoaDocs', "http://cocoadocs.org");
    }

    // sort by score
    results = filtered_results.sort(function(a, b){
      return b["score"] - a["score"]
    })
    
    var showNotFound = (results.length != 0) ? "none" : "block"
    document.getElementById("no_results").style.display = showNotFound
  }

  var documents = ""
  if(results) {
    for ( var i = 0; i < results.length; i++ ){
      var spec = results[i]
      var class_name = ""
      if(i == 0){
        class_name += "selected"
      }

      var is_apple = spec["url"] 
      
      if (is_apple) {
        class_name += " apple"
      }
      
      var url = is_apple? "https://developer.apple.com/library/ios/navigation/" + spec["url"] : spec["doc_url"]
      var heading = spec["name"]
      var side_heading = is_apple? spec["framework"] : spec["main_version"]
      var body = is_apple? spec["type"] : spec["summary"]
      
      documents += "<li class='" + class_name + "'>"
      documents += "<a href='" + url + "'>"
  
      documents += "<h2>" + heading + "</h2>"
      documents += "<h3>" + side_heading + "</h3>"
      documents += "<p>" + body + "</p>"
  
      documents += "</a><div style='clear:both'></div></li>"
    }
  }  
  
  document.getElementById("loading").style.display = "none"
  document.getElementById("results").innerHTML = documents   
}

document.onclick = function(){ 
  var x = window.scrollX, y = window.scrollY;
  document.getElementById('pod_search').focus();
  window.scrollTo(x, y);
}

el = document.body;
if (typeof el.addEventListener != "undefined") {
    el.addEventListener("keydown", function(evt) {
        doThis(evt.keyCode);
    }, false);
} else if (typeof el.attachEvent != "undefined") {
    el.attachEvent("onkeydown", function(evt) {
        doThis(evt.keyCode);
    });
}

function doThis(key) {
    switch (key) {
        // Enter
        case 13:
            openCurrentSelection()
            break;
        // Escape
        case 27:
            resetSelection()
            break;
        // Up
        case 38:
            gotoPreviousSelection()
            break;
        // Down
        case 40:
            gotoNextSelection()
            break;
    }
}

function gotoNextSelection(){
  var results = document.getElementById("results").children
  for ( var i = 0; i < results.length; i++ ){
    
    var child = results[i]
    if(child.className == "selected"){
      if(i == results.length - 1) return;

      var nextSelection = results[i + 1];
      child.className = ""
      
      nextSelection.className = "selected"
      return;
    }
  }
  results[0].className = "selected"
}

function gotoPreviousSelection(){
  var results = document.getElementById("results").children
  for ( var i = 0; i < results.length; i++ ){
    
    var child = results[i]
    if(child.className == "selected"){
      if(i == results.length - 0) return;
      var nextSelection = results[i - 1];
      child.className = ""
      
      nextSelection.className = "selected"
      return;
    }
  }
}
 
function resetSelection(){
  var input = document.getElementById('pod_search')
  input["value"] = ""
  input.focus()
}

function openCurrentSelection(){
  var selectedItemArray = document.getElementsByClassName("selected")

  if (selectedItemArray.length) {
    var item = selectedItemArray[0]
    var link = item.childNodes[0]
    window.document.location.href = link.href;
  }
}