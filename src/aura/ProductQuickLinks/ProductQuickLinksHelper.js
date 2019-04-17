({
	gotoURL : function (component,field1Value) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.menuUrl");
        if(component.get("v.MenuType") != 'My Systems'
           && component.get("v.MenuType") != 'Quick Links' && field1Value != null){
            urlAddress = urlAddress +'&category='+ field1Value ;
        }else if(component.get("v.MenuType") == 'My Systems'){
            urlAddress = urlAddress +'?description='+ field1Value ;
        }
        urlEvent.setParams({
          "url": urlAddress 
        });
        urlEvent.fire();
    }
})