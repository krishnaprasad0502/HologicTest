({
	/*Invokes SubmitNewCase component*/
	InvokeComponent: function(component, event, helper) {
        component.set("v.isOpen", true);
        var Type = component.get("v.Type");
        var subType = component.get("v.SubType");
        var Subject = component.get("v.Subject");
        var Priority = component.get("v.Priority");
        var isListViewAction = component.get("v.isListViewAction");
		$A.createComponent("c:SubmitNewCase",{
            "aura:id" : "CaseComp",
            "CaseType" : Type,
            "CaseSubType" : subType,
            "CaseSubject" : Subject,
            "CasePriority" : Priority,
            "isListViewAction" : isListViewAction
        }, function(newCmp,status,errorMessage) {
            if (component.isValid()) {
                if(status == "ERROR") {
                    console.log('Error Message--',errorMessage);
                }
                component.set("v.comp", newCmp);
            }
        });
    }
})