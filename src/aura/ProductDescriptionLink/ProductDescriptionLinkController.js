({
	doInit: function(component) {
        console.log('Description is:'+ component.get("v.productDescription"));
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting",response.getReturnValue());
        });
        
        var address=component.get('c.getProductDescriptionRecord');
        address.setParams({ 
			communityDescription : component.get("v.productDescription"),
            listViewName: component.get("v.listViewName")
		});
        address.setCallback(this, function(response) { 
            component.set("v.productRec", response.getReturnValue());
            component.set("v.showContainer",true)
            console.log('PROD Id is:'+ component.get("v.productRec"));
        });
        
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting",response.getReturnValue());
        });
                     
        $A.enqueueAction(address1);
        $A.enqueueAction(address);        
    }
})