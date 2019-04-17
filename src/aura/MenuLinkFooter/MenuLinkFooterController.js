({
	doInit : function(component, event, helper) {
       var address=component.get('c.getCurrentUser'); 
       address.setCallback(this, function(response) { 
            component.set("v.userInfo", response.getReturnValue()); 
       });		
       var address1 = component.get('c.fetchConfigData'); 
       address1.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());  
       }); 
        $A.enqueueAction(address);
        $A.enqueueAction(address1);
	}
})