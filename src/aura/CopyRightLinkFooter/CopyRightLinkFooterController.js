({
    doInit: function(component) {
       var address=component.get('c.fetchConfigData'); 
       address.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue());   
        });
        $A.enqueueAction(address);
    }
    
})