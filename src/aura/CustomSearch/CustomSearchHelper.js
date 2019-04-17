({
    callSearch : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var searchString = component.get("v.searchText");
        urlEvent.setParams({
          "url": "/global-search/"+ searchString 
        });
        urlEvent.fire();
    },
    callKnowledgeSearch : function (component,searchText,dataCategory) {
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
    }
})