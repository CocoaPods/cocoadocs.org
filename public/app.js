// var server = "file:///Users/orta/spiel/html/cocoadocs/activity/html/index.html"
var server = "http://cocoadocs.org"

// set the query based on the q=X syntax
var query_bits = window.location.search.split("q=")
if(query_bits.length > 1){
  var search_term = query_bits[1]
  document.getElementById("pod_search").value = search_term
}

// This gets called form the keyboard
// we check here to ensure arrow keys don't trigger 
// data refreshed

function podSearchHasChanged() {
  var query = document.getElementById("pod_search").value
  if (old_query != query) {
    searchTermChanged();
  }  
}

var old_query;
var filtered_results;
function searchTermChanged() {

  var query = document.getElementById("pod_search").value
  old_query = query
  
  filtered_results = []

  $.getJSON("http://cocoapods.org/api/v1.5/pods/search?query=" + query, function( data ) {
    filtered_results = data.concat(filtered_results)
    createList()
  });
  
  if (query.length) {
    window.history.replaceState( {} , 'CocoaDocs', server + '/?q=' + query );
    
    document.getElementById("about").style.display = "none"

    if(window.appledocs) {
      for ( var i = 0; i < appledocs.length; i++ ){
        var doc_name = appledocs[i]["name"];
        var score = doc_name.score(query);

        // Look in the titles of apples docs, but reduce their score
        // to put spec libraries first 
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
      window.history.replaceState( {} , 'CocoaDocs', server);
    }
  }

  createList()
}

function createList(){

  // sort by score
  var results = filtered_results.sort(function(a, b){
    return b["score"] - a["score"]
  })
  
  var query = document.getElementById("pod_search").value
  var showNotFound = (results.length != 0 || query.length == 0 ) ? "none" : "block"
  document.getElementById("no_results").style.display = showNotFound

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
      
      var url = is_apple? spec["url"] : "http://cocoadocs.org/docsets/" + spec["id"] + "/"
      var heading = is_apple? spec["name"] : spec["id"]
      var side_heading = is_apple? spec["framework"] : spec["version"]
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