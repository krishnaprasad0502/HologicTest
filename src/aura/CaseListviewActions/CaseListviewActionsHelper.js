({
    /*Invokes SubmitNewCase component*/
	InvokeComponent: function(component, event, helper) {
        component.set("v.isOpen", true);
        var Type = component.get("v.Type2");
        var subType = component.get("v.SubType2");
        var Priority = component.get("v.Priority2");
        var isListViewAction = component.get("v.isListViewAction");
        // get CaseTitle set to defualt priority to Sev 2 US-0006454
		var CaseTitle = component.get("v.CaseTitle");
        
		$A.createComponent("c:SubmitNewCase",{
            "aura:id" : "CaseComp",
            "CaseType" : Type,
            "CaseSubType" : subType,
            "CasePriority" : Priority,
            "isListViewAction" : isListViewAction,
            "CaseSubject" : component.get("v.Subject"),
            "CaseTitle" : CaseTitle
        }, function(newCmp,status,errorMessage) {
            if (component.isValid()) {
                if(status == "ERROR") {
                    console.log('Error Message--',errorMessage);
                }
                component.set("v.comp", newCmp);
            }
        });
    },
    /*Invokes DisposableProductIssueForm component*/
	InvokeDisposableComponent: function(component, event, helper) {
        component.set("v.isOpen", true);
        var Type = component.get("v.Type2");
        var subType = component.get("v.SubType2");
        var Priority = component.get("v.Priority2");
        var isListViewAction = component.get("v.isListViewAction");
        // get CaseTitle set to defualt priority to Sev 2 US-0006454
		var CaseTitle = component.get("v.CaseTitle");
        
		$A.createComponent("c:DisposableProductIssueForm",{
            "aura:id" : "CaseComp",
            "CaseType" : Type,
            "CaseSubType" : subType,
            "CasePriority" : Priority,
            "isListViewAction" : isListViewAction,
            "CaseSubject" : component.get("v.Subject"),
            "CaseTitle" : CaseTitle
        }, function(newCmp,status,errorMessage) {
            if (component.isValid()) {
                if(status == "ERROR") {
                    console.log('Error Message--',errorMessage);
                }
                component.set("v.comp", newCmp);
            }
        });
    },
    OpenServiceAppointments : function (component) {
        var urlEvent = $A.get("e.force:navigateToURL");
        var urlAddress = component.get("v.configSetting.SiteURL__c")+component.get("v.configSetting.View_Service_Appointments__c");
        urlEvent.setParams({
          "url": urlAddress
        });
        urlEvent.fire();
    }
})