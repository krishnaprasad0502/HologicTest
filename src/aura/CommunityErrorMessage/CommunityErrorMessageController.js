({
	doInit: function(component, event, helper) {
        
        var action = component.get("c.fetchConfigData");
        action.setCallback(this, function(actionResult) {
            component.set("v.congifDetail", actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
    
    }
})