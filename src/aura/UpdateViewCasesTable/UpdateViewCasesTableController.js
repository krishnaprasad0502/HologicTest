({
    initRecords: function(component, event, helper) {
        var action = component.get("c.fetchAccount");
        action.setParams({ 
            contactId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                console.log(JSON.stringify(storeResponse));
                // set AccountContactrelationList list with return value from server.
                component.set("v.AccountList", storeResponse);
            }
        });
        $A.enqueueAction(action);
    },
    
    Save: function(component, event, helper) {
        // Check required fields(Name) first in helper method which is return true/false
        if (helper.requiredValidation(component, event)){
            // call the saveAccount apex method for update inline edit fields update 
            var action = component.get("c.saveAccount");
            action.setParams({
                'lstAccount': component.get("v.AccountList")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var storeResponse = response.getReturnValue();
                    // set AccountList list with return value from server.
                    component.set("v.AccountList", storeResponse);
                    // Hide the save and cancel buttons by setting the 'showSaveCancelBtn' false 
                    component.set("v.showSaveCancelBtn",false);
                    $A.get('e.force:refreshView').fire();
                }
            });
            $A.enqueueAction(action);
        } 
    },
    
    cancel : function(component,event,helper){
        // on cancel refresh the view (This event is handled by the one.app container. It’s supported in Lightning Experience, the Salesforce app, and Lightning communities. ) 
        $A.get('e.force:refreshView').fire(); 
    } 
    
})