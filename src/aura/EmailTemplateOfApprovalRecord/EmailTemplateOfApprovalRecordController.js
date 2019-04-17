({
	DisplayEmailTemplateApprovalDetails : function(component, event, helper) {
                var action = component.get('c.DisplayDetailsForOneRecord');
         action.setParams({
            'ApprovalId':component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 console.log('testRESSSS'+storeResponse);
                var storeResponse = response.getReturnValue();
                console.log('testRESSSS'+storeResponse);
                component.set("v.objClassController",storeResponse);
                if( component.get("v.objClassController.ApprovalDetails.Quote__r.Account_Name__c")!=undefined && component.get("v.objClassController.ApprovalDetails.Quote__r.SBQQ__Opportunity2__r.Owner.Name")!=undefined)
                {
                     component.set("v.Subject",component.get("v.objClassController.ApprovalDetails.Quote__r.Account_Name__c")+ ' - '+ component.get("v.objClassController.ApprovalDetails.Quote__r.Name")+','+ component.get("v.objClassController.ApprovalDetails.Quote__r.SBQQ__Opportunity2__r.Owner.Name"));
                 }
                else if(component.get("v.objClassController.ApprovalDetails.Quote__r.Account_Name__c")!=undefined)
                {
                  component.set("v.Subject",component.get("v.objClassController.ApprovalDetails.Quote__r.Account_Name__c") +' - ' + component.get("v.objClassController.ApprovalDetails.Quote__r.Name"));
                
                }
                else if(component.get("v.objClassController.ApprovalDetails.Quote__r.SBQQ__Opportunity2__r.Owner.Name")!=undefined)
                {
                     component.set("v.Subject",component.get("v.objClassController.ApprovalDetails.Quote__r.Name") +','+ component.get("v.objClassController.ApprovalDetails.Quote__r.SBQQ__Opportunity2__r.Owner.Name"));
                }
                else
                {
                   component.set("v.Subject",component.get("v.objClassController.ApprovalDetails.Quote__r.Name"));
                }
               /* var approval = component.get("v.objClassController.approvalsOfQuote");
                    var fieldNames = component.get("v.objClassController.fieldAPINames");
                    var NewBody = "";
                 for (var i=0; i<approval.length; i++){
                        for (var ii=0; ii<fieldNames.length; ii++){
                            if(approval[i][fieldNames[ii]]==undefined)
                            {
                                NewBody += ' '+' ';
                            }
                            else
                            {
                                 NewBody += approval[i][fieldNames[ii]]+' ';
                            }
                           
                        }
                        NewBody += "\n";
                    }
                    console.log(NewBody);
                    $A.createComponent(
                        "ui:outputText",
                        {
                            "value" : NewBody
                        },
                        function(newComponent){
                            component.set("v.body",newComponent);
                        }
                    )*/
                
            }
        });
     
  
       $A.enqueueAction(action);
		
		
	},
})