({
    doInit : function(component, event, helper) {
        var action = component.get("c.checkFavouriteArticle");
		action.setParams({ 
			articleId : component.get("v.recordId")
		});
		action.setCallback(this,function(response){
            component.set("v.display",response.getReturnValue());
		});
		$A.enqueueAction(action); 
        
        // Prepare a new record from template
        component.find("feedbackRecordCreator").getNewRecord(
            "Community_Article_Feedback__c", // sObject type (objectApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newarticleFeedback");
                var error = component.get("v.newFeedbackError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                    return;
                }
                //component.set("v.simpleArticleFeedback.Community_Knowledge__c", component.get("v.recordId"));
                console.log("Record template initialized: " + rec.sobjectType);
            })
        );
	},
	/*Method updates the current record to favorite for loggedin User*/
    UpdateRecordtoFavourite : function(component, event, helper) {
        
    	var action = component.get("c.UpdateFavouriteArticle");
		action.setParams({ 
			articleId : component.get("v.recordId")
		});
        action.setCallback(this,function(response){
            if(response.getReturnValue() == 'Success'){
                component.set("v.display","True");
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message: response.getReturnValue(),
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error'
                });
                toastEvent.fire();
            }
        });
		$A.enqueueAction(action);     
    },
    
	/*Method removes the current record as favorite for loggedin User*/    
	RemoveFavourite : function(component, event, helper) {
    	var action1 = component.get("c.removeFavouriteArticle");
		action1.setParams({ 
			articleId : component.get("v.recordId")
		});
        action1.setCallback(this,function(response){
            if(response.getReturnValue() == 'Success'){
                component.set("v.display","False");
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message:response.getReturnValue(),
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error'
                });
                toastEvent.fire();
            }
        });
		$A.enqueueAction(action1);   
    },
    openModel: function(component, event, helper) {
      // for Display Model,set the "isOpen" attribute to "true"
      component.set("v.isOpen", true);
   },
 
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   }, 
   SubmitFeedback: function(component, event, helper) {
       component.set("v.simpleArticleFeedback.Community_Knowledge__c", component.get("v.recordId"));
       component.find("feedbackRecordCreator").saveRecord(function(saveResult) {
           if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
               // record is saved successfully
               var resultsToast = $A.get("e.force:showToast");
               resultsToast.setParams({
                   "title": "Saved",
                   "message": "The record was saved."                   
               });
               $A.get('e.force:refreshView').fire();
               resultsToast.fire();
               component.set("v.isOpen", false);
           } else if (saveResult.state === "INCOMPLETE") {
               // handle the incomplete state
               console.log("User is offline, device doesn't support drafts.");
           } else if (saveResult.state === "ERROR") {
               // handle the error state
               console.log('Problem saving Feedback, error: ' + JSON.stringify(saveResult.error));
           } else {
               console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
           }
       });       
       
   }

})