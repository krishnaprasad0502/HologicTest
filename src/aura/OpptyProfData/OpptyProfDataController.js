({
	doInit: function (component, event, helper) {
		var action = component.get("c.findAll");
       
        action.setParams({"opptyId": component.get("v.recordId")});
		action.setCallback(this, function(a){
			component.set("v.profDatas", a.getReturnValue());
            component.set("v.profDatasSize", a.getReturnValue().length);
        })
		$A.enqueueAction(action);

	},
     checkAllCheckboxes : function(component, event, helper) {
        var checkboxes = component.find("DependentCheckbox");
        var masterchkbox = component.find("MasterCheckbox");
        for (var i = 0; i < checkboxes.length; i++){
            if(masterchkbox.get("v.value") == true)
            	checkboxes[i].set("v.value",true);
            else
                checkboxes[i].set("v.value",false);
        }
    },
    uncheckMasterCheckbox : function(component, event, helper) {
        var checkboxes = component.find("DependentCheckbox");
        var masterchkbox = component.find("MasterCheckbox");
        var selectedCount = 0;
        var unselectedCount = 0;
        for (var i = 0; i < checkboxes.length; i++){
            if(checkboxes[i].get("v.value") == true)
            	selectedCount++;
            else
                unselectedCount++;
        }
        if(selectedCount == checkboxes.length)
            masterchkbox.set("v.value",true);
        else if(unselectedCount > 0)
            masterchkbox.set("v.value",false);
    },
    cancel : function(component, event, helper){
    	$A.get("e.force:closeQuickAction").fire();
    },
    savePP : function(component, event, helper){
        var action = component.get("c.saveProfData");
        event.getSource().set("v.disabled", true);
        action.setParams({"wrapProfDataList": JSON.stringify(component.get("v.profDatas")),"opptyId": component.get("v.recordId")});
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire()
            }
            else if(state == "INCOMPLETE"){
                throw new Error('Unable to process the current request');
            }
            else if(state == "ERROR"){
            	var errors = response.getError();
                var message = "Error inserting Pipeline Products:";
                let toastParams = {
        							title: "Error",
        							message: "", // Default error message
        							type: "error"
    							 };
                if(errors && errors.length > 0){
                    for(var i=0; i<errors.length; i++){
                        message = errors[i].message;
                    }
                    toastParams.message = message;
                }
                let toastEvent = $A.get("e.force:showToast");
    			toastEvent.setParams(toastParams);
    			toastEvent.fire();
            }
                
        });
        $A.enqueueAction(action);
        
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
       component.set("v.Spinner", true); 
    },
    
 	// this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
    	// make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
    }
    
})