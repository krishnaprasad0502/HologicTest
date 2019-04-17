({
	/*Initialization - Sets default values*/
    doInit: function(component, event, helper) {
        
        
        var actionCurrUser = component.get("c.fetchUser");
        actionCurrUser.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
            	component.set("v.currentUser", response.getReturnValue());
                
            }
        });
        $A.enqueueAction(actionCurrUser);
        var Type = component.get('v.CaseType');
        var subType = component.get('v.CaseSubType');
        var CasePriority = component.get('v.CasePriority');
        var CaseTitle = component.get('v.CaseTitle');
        console.log('CaseTitle'+CaseTitle);
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        if((Type == 'Web' && (CaseTitle == 'Submit an Issue for Disposable Product') && component.get("v.assetDetail") == false)){
        	component.set("v.showScreen2Back",true);
        }
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        //if((Type == 'Web' && (CaseTitle =='Submit an Issue for Disposable Product'))){
        	component.set("v.showProductDesc",true);
        //}
        component.set("v.NewSR.Status",'Open');
        component.set("v.NewSR.Type",Type);
        component.set("v.NewSR.Subject",component.get("v.CaseSubject"));
        component.set("v.NewSR.Description",'');
        
        if(Type == 'Web' && (subType == 'None' || subType == undefined || subType == null || subType == '')){//Submit an issue and compliance
        	console.log('Submit an Issue');
        	component.set("v.Screen1",true);
        	component.set("v.Screen2",false);
        	component.set("v.Screen3",false);
            component.set("v.showProduct",true);
            component.set("v.NewSR.Subject","");
        }
    },
    Screen1Next : function(component, event, helper) {
    	
        var productId = component.get('v.ProductId');        
        var quantity = component.get('v.Quantity');
        var patient = component.get('v.NumberOfPatient');
        var description = component.get('v.DetailedDescription');
        var SerialNumber = component.get('v.SerialNumber');
        var LotNumber = component.get('v.NewSR.Lot_Number__c');
        console.log('SerialNumber'+SerialNumber);
        console.log('LotNumber'+LotNumber);
        if((SerialNumber == null || SerialNumber == '' || SerialNumber == undefined) && (LotNumber == null || LotNumber == '' || LotNumber == undefined)){
            component.set("v.showS1NumberError",true);
            return;
        }else {
            component.set("v.showS1NumberError",false);
        }
 
        if(productId == null || productId == '' || productId == undefined){
    		if(component.get('v.CaseType') == 'Web'){
    			component.set("v.errorMessage","Please Select Product");
    		}
    		return;
    	}else if(quantity == null || quantity == '' || quantity == undefined){
            component.set("v.showS1Error",true);
            return;
    	}else if(patient == null || patient == '' || patient == undefined){
            component.set("v.showS2Error",true);
    		return;
    	}else if(description == null || description == '' || description == undefined){
            component.set("v.showS3Error",true);
    		return;
        }else{
            component.set("v.errorMessage","");
        }
        component.set("v.Screen1",false);
        component.set("v.Screen2",true);
        component.set("v.Screen3",false);
        component.set("v.showProductName",true);
    },
    Screen2Back : function(component, event, helper) {
    	component.set("v.Screen1",true);
        component.set("v.Screen2",false);
    	component.set("v.Screen3",false);
        
    	component.set("v.showS1Error",false);
        component.set("v.showS2Error",false);
        component.set("v.showS3Error",false);
        component.set("v.showS1NumberError",false);
    },
    Screen2Next : function(component, event, helper) {
    	var Type = component.get('v.CaseType');  
        component.set("v.Screen1",false);
        component.set("v.Screen2",false);
        component.set("v.Screen3",true);
    },
    Screen3Save : function(component, event, helper) {
        var status1 = helper.q1Validation(component, event, helper);
        if(status1 == 'Fail'){
            	return;
	    	}
        var status2 = helper.q2Validation(component, event, helper);
        if(status2 == 'Fail'){
            	return;
	    	}
        var status3 = helper.q3Validation(component, event, helper);
        if(status3 == 'Fail'){
            	return;
	    	}
        var status4 = helper.q4Validation(component, event, helper);
        if(status4 == 'Fail'){
            	return;
	    	}
        /*var status5 =helper.q5Validation(component, event, helper);
        if(status5 == 'Fail'){
            	return;
	    	}*/
        
        var status7 = helper.q7Validation(component, event, helper);
        if(status7 == 'Fail'){
            	return;
	    	}
        var status6 = helper.q6Validation(component, event, helper);
        if(status6 == 'Fail'){
            	return;
	    	}
        component.set("v.disableCreateFinish",true);
        helper.saveCase(component, event, helper);
    },
    handleQ1Change : function(component, event, helper) {
        component.set("v.q1Required",false);
		component.set("v.displayQ1TextBox",false);
        component.set("v.showQ1Error",false);
        console.log('event.getParam("value")'+event.getParam("value"));
        var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ1TextBox",true);
        }else{
        	component.set("v.q1Required",false);
            component.set("v.q1Answer",'');
			component.set("v.displayQ1TextBox",false);
        }
    },
    
    handleQ2Change : function(component, event, helper) {
    	component.set("v.q2Required",false);
        component.set("v.displayQ2TextBox",false)
        component.set("v.showQ2Error",false);
        var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ2TextBox",true);
        }else{
            component.set("v.q2Required",false);
            component.set("v.q2Answer",'');
			component.set("v.displayQ2TextBox",false);
        }
    },
    handleQ3Change : function(component, event, helper) {
    	component.set("v.q3Required",false);
        var changeValue = event.getParam("value");
        if(changeValue == 'Yes' || changeValue == 'No'){
           component.set("v.q3Required",false);
        }
    },
    handleQ4Change : function(component, event, helper) {
    	component.set("v.q4Required",false);
        component.set("v.displayQ4TextBox",false)
        component.set("v.showQ4Error",false);
        var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ4TextBox",true);
        }else{
            component.set("v.q5Value",'');
            component.set("v.q4Answer",'');
			component.set("v.displayQ4TextBox",false);
        }
    },
    handleQ6Change : function(component, event, helper) {
    	component.set("v.q6Required",false);
        var changeValue = event.getParam("value");
        if(changeValue == undefined || changeValue == '' || changeValue == null  ){
           component.set("v.q6Required",true);
        }else{
            component.set("v.q6Required",false);
        }
    },
    handleQ7Change : function(component, event, helper) {
    	component.set("v.q7Required",false);
        component.set("v.displayQ7TextBox",false)
        component.set("v.showQ7Error",false);
        var changeValue = event.getParam("value");
        if(changeValue == 'No'){
           component.set("v.displayQ7TextBox",true);
        }else{
            component.set("v.q7Required",false);
            component.set("v.q7Answer",'');
			component.set("v.displayQ7TextBox",false);
        }
    },
    onCheck: function(component, event, helper) {
       		var checkCmp = component.get("v.CheckboxVal");
        	var Address = component.get("v.Address") ;
        if(checkCmp == true){
            component.set("v.q7Answer",Address);
        }
        else{
            component.set("v.q7Answer",'');              
        }
        
    },
    callChildCompMethod : function(component, event, helper) {
    	var childCmp = component.find('childCmp');
    	childCmp.sampleMethod(component.get('v.NewSR.Subject')); 
    }
})