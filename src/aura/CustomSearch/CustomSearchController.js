({
    handleClick : function(component, event, helper) {
      var searchText = component.get('v.searchText');
        if(searchText.length < 1){
            throw new Error("Your search term must have 2 or more characters.");
        }
      if(component.get('v.searchType') =='Global'){
         helper.callSearch(component);  
      }else if(component.get('v.searchType') =='Knowledge'){
         var dataCategory = component.get('v.dataCategory');
         helper.callKnowledgeSearch(component,searchText,dataCategory);
      }else{
          var action = component.get('c.searchForIds');
          action.setParams({searchText: searchText});
          action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
              var ids = response.getReturnValue();
            }
          });
    
          $A.enqueueAction(action);
      }
    },
    onKeyUp: function(component, event, helpler){
        //checks for "enter" key
        var vc = event.getParam('keyCode') ;
        if (event.getParam('keyCode')===13) {
            
            var searchText = component.get('v.searchText');
            if(searchText.length < 1){
                throw new Error("Your search term must have 2 or more characters.");
            }
            if(component.get('v.searchType') =='Global'){
                var urlEvent = $A.get("e.force:navigateToURL");
                var searchString = component.get("v.searchText");
                urlEvent.setParams({
                    "url": "/global-search/"+ searchString 
                });
                urlEvent.fire(); 
            }else if(component.get('v.searchType') =='Knowledge'){
                var urlEvent = $A.get("e.force:navigateToURL");
                var searchString = searchText ;
                var dynamicurl ;
                if((searchText != '' && searchText != null) && (dataCategory != '' && dataCategory != null)){
                    dynamicurl = "/knowledgebase/?searchtext="+ searchString +"&category="+ dataCategory ;
                }else if(searchText != '' && searchText != null){
                    dynamicurl = "/knowledgebase/?searchtext="+ searchString  ;
                }else if(dataCategory != '' && dataCategory != null){
                    dynamicurl = "/knowledgebase/?category="+ dataCategory  ;
                }else{
                    dynamicurl = "/knowledgebase/" ;
                }
                urlEvent.setParams({
                    "url": dynamicurl
                });
                urlEvent.fire();
            }else{
                var action = component.get('c.searchForIds');
                action.setParams({searchText: searchText});
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        var ids = response.getReturnValue();
                    }
                });
                
                $A.enqueueAction(action);
            }
        }
    }
})