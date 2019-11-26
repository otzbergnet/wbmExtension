//check if we are in a frame
var shortcut = "y"

if (window.top === window) {
    
    console.log("Wayback Machine Extension successfully loaded");
    
    document.addEventListener("DOMContentLoaded", function(event) {
        safari.self.addEventListener("message", messageHandler);
        document.addEventListener("contextmenu", handleContextMenu, false);
        safari.extension.dispatchMessage("shortcut", {"msgID" : "1"});
        safari.extension.dispatchMessage("pageHistoryInject");
    });
    
    //detect ctrl+w for pageHistory
    document.addEventListener('keyup', function (event) {
      if (event.ctrlKey) {
        switch (event.key) {
          case shortcut:
              safari.extension.dispatchMessage("wbm_pageHistory", {"source": "shortcut"}); break
        }
      }
    })
}

function messageHandler(event){
    switch (event.name){
        case "shortcut":
            shortcut = event.message.shortcut
            console.log("use ctrl + "+shortcut+" to open the Page History")
        case "inject":
            inject = event.message.inject
            if(inject){
                injectPageHistoryButton();
            }
    }
}

function handleContextMenu(event) {
    var link =  window.getSelection().anchorNode.parentNode.href
    if(link != undefined){
        safari.extension.setContextMenuEventUserInfo(event, { "href": link });
    }
    else{
        safari.extension.setContextMenuEventUserInfo(event, { "href": "-" });
    }
}

function injectPageHistoryButton(){
    var src = safari.extension.baseURI + "wbm.png";
    
    var div = document.createElement('div');
    div.innerHTML = '<div class="wbm_pagehistory" id="wbm_pagehistory" title="Click to show Page History in Wayback Machine"><img id="wbm_logo" src="'+src+'" title="Click to show Page History in Wayback Machine" /></div>';
    div.id = 'wbm_pagehistory_outer';
    div.className = 'wbm_pagehistory_outer';
    
    if(document.body.parentNode.parentNode != "#document"){
        document.body.appendChild(div);
    }
    watchPageHistory();
}

function watchPageHistory(){
    document.getElementById("wbm_pagehistory").addEventListener("click", handlePageHistory);
}

function handlePageHistory(){
    safari.extension.dispatchMessage("wbm_pageHistory", {"source": "shortcut"});
}
