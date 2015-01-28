
function jumpToChange()
{
	window.location.hash = this.options[this.selectedIndex].value;
}

function toggleTOC()
{
	var contents = document.getElementById('contents');
	var tocContainer = document.getElementById('tocContainer');

	if (this.getAttribute('class') == 'open') {
		this.setAttribute('class', '');
		contents.setAttribute('class', '');
		tocContainer.setAttribute('class', '');

		window.name = "hideTOC";
	}
	else
	{
		this.setAttribute('class', 'open');
		contents.setAttribute('class', 'isShowingTOC');
		tocContainer.setAttribute('class', 'isShowingTOC');

		window.name = "";
	}
	return false;
}

function toggleTOCEntryChildren(e)
{
	e.stopPropagation();
	var currentClass = this.getAttribute('class');
	if (currentClass == 'children') {
		this.setAttribute('class', 'children open');
	}
	else if (currentClass == 'children open') {
		this.setAttribute('class', 'children');
	}
	return false;
}

function tocEntryClick(e)
{
	e.stopPropagation();
	return true;
}

function init()
{
	var taskTreeItem = document.getElementById('task_treeitem');
	if (taskTreeItem.getElementsByTagName('li').length > 0) {
		taskTreeItem.setAttribute('class', 'children open');
    taskTreeItem.firstChild.setAttribute('class', 'disclosure');
	}

	var tocList = document.getElementById('toc');
	var tocEntries = tocList.getElementsByTagName('li');

	for (var i = 0; i < tocEntries.length; i++) {
    if(tocEntries[i].getAttribute("role") == "treeitem" && tocEntries[i].getAttribute("class") == "children"){
      tocEntries[i].setAttribute('class', 'children open');
    }

		tocEntries[i].addEventListener('click', toggleTOCEntryChildren, false);
	}

  // Too big? Make it scroll
  if(tocList.clientHeight > window.screen.availHeight){
    document.getElementById("tocContainer").style.position = "static";
  }

	var tocLinks = tocList.getElementsByTagName('a');
	for (var i = 0; i < tocLinks.length; i++) {
		tocLinks[i].addEventListener('click', tocEntryClick, false);
	}
}

window.onload = init;
