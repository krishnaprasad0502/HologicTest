({
    checkExistingUser : function (component) {        
       
        var config = component.get('c.checkCommunityUser');        
        config.setParams({ 
            contactId : component.get("v.recordId")
        });
        config.setCallback(this, function(response) { 
            component.set("v.display",response.getReturnValue());
        });
        $A.enqueueAction(config);
    },
	enableCustomerUser : function (component) {        
        var title ;
        var message ;
        var config = component.get('c.enableCommunityUser');        
        config.setParams({ 
            contactId : component.get("v.recordId")
        });
        config.setCallback(this, function(response) { 
            
            if(response.getReturnValue() == 'Success'){
                title = 'Success';
                message = 'Customer User successfully enabled.';            
                component.set("v.callBackMessage",'Email successfully sent with registration link to customer.');
                component.set("v.displayConfirmMessage",true); 
            }else{
                title = 'Failure';
                message = 'Customer User not enabled.'; 
                component.set("v.callBackMessage","Customer User not enabled.");
                component.set("v.displayFailureMessage",true); 
            }
        });
        $A.enqueueAction(config);
        
        /*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message
        });
        toastEvent.fire();*/
    },
    disableCustomerUser : function (component) {        
        var title ;
        var message ;
        var config = component.get('c.disableCommunityUser');        
        config.setParams({ 
            contactId : component.get("v.recordId")
        });
        config.setCallback(this, function(response) { 
            if(response.getReturnValue() == 'Success'){
                title = 'Success';
                message = 'Customer User successfully disabled.'; 
                component.set("v.callBackMessage","Customer User successfully disabled.");
                component.set("v.displayConfirmMessage",true);
                component.set("v.display",true);
            }else{
                title = 'Failure';
                message = 'Customer User not disabled.'; 
                component.set("v.callBackMessage","Customer User not disabled.");
                component.set("v.displayFailureMessage",true); 
            }
        });
        $A.enqueueAction(config);
        
        /*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message
        });
        toastEvent.fire();*/
    },
})