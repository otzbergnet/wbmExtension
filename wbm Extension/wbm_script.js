//check if we are in a frame
var shortcut = "y"

if (window.top === window) {
    
    console.log("Wayback Machine Extension successfully loaded");
    
    document.addEventListener("DOMContentLoaded", function(event) {

        var wbmTrackCall =setInterval(function(){
            if (!document.hidden) {
                clearInterval(wbmTrackCall);
                safari.self.addEventListener("message", messageHandler);
                document.addEventListener("contextmenu", handleContextMenu, false);
                safari.extension.dispatchMessage("shortcut", {"msgID" : "1"});
                safari.extension.dispatchMessage("pageHistoryInject");
                doBoost5();
            }
        },500);
        
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
            break;
        case "inject":
            inject = event.message.inject
            if(inject){
                injectPageHistoryButton();
            }
            break;
        case "boost5result":
            handleBookst5Result(event.message);
            break;
        default:
            //
    }
}

function handleContextMenu(event) {
    var target = event.target;
    while(target != null && target.nodeType == Node.ELEMENT_NODE && target.nodeName.toLowerCase() != "a") {
        target = target.parentNode;
    }
    clickedURL = target.href;
    if(clickedURL != undefined && clickedURL != null && clickedURL != ""){
        safari.extension.setContextMenuEventUserInfo(event, { "href": clickedURL });
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

function doBoost5(){
    
    let boost5Element = document.getElementById('web_boost5');
    if (boost5Element == undefined || boost5Element == null){
        safari.extension.dispatchMessage("boost5", {"url" : document.location.href});
    } else{
        let count = boost5Element.dataset.boost5count;
        let date = boost5Element.dataset.boost5date;
        if(count != "n" && date != "n"){
            safari.extension.dispatchMessage("wbm_showBadge", {"count": count});
        } else{
            let message = [];
            message.boost5count = "n"
            message.boost5date = "n";
            handleBookst5Result(message);
        }
        
    }
    
}

function handleBookst5Result(message){
    let div = document.createElement('div');
    div.setAttribute("id", "boost5");
    div.dataset.success = "y"
    div.dataset.count = message.boost5count;
    div.dataset.date = message.boost5date;
    document.body.appendChild(div);
}
