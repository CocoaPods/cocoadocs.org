function searchTermChanged() {
  var query = document.getElementById("pod_search").value
  
  if (query.length){
    for ( var i = 0; i < library_names.length; i++ ){
  
      var library = library_names[i];
      var score = library.score(query);
      var library_cell = document.getElementById(library)
  
      if (score > 0.2){
      	library_cell.style.display = 'inline-block'
      } else {
        library_cell.style.display = 'none'
      }
    }
  } else {
  
    for ( var i = 0; i < library_names.length; i++ ){
      var library = library_names[i];
      var library_cell = document.getElementById(library)
      library_cell.style.display = 'inline-block'
    }
  }
}

function getLibraries(){
  var libraries = document.getElementsByClassName("library")
  var all_selectors = []
  
  for ( var i = 0; i < libraries.length; i++ ){
    var library = libraries[i]
    all_selectors.push(library.id)
  }
  
  return all_selectors;
}

var library_names = getLibraries();