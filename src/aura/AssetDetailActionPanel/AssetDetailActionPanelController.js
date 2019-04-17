({
    /*Method checks if the current record is favorite to loggedin User*/
	doInit : function(component, event, helper) {
        
        
        var action = component.get("c.CheckFavourite");
		action.setParams({ 
			RecId : component.get("v.recordId")
		});
		action.setCallback(this,function(response){
            component.set("v.display",response.getReturnValue());
		});
		$A.enqueueAction(action); 
        
        var action1 = component.get("c.fetchRecords");
        action1.setCallback(this,function(response){
            component.set("v.ReturnedRecords",response.getReturnValue());
		});
        $A.enqueueAction(action1); 
        
        var action3 = component.get("c.fetchConfigData");
        action3.setCallback(this,function(response){
            component.set("v.configSetting",response.getReturnValue());
		});
        $A.enqueueAction(action3);
        
        var action2 = component.get("c.fetchAsset");
        action2.setParams({ 
			RecId : component.get("v.recordId")
		});
        action2.setCallback(this,function(response){
            if(response.getReturnValue() != null){
            	var assetObject = response.getReturnValue();
                if(assetObject.Community_Custom_Asset_Name__c != null && assetObject.Community_Custom_Asset_Name__c != ''){
                	//component.set("v.assetName",assetObject.Community_Asset_Display_Name__c);
                	component.set("v.assetName",assetObject.Community_Custom_Asset_Name__c);
                }else{
                    component.set("v.assetName",assetObject.Name);
                }    
            }
            //component.set("v.ReturnedRecords",response.getReturnValue());
		});
        $A.enqueueAction(action2);
        
        /*To get the data from custom meta data*/
     	var action4 = component.get("c.FetchMetadataRecords");
        action4.setCallback(this,function(response){
            component.set("v.returnedMetadataRecords",response.getReturnValue());
		});
        $A.enqueueAction(action4); 
	},
    
    /*Method updates the current record to favorite for loggedin User*/
    UpdateRecordtoFavourite : function(component, event, helper) {
        
    	var action = component.get("c.UpdateFavourite");
		action.setParams({ 
			RecId : component.get("v.recordId")
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
    	var action = component.get("c.RemoveFromFavourites");
		action.setParams({ 
			RecId : component.get("v.recordId")
		});
        action.setCallback(this,function(response){
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
		$A.enqueueAction(action);   
    },
	
    /*Handle Service Report clicks*/
	handleClick : function (cmp, event, helper) {
        console.log('you are here');
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        console.log(id_str);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": id_str
        });
        urlEvent.fire();
    },
	
    /*for Display Model,set the "isOpen" attribute to "true"*/
    openModel: function(component, event, helper) {
		component.set("v.isOpen", true);
	},
	
    /*for Hide/Close Model,set the "isOpen" attribute to "Fasle"*/
	closeModel: function(component, event, helper) {
		component.set("v.isOpen", false);
        component.set("v.submitCaseisOpen", false);
	},
    
	/*Gives a new name to Asset*/
    updateAssetName : function (component, event, helper) {
        //Save Asset Name
        var action = component.get("c.saveAsset");

        action.setParams({ 
			customAssetName : component.get("v.newAssetName"),
            RecId : component.get("v.recordId")
		});

        action.setCallback(this,function(response){
            if(response.getReturnValue() == 'Success'){
                component.set("v.newAssetName","");
                $A.get('e.force:refreshView').fire();
            }else{
				var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error!",
                    "type": "error",
                    "message": $A.get("$Label.c.Community_Asset_Action_Error")
                });
                resultsToast.fire();
                console.log('The error is: ');
                console.log(response.getReturnValue());
            }
		});
        $A.enqueueAction(action);
    },
    //Invokes SubmitNewCase component
    InvokeComponent: function(component, event, helper) {
        //alert('Test - Ignore');
        component.set("v.submitCaseisOpen", true);
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var res = id_str.split("#");
        var assetRecordId = component.get("v.recordId");
        var Value1 = res[1];
        var Value2 = res[2];
        var Value3 = res[3];
        var Subject = res[4];
        // Added var Title to get LinkName to set default priority for Submit an Issue to Sev 2
        // Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        var Title = res[5];
        console.log("assetRecordId",assetRecordId);
        $A.createComponent("c:SubmitNewCase",{
				"aura:id" : "CaseComp",
            	"CaseType" : Value1,
            	"CaseSubType" : Value2,
            	"CasePriority" : Value3,
            	"CaseSubject": Subject,
            	"assetRecordId" : assetRecordId,
            	"CaseTitle" : Title
            }, function(newCmp,status,errorMessage) {
                console.log("newCmp",newCmp);
                if (component.isValid()) {
                    console.log("status",status);
					if(status == "ERROR") {
						console.log('Error Message--',errorMessage);
					}
                    
					component.set("v.comp", newCmp);
				}
            }   
        );
    },
    schedulePM: function(component, event, helper) {
        console.log('INSIDE PM');
        var recId = component.get("v.recordId");
        component.set('v.recorddetailId','?recorddetailid=');
        component.set('v.assetActionPanel','&assetactionpanel=YES');
        
        var SiteURL = component.get("v.configSetting.SiteURL__c");
        var SAListView = component.get("v.configSetting.ServiceAppointment_ListView__c");
        var recorddetailId = component.get("v.recorddetailId");
        var assetActionPanel = component.get("v.assetActionPanel");
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": SiteURL + SAListView + recorddetailId + recId + assetActionPanel
        });
        urlEvent.fire();
    }
})