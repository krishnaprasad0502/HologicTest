({
	init : function(component, event, helper) {
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue());  
        });
        var action = component.get('c.fetchBreadCrumbData');
        action.setParams({ 
			topicId : component.get("v.recordId"),
		});
        action.setCallback(this, function(response) { 
            component.set("v.topicBreadcrumbs", response.getReturnValue()); 
        });   
        
        $A.enqueueAction(address1);
        $A.enqueueAction(action);
	}
})