({
    gotoURL : function (component) {        
        var navEvt = $A.get("e.force:navigateToList");
    	navEvt.setParams({
      		"recordId": "",
       		"listViewId": "00B61000002dX9SEAU",
			"listViewName": null,
            "scope": "Product2"
    	});
    	navEvt.fire();
    },
})