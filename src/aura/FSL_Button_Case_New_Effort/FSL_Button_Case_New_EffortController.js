({
    newEffort : function(component, event, helper) {

        var caseId = component.get("v.recordId"),
            effortName = component.get("v.effortName"),
            userId = $A.get("$SObjectType.CurrentUser.Id");

        // ## Old process values
        // var urlEvent = $A.get("e.force:navigateToURL");
        // urlEvent.setParams({
        //     "url": 'a5v/e?retURL=%2F' + {!Case.Id} 
        //         + '&CF00N6100000FE33P=' + {!JSENCODE(User.Name)}
        //         + '&CF00N6100000FE33P_lkid=' + {!$User.Id}
        //         + '&CF00N6100000FE33O=' + {!Case.CaseNumber}
        //         + '&CF00N6100000FE33O_lkid=' + {!Case.Id}
        // });
        // urlEvent.fire();

        // ## Case Effort Object fields
        // Session_Time__c.Name = effortName
        // Session_Time__c.CreatedById = userId
        // Session_Time__c.Case__c = caseId

        // Create Case Effort
        // var createCaseEffort = $A.get("e.force:createRecord");
        // createCaseEffort.setParams({
        //     "entityApiName": "Session_Time__c",
        //     "defaultFieldValues": {
        //         'Name' : effortName,
        //         'CreatedById' : userId,
        //         'Case__c' : caseId
        //     }
        // });
        // createCaseEffort.fire();

        // Display "toast" status message
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            'title': 'New Case Effort added',
            'message': '"' + effortName + '" has been added to Case ' + caseId
        });
        resultsToast.fire();

        // Close the action panel
        // var dismissActionPanel = $A.get("e.force:closeQuickAction");
        // dismissActionPanel.fire();
    }
})