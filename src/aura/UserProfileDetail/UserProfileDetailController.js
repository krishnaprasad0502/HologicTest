({
    doInit: function(component, event, helper) {
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue());  
        });
		var action = component.get("c.fetchUser");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.userInfo", response.getReturnValue());
            }else if (state === "INCOMPLETE") {
                var error = $A.get("$Label.c.Service_Try_Again_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                console.log("User is offline, device doesn't support drafts.");
            } 
            else if (state === "ERROR") {
                var error = $A.get("$Label.c.Service_Unknown_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
             }
             else {
                 var error = $A.get("$Label.c.Service_Unknown_Error");
                 component.set("v.errorMessage",error);
                 component.set("v.showError",true);
                 console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
             }
        });
        $A.enqueueAction(action);
        $A.enqueueAction(address1);
    },
    
    EditPhone: function(component, event, helper){
        component.set("v.editable",true);
    },
    Cancel: function(component, event, helper){
        $A.get("e.force:refreshView").fire();
    },
    
    AmendUserDetail: function(component, event, helper){
        var a = component.get('c.PhoneValidation');
        a.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var Status = response.getReturnValue();
                console.log('Status '+Status);
                if(Status == 'Fail'){
                	return;
                }
            }
        });
        $A.enqueueAction(a);
        
		var OfficePhone = component.get("v.userInfo.Phone");
    	var Ext = component.get("v.userInfo.Extension");
        var MobilePhone = component.get("v.userInfo.MobilePhone");
        var CurrentUser = component.get("v.userInfo.Id");
        
        var action = component.get("c.UpdateUser");
        action.setParams({
            "CurrentUser" : CurrentUser,
        	"OfficePhone" : OfficePhone,
        	"Ext" : Ext,
        	"MobilePhone" : MobilePhone
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var csresult = response.getReturnValue();
                
                //    var resultsToast = $A.get("e.force:showToast");
	            //        resultsToast.setParams({
	           //             "title": "Saved",
	           //             "message": "Record Saved."
	           //         });
	            //        resultsToast.fire();
                //$A.get("e.force:refreshView").fire();
                var urlEvent = $A.get("e.force:navigateToURL");
                var siteUrl = component.get("v.configSetting.SiteURL__c");
                //var urlAddress = siteUrl + component.get("v.configSetting.My_Profile__c")+component.get("v.userInfo.Id");	
                // My Profile related change US-0006454
                var urlAddress =  siteUrl + component.get("v.configSetting.My_Profile__c");	
                urlEvent.setParams({
                    "url": urlAddress
                });
                urlEvent.fire();
            }
        });
        
        var phone = component.get('v.userInfo.Phone');
        if(( phone != null && phone != '' && phone != undefined && phone != 'None' )){
            $A.enqueueAction(action);
        }
    },
    PhoneValidation : function(component, event, helper){
    	var phone = component.get('v.userInfo.Phone');
    	if((phone == null || phone == '' || phone == undefined || phone == 'None')){
             console.log('null');
    		 component.set("v.PhoneErrorMessage","Required Field");
           	 return 'Fail';
    	}else{
            console.log('NOT null');
            component.set("v.PhoneErrorMessage","");
    		return 'Success';
    	}
    },
    SubmitCase :function(component, event, helper){
        var action = component.get("c.SubmitNewCase");
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                console.log('state'+state);
                var csresult = response.getReturnValue();
                console.log('csresult'+csresult);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "Case has been submitted."
                });
                resultsToast.fire();
                var sObectEvent = $A.get("e.force:navigateToSObject");
                sObectEvent.setParams({
                    "recordId": csresult.Id
                });
                sObectEvent.fire();
                // $A.get("e.force:refreshView").fire();
            }else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log('Something went wrong, Please check with your admin');
            }
        });
        
        $A.enqueueAction(action);
        
    }

})