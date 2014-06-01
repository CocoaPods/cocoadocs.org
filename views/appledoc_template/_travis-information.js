var github_element = document.getElementById("open_in_github");

if (github_element) {
	var github_username = github_element.attributes["data-github-username"].value;
	var github_repo = github_element.attributes["data-github-repo"].value;
	var github_ref = github_element.attributes["data-github-ref"].value;

	var script = document.createElement( "script" );
	script.type = "text/javascript";
	script.src = "https://api.travis-ci.org/repos/" + github_username + "/" + github_repo + "/branches/" + github_ref + "?callback=travisCallback";
	document.body.appendChild(script);
}

function travisCallback (data) {
	var list_item = document.getElementById("travis");
	var anchor = list_item.children[0];

	if (data["branch"]["state"] == "passed") {
		list_item.className = "green";
	} else {
		list_item.className = "red";
	}

	console.log(data["branch"]);
	anchor.href = "https://travis-ci.org/" + github_username + "/" + github_repo + "/builds/" + data["branch"]["id"];
}
