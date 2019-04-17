({
	PriorityValidation : function(component, event, helper){
    	var priority = component.get('v.CasePriority');
    	
    	if((priority == null || priority == '' || priority == undefined || priority == 'None')){
    		 component.set("v.PriorityErrorMessage","Please select Priority");
    		 return 'Fail';
    	}else{
    		component.set("v.PriorityErrorMessage","");
    		return 'Success';
    	}
    },
    contactValidation: function(component, event, helper) {
        if(component.get('v.CustomerContactInfo') == null || component.get('v.CustomerContactInfo') == '' || component.get('v.CustomerContactInfo') == undefined){
    		component.set("v.showcontactError",true);
            component.set("v.contactRequired",true);
    		return 'Fail';
    	}else{
            component.set("v.showcontactError",false);
            component.set("v.contactRequired",false);
    		return 'Success';
    	}
    },
    q1Validation: function(component, event, helper) {
    	if(component.get("v.q1Value") == null || component.get("v.q1Value") == '' || component.get("v.q1Value") == undefined){
            component.set("v.q1Required",true);
            return 'Fail';
        }else if(component.get("v.q1Value") == 'Yes' && (component.get("v.q1Answer") == null || component.get("v.q1Answer") == '')){
            component.set("v.showQ1Error",true);
            return 'Fail';
        }else if(component.get("v.q1Value") == 'No'){
            component.set("v.showQ1Error",false);
        }else{
        	component.set("v.errorMessage","");
        }
        return 'Success';
   },
    q2Validation: function(component, event, helper) {
    	if(component.get("v.q2Value") == null || component.get("v.q2Value") == '' || component.get("v.q2Value") == undefined){
            component.set("v.q2Required",true);
            return 'Fail';
        }else if(component.get("v.q2Value") == 'Yes' && (component.get("v.q2Answer") == null || component.get("v.q2Answer") == '')){
            component.set("v.showQ2Error",true);
            return 'Fail';
        }else{
        	component.set("v.errorMessage","");
        }
        return 'Success';
    },
    q3Validation: function(component, event, helper) {
        console.log('IN Q3');
    	if(component.get("v.q3Value") == null || component.get("v.q3Value") == '' || component.get("v.q3Value") == undefined){
            component.set("v.q3Required",true);
            
            return 'Fail';
        }
        else{
        	return 'Success';
        }
    },
    q4Validation: function(component, event, helper) {
        console.log('IN Q4');
    	if(component.get("v.q4Value") == null || component.get("v.q4Value") == '' || component.get("v.q4Value") == undefined){
            component.set("v.q4Required",true);
            return 'Fail';
        }else if(component.get("v.q4Value") == 'Yes' && (component.get("v.Address") == null || component.get("v.Address") == '')){
            component.set("v.showQ4Error",true);
            return 'Fail';
        }else{
        	return 'Success';
        }
        
    },
    /*q5Validation: function(component, event, helper) {
        console.log('IN Q5');
    	if(component.get("v.q5Value") == null || component.get("v.q5Value") == '' || component.get("v.q5Value") == undefined){
            component.set("v.q6Required",true);
            return 'Fail';
        }
        else{
        	return 'Success';
        }
    },*/
    q6Validation: function(component, event, helper) {
        console.log('IN Q6');
    	if(component.get("v.q6Value") == null || component.get("v.q6Value") == '' || component.get("v.q6Value") == undefined){
            console.log('IN q6Value>>>'+component.get("v.q6Value"));
            component.set("v.q6Required",true);
            return 'Fail';
        }
        else{
        	return 'Success';
        }
    },
    q7Validation: function(component, event, helper) {
        console.log('IN q3Value>>>'+component.get("v.q7Value"));
        console.log('IN q3Required>>>'+component.get("v.q7Required"));
    	if(component.get("v.q7Value") == null || component.get("v.q7Value") == '' || component.get("v.q7Value") == undefined){
            component.set("v.q7Required",true);
            console.log('1111IN q3Value>>>'+component.get("v.q7Value"));
        	console.log('1111IN q3Required>>>'+component.get("v.q7Required"));
            return 'Fail';
        }else if(component.get("v.q7Value") == 'No' && (component.get("v.q7Answer") == null || component.get("v.q7Answer") == '')){
            console.log('2222IN q3Value>>>'+component.get("v.q7Value"));
        	console.log('2222IN q3Required>>>'+component.get("v.q7Required"));
            component.set("v.showQ7Error",true);
            return 'Fail';
        }else{
        	component.set("v.errorMessage","");
        }
        return 'Success';
    },
    saveCase : function(component, event, helper) {
    	
        var Type = component.get('v.CaseType');
    	var priority = component.get('v.CasePriority');
    	var type = component.get("v.CaseType");
        var subType = component.get("v.CaseSubType");
        var caseOrigin = 'Web';
        var subject = $A.get("$Label.c.Community_Disposable_Case_Subject") +' '+ component.get('v.ProductName');
        var productId = component.get('v.ProductId');
        var customerAccountId = component.get('v.customerAccountId');
        var LotNo = component.get('v.NewSR.Lot_Number__c');
        //var DetailedDescription = component.get('v.DetailedDescription')
        var DetailedDescription = $A.get("$Label.c.Community_Disposable_Text_Q1") +' : ' + component.get('v.DetailedDescription');
        var SerialNumber = 'Serial Number : ' + component.get('v.SerialNumber'); 
        var SalesRep = $A.get("$Label.c.Community_Disposable_Text_Q3") +' : ' + component.get('v.SalesRep'); 
        var Quantity = $A.get("$Label.c.Community_Disposable_Text_Q4") +' : ' + component.get('v.Quantity'); 
        var LotNumber = 'Lot Number : ' + component.get('v.NewSR.Lot_Number__c'); 
        var Specialist = $A.get("$Label.c.Community_Disposable_Text_Q5") +' : ' + component.get('v.Specialist'); 
        var Address = $A.get("$Label.c.Community_Disposable_Text_Q6") +' : '+ component.get('v.Address');  
        var Patients = 'Number of Patients Involved : ' + component.get('v.NumberOfPatient');
        
        
        var concatResult = LotNumber + '\n' + SerialNumber + '\n' + Quantity + '\n' + Patients +  '\n' + SalesRep + '\n' + Specialist + '\n';
        if(component.get('v.q1Value') == 'Yes'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q2") +' : ' + component.get('v.q1Value') + ': \n Provide a detail description of the injury: '+ component.get('v.q1Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q2") +' : ' + component.get('v.q1Value') + ': \n' ;
        }
        if(component.get('v.q2Value') == 'Yes'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q3") +' : ' + component.get('v.q2Value') + ': \n Provide a detail description of the exposure: '+ component.get('v.q2Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q3") +' : ' + component.get('v.q2Value') + ': \n';
        }
        concatResult += $A.get("$Label.c.Community_Case_Comment_Q4") +' : ' + component.get('v.q3Value') + '\n' ;
        if(component.get('v.q4Value') == 'Yes'){
        	concatResult += $A.get("$Label.c.Community_Case_Comment_Q5") +' : ' + component.get('v.q4Value') + '\n' ;
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q6") +' : ' + component.get('v.q5Value') + ': \n '+ $A.get("$Label.c.Community_Disposable_Text_Q6") +': '+ component.get('v.Address') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q5") +' : ' + component.get('v.q4Value') + '\n' ;
        }
        if(component.get('v.q7Value') == 'No'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q8") +' : ' + component.get('v.q7Value') + ': \n Customer Detail: ' + component.get('v.q7Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q8") +' : ' + component.get('v.q7Value') +'\n';
        }
        concatResult += $A.get("$Label.c.Community_Case_Comment_Q7") +' : ' + component.get('v.q6Value') ;
        DetailedDescription = DetailedDescription + '\n' +  concatResult;
        
        var action = component.get("c.createDisposableCase");
        action.setParams({
        	"priority" : priority,
        	"ctype" : type,
        	"subType" : subType,
        	"origin" : caseOrigin,
        	"subject" : subject,
        	"productId" : productId,
        	"customerAccountId" : customerAccountId,
        	"LotNo" :LotNo,
            "description" :DetailedDescription
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                
            	var csresult = response.getReturnValue();
                if(csresult.caseStatus == 'Success'){
                		
                    	var caseID = csresult.caseId ;
				   		helper.createCaseComment(component, event, helper, caseID);
                    
	            }else{
                	component.set("v.errorMessage",csresult.caseStatus);
                	component.set("v.disableCreateFinish",false);
                	return;
                }
            }else if (state === "INCOMPLETE") {
                component.set("v.disableCreateFinish",false);
                var error = $A.get("$Label.c.Service_Try_Again_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                component.set("v.disableCreateFinish",false);
                console.log("User is offline, device doesn't support drafts.");
            } 
            else if (state === "ERROR") {
                component.set("v.disableCreateFinish",false);
                var error = $A.get("$Label.c.Service_Unknown_Error");
                component.set("v.errorMessage",error);
                component.set("v.showError",true);
                component.set("v.disableCreateFinish",false);
                console.log('Problem saving case, error: ' + JSON.stringify(saveResult.error));
             }
             else {
                 component.set("v.disableCreateFinish",false);
                 var error = $A.get("$Label.c.Service_Unknown_Error");
                 component.set("v.errorMessage",error);
                 component.set("v.showError",true);
                 component.set("v.disableCreateFinish",false);
                 console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
             }
        });
        $A.enqueueAction(action);  
    },
    
    createCaseComment : function(component, event, helper, caseID) {
    	
        var DetailedDescription = $A.get("$Label.c.Community_Disposable_Text_Q1") +' : ' + component.get('v.DetailedDescription');
        var SerialNumber = 'Serial Number : ' + component.get('v.SerialNumber'); 
        var SalesRep = $A.get("$Label.c.Community_Disposable_Text_Q3") +' : ' + component.get('v.SalesRep'); 
        var Quantity = $A.get("$Label.c.Community_Disposable_Text_Q4") +' : ' + component.get('v.Quantity'); 
        var LotNumber = 'Lot Number : ' + component.get('v.NewSR.Lot_Number__c'); 
        var Specialist = $A.get("$Label.c.Community_Disposable_Text_Q5") +' : ' + component.get('v.Specialist'); 
        var Address = $A.get("$Label.c.Community_Disposable_Text_Q6") +' : '+ component.get('v.Address');  
        var Patients = 'Number of Patients Involved : ' + component.get('v.NumberOfPatient');
        
        var concatResult = LotNumber + '\n' + SerialNumber + '\n' + Quantity + '\n' + Patients +  '\n' + SalesRep + '\n' + Specialist + '\n';
        if(component.get('v.q1Value') == 'Yes'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q2") +' : ' + component.get('v.q1Value') + ': \n Provide a detail description of the injury: '+ component.get('v.q1Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q2") +' : ' + component.get('v.q1Value') + ': \n' ;
        }
        if(component.get('v.q2Value') == 'Yes'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q3") +' : ' + component.get('v.q2Value') + ': \n Provide a detail description of the exposure: '+ component.get('v.q2Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q3") +' : ' + component.get('v.q2Value') + ': \n';
        }
        concatResult += $A.get("$Label.c.Community_Case_Comment_Q4") +' : ' + component.get('v.q3Value') + '\n' ;
        if(component.get('v.q4Value') == 'Yes'){
        	concatResult += $A.get("$Label.c.Community_Case_Comment_Q5") +' : ' + component.get('v.q4Value') + '\n' ;
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q6") +' : ' + component.get('v.q5Value') + ': \n '+ $A.get("$Label.c.Community_Disposable_Text_Q6") +': '+ component.get('v.Address') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q5") +' : ' + component.get('v.q4Value') + '\n' ;
        }
        if(component.get('v.q7Value') == 'No'){
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q8") +' : ' + component.get('v.q7Value') + ': \n Customer Detail: ' + component.get('v.q7Answer') + '\n';
        }else{
            concatResult += $A.get("$Label.c.Community_Case_Comment_Q8") +' : ' + component.get('v.q7Value') +'\n';
        }
        concatResult += $A.get("$Label.c.Community_Case_Comment_Q7") +' : ' + component.get('v.q6Value') ;
        DetailedDescription = DetailedDescription + '\n' +  concatResult;    
       
		var action = component.get("c.insertDisposableCaseComments");
        action.setParams({
        	"ComplianceString" : DetailedDescription,
        	"CaseId" : caseID
        });
		action.setCallback(this, function(response){
             
	            var state = response.getState();
	            if (state === "SUCCESS"){
                    //var csresult = response.getReturnValue();
	            	var resultsToast = $A.get("e.force:showToast");
	                    resultsToast.setParams({
	                        "title": "Saved",
	                        "message": "The record is saved."
	                    });
	                    resultsToast.fire();
                    var compEvent = component.getEvent("closeModalEvent");
				        //compEvent.setParams({"recordByEvent" : getSelectRecord });  
				        compEvent.fire();

	                	var sObectEvent = $A.get("e.force:navigateToSObject");
	                	sObectEvent.setParams({
	                		"recordId": caseID
	                	});
	                	sObectEvent.fire();
                    
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
})