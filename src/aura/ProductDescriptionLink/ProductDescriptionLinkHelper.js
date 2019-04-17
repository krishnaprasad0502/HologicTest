({
	fetchConfig : function(component) {
		var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            console.log('Test check123'+ response.getReturnValue().Hologic_Home__c);
            component.set("v.showContainer",true);
            component.set("v.configSetting", response.getReturnValue()); 
            console.log('Test check123'+component.get("v.configSetting"));
        });
            
        $A.enqueueAction(address1);
	}
})