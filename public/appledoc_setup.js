function setup(spec) {
  
  // {"spec_homepage":"https://github.com/tmdvs/TDBadgedCell","versions":["2.1"],"license":" Custom"}
  
  // set the title to the current foldername
  url = window.location.pathname.split("/")
  navTitle = document.getElementById("libraryVersionTitle")
  navTitle.textContent = url[3]
  
  document.getElementById("developerHomepageLink").href = spec.spec_homepage
  
  // add the dropdown
  if(spec.versions.length > 1) {
    libraryVersionList = document.getElementById("libraryVersionList")
    innerHTML = ""
    for (var i = 0; i < spec.versions.length; i++) {
      innerHTML += "<li><a href='../" + spec.versions[i] + "'>"+ spec.versions[i] + "</a></li>"
    }
    libraryVersionList.innerHTML = innerHTML
  } 
}
