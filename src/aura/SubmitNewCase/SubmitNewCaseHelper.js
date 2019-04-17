({
	fetchPickListVal: function(component, fieldName, elementId) {
		console.log('############################### Fetch Picklist Values ###############################');
        var action = component.get("c.getSelectOptions");
        action.setParams({
            "objObject": component.get("v.NewSR"),
            "fld": fieldName
        });
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
                for (var i = 0; i < allValues.length; i++) {
                    opts.push({
                        class: "optionClass",
                        label: allValues[i],
                        value: allValues[i]
                    });
                }
                //component.find(elementId).set("v.options", opts);
                component.set("v.options",opts);
            }
        });
        $A.enqueueAction(action);
    },
    
    // This method is created to return Service Appointment records based on the asset id.
    // PM Schedule data while case creation  US-0006345 START
    getServiceAppointment : function(component, event, helper, assetId) {
        
        var action = component.get("c.fetchServiceAppointment");
        action.setParams({
            "strObjectName" : component.get("v.SAsObjectName"),
            "strFieldSetName" : component.get("v.SAFieldSetName"),
            "AssetId" : assetId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                component.set("v.SAList", response.getReturnValue()); 
                console.log('component.get(v.SAList)>>>>>',component.get('v.SAList'));
                if(component.get('v.SAList') == null || component.get('v.SAList') == '' || component.get('v.SAList') == undefined){
                    component.set("v.showSAEmptyMessage", true); 
                }
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
    },
    
    // This method is created to return Current Date, Past Date and Future Date.
    // PM Schedule data while case creation  US-0006345 START
    getTimeframe : function(component, event, helper) {
        var action = component.get("c.fetchTimeframe");
      	action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var csresult = response.getReturnValue();
                component.set("v.CurrentDate", csresult.CurrentDate); 
                component.set("v.PastDate", csresult.PastDate); 
                component.set("v.FutureDate", csresult.FutureDate); 
                
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
        
    },
    // PM Schedule data while case creation  US-0006345 END
    
    PriorityValidation : function(component, event, helper){
    	console.log('############################### Priority Validation ###############################');
    	var priority = component.get('v.CasePriority');
    	console.log('The Priority is#$#: '+component.get('v.CasePriority'));
    	
    	if((priority == null || priority == '' || priority == undefined || priority == 'None')){
    		 //component.set("v.errorMessage","Please select Priority");
    		 component.set("v.PriorityErrorMessage","Please select Priority");
    		 return 'Fail';
    	}else{
    		//component.set("v.errorMessage","");
    		component.set("v.PriorityErrorMessage","");
    		return 'Success';
    	}
    },
    q1Validation: function(component, event, helper) {
    	console.log('############################### Q1 Validation ###############################');
    	if(component.get('v.q1Value') == null || component.get('v.q1Value') == '' || component.get('v.q1Value') == undefined){
    		component.set("v.showQ1Error",true);
    		return 'Fail';
    	}else{
    		return 'Success';
    	}
    },
    q2Validation: function(component, event, helper) {
    	console.log('############################### Q2 Validation ###############################');
    	if(component.get("v.q2Value") == null || component.get("v.q2Value") == '' || component.get("v.q2Value") == undefined){
            component.set("v.q2Required",true);
            return 'Fail';
        //&& (component.get("v.q2Answer") == null || component.get("v.q2Answer") == '')
        }else if(component.get("v.q2Value") == 'Yes' && (component.get("v.q2Answer") == null || component.get("v.q2Answer") == '')){
            component.set("v.showQ2Error",true);
            return 'Fail';
        }else{
        	component.set("v.errorMessage","");
        }
        return 'Success';
    },
    q3Validation : function(component, event, helper) {
    	console.log('############################### Q3 Validation ###############################');
    	if(component.get("v.q3Value") == null || component.get("v.q3Value") == '' || component.get("v.q3Value") == undefined){
            component.set("v.q3Required",true);
            return 'Fail';
        }else if(component.get("v.q3Value") == 'Yes' && (component.get("v.q3Answer") == null || component.get("v.q3Answer") == '')){
            component.set("v.showQ3Error",true);
            return 'Fail';
        }else{
        	component.set("v.errorMessage","");
        }
        return 'Success';
    },
    fetchAssetValues : function(component, event, helper) {
    	console.log('############################### Helper : fetchAssetValues ###############################');
    	console.log('The Asset Id is: ');
    	console.log(component.get('v.assetRecordId'));
    	var action = component.get("c.fetchAssetRecord");
        action.setParams({
            "AssetId": component.get('v.assetRecordId')
        });
        action.setCallback(this, function(response) {
            console.log('HELPER : Fetch Asset Values   The response state is: '+response.getState());
            if (response.getState() == "SUCCESS") {
            	var ast = response.getReturnValue();
            	
            	if(ast.Id != null && ast.Id != '' && ast.Id != undefined){
            		var cAccount = ast.Customer_Account__r;
            		component.set("v.customerAccountName",cAccount.Name);//customerAccountName
            	}
            	
            	console.log('HELPER : Fetch Asset Values   The response contains: ');
            	console.log(ast);
            	component.set("v.customerAccount",ast.Customer_Account__r);
            	
                component.set("v.AssetName",ast.SerialNumber);
                console.log('HELPER : Fetch Asset Values   Asset Name: '+component.get("v.AssetName"));
                
		    	component.set("v.AssetId",ast.Id);
		    	console.log('HELPER : Fetch Asset Values   Asset Id: '+component.get("v.AssetId"));

		    	//component.set("v.customerAccountName",ast.Customer_Account__r.Name);//customerAccountName
		    	//console.log('Customer Account Name: '+component.get("v.customerAccountName"));
		    	
		    	component.set("v.customerAccountId",ast.Customer_Account__c);//customerAccountId
		    	console.log('HELPER : Fetch Asset Values   Customer Account Id'+component.get("v.customerAccountId"));
		    	
		    	component.set("v.SerialNumber",ast.SerialNumber);//SerialNumber
		    	console.log('HELPER : Fetch Asset Values   Serial Number'+component.get("v.SerialNumber"));
		    	
		    	component.set("v.CommunityProductDesc",ast.Community_Product_Description__c);//CommunityProductDesc
		    	console.log('HELPER : Fetch Asset Values   Community Prod desc'+component.get("v.CommunityProductDesc"));
		    	
		    	component.set("v.InstallLocationLabel",ast.Install_Location_Label__c);//InstallLocationLabel
		    	console.log('HELPER : Fetch Asset Values   Install Location Label'+component.get("v.InstallLocationLabel"));
		    	
		    	component.set("v.AssetAccountId",ast.AccountId);
		    	console.log('HELPER : Fetch Asset Values   Account Id'+component.get("v.AssetAccountId"));

	            if(ast.SerialNumber != null && ast.SerialNumber != '' && ast.SerialNumber != undefined){
		    		component.set("v.showSSN",true);
		    		component.set("v.showSL",true);
		    		component.set("v.showProductName",false);
		    	}else{
		    		component.set("v.showSSN",false);
		    		component.set("v.showSL",false);
		    		component.set("v.showProductName",true);
		    	}
            }
        });
        $A.enqueueAction(action);
    },
    saveCase : function(component, event, helper, buttontype) {
    	component.set("v.disableCreateFinish",true);
    	console.log('############################### Screen 3 Save ###############################');
    	var priorityStatus = helper.PriorityValidation(component, event, helper);
    	if(priorityStatus == 'Fail'){
    		component.set("v.disableCreateFinish",false);
    		return;
    	}
    	
    	var Type = component.get('v.CaseType');
    	var assetInputId = component.get('v.assetRecordId');
    	if(assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None' && Type == 'Web'){
        	var status = helper.q1Validation(component, event, helper);
	    	if(status == 'Fail'){
	    		component.set("v.disableCreateFinish",false);
	    		return;
	    	}
        }

        var priority = component.get('v.CasePriority');
    	var type = component.get("v.CaseType");
        var subType = component.get("v.CaseSubType");
        var caseOrigin = 'Web';
        var subject = component.get('v.NewSR.Subject');
        var assetId = component.get('v.AssetId');
        var AssetAccountId = component.get("v.AssetAccountId");
        var productId = component.get('v.ProductId');
        var customerAccountId = component.get('v.customerAccountId');
        var casePhone = component.get('v.NewSR.Case_Phone_Number__c');
        var Description = component.get('v.NewSR.Description');
        
        console.log('***** ON SAVE *****');
        console.log('priority : '+priority);
        console.log('type : '+type);
        console.log('subType : '+subType);
        console.log('caseOrigin : '+caseOrigin);
        console.log('subject : '+subject);
        console.log('assetId : '+assetId);
        console.log('AssetAccountId : '+AssetAccountId);
        console.log('productId : '+productId);
        console.log('customerAccountId : '+customerAccountId);
        console.log('casePhone : '+casePhone);
        console.log('Description : '+Description);
        console.log('***** ON SAVE *****');
        var action = component.get("c.createCase");
        action.setParams({
        	"priority" : priority,
        	"ctype" : type,
        	"subType" : subType,
        	"origin" : caseOrigin,
        	"subject" : subject,
        	"description" : Description,
        	"productId" : productId,
        	"assetId" : assetId,
        	"AssetAccountId" : AssetAccountId,
        	"customerAccountId" : customerAccountId,
        	"casePhoneNumber" : casePhone
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
            	var csresult = response.getReturnValue();
                if(csresult.caseStatus == 'Success'){
                	if(buttontype == 'Next'){
	                	var resultsToast = $A.get("e.force:showToast");
	                    resultsToast.setParams({
	                        "title": "Saved",
	                        "message": "The record is saved."
	                    });
	                    resultsToast.fire();
	                	component.set("v.CaseId",csresult.caseId);
	                	component.set("v.Screen1",false);
				    	component.set("v.Screen2",false);
				    	component.set("v.Screen3",true);
				    }else{
				    	//alert('You are here: Save CAse');
				    	var compEvent = component.getEvent("closeModalEvent");
				        //compEvent.setParams({"recordByEvent" : getSelectRecord });  
				        compEvent.fire();
				    	var sObectEvent = $A.get("e.force:navigateToSObject");
	                	sObectEvent.setParams({
	                		"recordId": csresult.caseId
	                	});
	                	sObectEvent.fire();
				    }
                }else{
                	component.set("v.errorMessage",csresult.caseStatus);
                	component.set("v.disableCreateFinish",false);
                	return;
                }
                console.log('The case ID is: '+CaseId);
            }else if (state === "INCOMPLETE") {
                var error = $A.get("$Label.c.Service_Try_Again_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                component.set("v.disableCreateFinish",false);
                console.log("User is offline, device doesn't support drafts.");
            } 
            else if (state === "ERROR") {
                var error = $A.get("$Label.c.Service_Unknown_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                component.set("v.disableCreateFinish",false);
                console.log('Problem saving case, error: ' + JSON.stringify(saveResult.error));
             }
             else {
                 var error = $A.get("$Label.c.Service_Unknown_Error");
                 component.set("v.errorMessage",error);
                 component.set("v.showError",true);
                 component.set("v.disableCreateFinish",false);
                 console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
             }
        });
        $A.enqueueAction(action);  
    },
    
    createServiceRequestComments : function(component, event, helper) {
    	component.set("v.disableFinish",true);
    	var type = component.get("v.CaseType");
    	if(component.get("v.showComplianceQ1Section") == true && component.get("v.q1Value") == 'Yes'){
	    	var q2status = helper.q2Validation(component, event, helper);
	    	if(q2status == 'Fail'){
	    		component.set("v.disableFinish",false);
	    		return;
	    	}
    	
	    	var q3status = helper.q3Validation(component, event, helper);
	    	if(q3status == 'Fail'){
	    		component.set("v.disableFinish",false);
	    		return;
	    	}
	    	var ComplianceString1 = '';
	        var ComplianceString2 = '';
	        var ComplianceString3 = '';
	        
	        ComplianceString1 += $A.get("$Label.c.Community_Case_Comment_Q1") + ' : ';
	        if(component.get("v.q1Value") != null && component.get("v.q1Value") != undefined){
	            ComplianceString1 += component.get("v.q1Value");
	        }
        
	        ComplianceString2 += $A.get("$Label.c.Community_Case_Comment_Q2") + ' : ';
	        if(component.get("v.q2Value") != null && component.get("v.q2Value") != undefined){
	            component.set("v.q2Required",false);
	            ComplianceString2 += component.get("v.q2Value") + ' : ';
	            if(component.get("v.q2Answer") != null && component.get("v.q2Answer") != ''){
					ComplianceString2 += component.get("v.q2Answer");    
	                component.set("v.showQ2Error",false);
	            }
	        }
        
	        ComplianceString3 += $A.get("$Label.c.Community_Case_Comment_Q3") + ' : ';
	        if(component.get("v.q3Value") != null && component.get("v.q3Value") != undefined){
	            component.set("v.q3Required",false);
	            ComplianceString3 += component.get("v.q3Value") + ' : ';
	            if(component.get("v.q3Answer") != null && component.get("v.q3Answer") != ''){
					ComplianceString3 += component.get("v.q3Answer");   
	                component.set("v.showQ3Error",false);
	            }
	        }
	        
	        var action = component.get("c.insertServiceRequestComments");
	        action.setParams({
	        	"isCreateComments" : component.get("v.showComplianceQ1Section"),
        		"qa1" : ComplianceString1,
                "qa2" : ComplianceString2,
             	"qa3" : ComplianceString3,
             	"caseId" : component.get("v.CaseId"),
             	"ctype" : type
            });
            action.setCallback(this, function(response){
	            var state = response.getState();
	            if (state === "SUCCESS"){
	            	var csresult = response.getReturnValue();
	                if(csresult.caseStatus == 'Success'){
	                	//alert('You are here: Save CAse');
				    	var compEvent = component.getEvent("closeModalEvent");
				        //compEvent.setParams({"recordByEvent" : getSelectRecord });  
				        compEvent.fire();

	                	console.log('Youi are at: 292'+component.get("v.CaseId"));
	                	var sObectEvent = $A.get("e.force:navigateToSObject");
	                	sObectEvent.setParams({
	                		"recordId": component.get("v.CaseId")
	                	});
	                	sObectEvent.fire();
	                }else{
	                	component.set("v.errorMessage",csresult.caseStatus);
	                	component.set("v.disableFinish",false);
	                	console.log('Youi are at: 301'+component.get("v.errorMessage"));
	                	return;
	                }
	            }else if (state === "INCOMPLETE") {
	                var error = $A.get("$Label.c.Service_Try_Again_Error");
	                component.set("v.errorMessage",error);
	                component.set("v.showError",true);
	                component.set("v.disableFinish",false);
	                console.log("User is offline, device doesn't support drafts.");
	            } 
	            else if (state === "ERROR") {
	                var error = $A.get("$Label.c.Service_Unknown_Error");
	                component.set("v.errorMessage",error);
	                component.set("v.showError",true);
	                component.set("v.disableFinish",false);
	                console.log('Problem saving case, error: ' + JSON.stringify(saveResult.error));
	             }
	             else {
	                 var error = $A.get("$Label.c.Service_Unknown_Error");
	                 component.set("v.errorMessage",error);
	                 component.set("v.showError",true);
	                 component.set("v.disableFinish",false);
	                 console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
	             }
	        });
	        $A.enqueueAction(action);
	    }
    	console.log("QA1: "+ComplianceString1);
	    console.log("QA2: "+ComplianceString2);
	    console.log("QA3: "+ComplianceString3);
    }	
})