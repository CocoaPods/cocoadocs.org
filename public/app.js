// This is for the front page

function searchTermChanged() {
  if(!window.specs) return
  
  var query = document.getElementById("pod_search").value
  var filtered_results = [];
  var results;
  
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
  if(results) {
    for ( var i = 0; i < results.length; i++ ){
      var spec = results[i]
      if(i == 0){
        documents += "<li class='selected'>"
        
      }else if(i == 1){
        documents += "<li class='next'>"
        
      } else {
        documents += "<li>"
      }

      documents += "<a href='" + spec["doc_url"] + "'>"
    
      documents += "<h2>" + spec["name"] + "</h2>"
      documents += "<h3>" + spec["main_version"] + "</h3>"
      documents += "<p>" + spec["summary"] + "</p>"
    
      documents += "</a></li>"    
    }
  }  
  
  document.getElementById("loading").style.display = "none"
  document.getElementById("results").innerHTML = documents   
}

document.onclick = function(){ document.getElementById('pod_search').focus(); }

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
            openNextSelection()
            break;
        // Down
        case 40:
            alert('down pressed');
            break;
    }
}

function openNextSelection(){
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