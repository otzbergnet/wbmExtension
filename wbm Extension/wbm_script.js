//check if we are in a frame
var shortcut = "y"

if (window.top === window) {
    
    console.log("Wayback Machine Extension successfully loaded");
    
    safari.self.addEventListener("message", messageHandler);
    safari.extension.dispatchMessage("shortcut", {"msgID" : "1"});
    
    //mostly useless and we should remove
    document.addEventListener("DOMContentLoaded", function(event) {
        safari.extension.dispatchMessage("Hello World!");
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
    }
    
    
}
