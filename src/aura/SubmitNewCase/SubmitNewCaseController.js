({
    /*Initialization - Sets default values*/
    doInit: function(component, event, helper) {
        console.log('############################### DO INIT ###############################');
        var actionCurrUser = component.get("c.fetchUser");
        actionCurrUser.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
            	component.set("v.currentUser", response.getReturnValue());
                
            }
        });
        $A.enqueueAction(actionCurrUser);
        console.log('current user',component.get('v.currentUser'));
        var Type = component.get('v.CaseType');
        var subType = component.get('v.CaseSubType');
        var CasePriority = component.get('v.CasePriority');
        var assetInputId = component.get('v.assetRecordId');
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        var CaseTitle = component.get('v.CaseTitle');
        
        component.set("v.dynamicPriority",component.get('v.CasePriority'));
        
        console.log('Type is: '+Type);
        console.log('subType is: '+subType);
        console.log('CasePriority is: '+CasePriority);
        console.log('Asset Input Id is: '+assetInputId);
        
        if(assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None' && (Type == 'Web' || subType == 'PM')){
        	helper.fetchAssetValues(component, event, helper);
        	if(Type == 'Web'){
        		component.set("v.assetDetail",true);
        	}	
        }
        
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        if((Type == 'Web' && (CaseTitle == 'Submit an Issue') && component.get("v.assetDetail") == false) || (Type == 'Scheduled Event' && subType == 'PM') ){
        	component.set("v.showScreen2Back",true);
            component.set("v.showSAScreenBack",true);
        }
        
        if(assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None' && subType == 'PM'){
        	component.set("v.showScreen2Back",true);
            component.set("v.showSAScreenBack",false);
        }
        
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        if((Type == 'Web' && (CaseTitle =='Submit an Issue')) || subType == 'PM'){
        	component.set("v.showProductDesc",true);
        }
        
        var asdetail = component.get("v.assetDetail",true);
        component.set("v.NewSR.Status",'Open');
        component.set("v.NewSR.Type",Type);
        component.set("v.NewSR.Subject",component.get("v.CaseSubject"));
        component.set("v.NewSR.Description",'');
        //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
        if(Type == 'Web' && (CaseTitle != 'Submit an Issue') && (subType == 'None' || subType == undefined || subType == null || subType == '')){//General Enquiry
        	console.log('General Enquiry');
        	component.set("v.Screen1",false);
        	component.set("v.Screen2",true);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",false);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",false);
        	if(CasePriority == 'Sev 2'){
        		component.set("v.NewSR.Subject","");
        	}	
        }else if(Type == 'Web' && assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None' && (subType == 'None' || subType == undefined || subType == null || subType == '')){//Submit Case from Asset Detail
        	console.log('Submit Case - Asset Detail Invocation');
        	component.set("v.Screen1",false);
        	component.set("v.Screen2",true);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",false);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",true);
        	component.set("v.NewSR.Subject","");
        }else if(Type == 'Scheduled Event' && subType == 'PM' && assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None'){//Schedule Preventive Maintenance from Asset Detail
        	console.log('Schedule PM from Asset Detail');
        	// PM Schedule data while case creation  US-0006345
            component.set("v.Screen1",false);
        	component.set("v.Screen2",false);
        	component.set("v.Screen3",false);
            component.set("v.SAScreen",true);
        	component.set("v.showAsset",false);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",false);
              
        	// This method is created to return Service Appointment records based on the asset id.
            // PM Schedule data while case creation  US-0006345 
            var assetId = assetInputId;
            helper.getServiceAppointment(component,event, helper, assetId);
            helper.getTimeframe(component,event, helper);
            
        }else if(Type == 'Web' && (subType == 'None' || subType == undefined || subType == null || subType == '')){//Submit an issue and compliance
        	console.log('Submit an Issye - show compliance');
        	component.set("v.Screen1",true);
        	component.set("v.Screen2",false);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",true);
        	component.set("v.showProduct",true);
        	component.set("v.showComplianceQ1Section",true);
        	component.set("v.NewSR.Subject","");
        }else if(Type == 'Scheduled Event' && subType == 'PM'){//Schedule Preventive maintenance
        	console.log('Schedule PM');
        	component.set("v.Screen1",true);
        	component.set("v.Screen2",false);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",true);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",false);
        }else if(Type == 'Scheduled Event' && subType == 'Clinical Training'){//
        	console.log('Request Training Services');
        	component.set("v.Screen1",false);
        	component.set("v.Screen2",true);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",false);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",false);
        }else if(Type == 'Scheduled Event' && subType == 'Service'){
        	console.log('Request for Clinical Professional Services && Request Connectivity Professional Services');
        	component.set("v.Screen1",false);
        	component.set("v.Screen2",true);
        	component.set("v.Screen3",false);
        	component.set("v.showAsset",false);
        	component.set("v.showProduct",false);
        	component.set("v.showComplianceQ1Section",false);
        }
        
        helper.fetchPickListVal(component, 'Priority', 'Priority');
        if(component.get("v.NewSR.Type") == "Complaint" || component.get("v.NewSR.Type") == "Web"){
        	console.log('The priority is: '+component.get("v.dynamicPriority"));
            if(component.get("v.dynamicPriority") == 'Sev 2'){
            	component.set("v.CasePriority","Sev 2");
            }else if(component.get("v.dynamicPriority") == 'Sev 3'){
            	component.set("v.CasePriority","Sev 3");
            }else{
            	component.set("v.CasePriority","None");
            }	
        }
		
        var action = component.get("c.fetchUserContact");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var ContactInfo = response.getReturnValue();
                component.set("v.userContactInfo", response.getReturnValue());
                //Default the Priority for Submit an Issue to 'Sev 2' US-0006454
                if(Type != 'Web' || (Type == 'Web' && CaseTitle != 'Submit an Issue' )){
                	component.set("v.customerAccountName",ContactInfo.Account.Parent.Name);
                }
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
        console.log('CasePriority is: '+CasePriority);
        console.log('currentuser',component.get('v.currentUser'));
    },
    onAssetChange : function(component, event, helper) {
    	console.log('############################### On Asset Change ###############################');
    	component.set("v.disableProduct",true);
    	var assetId = component.get('v.AssetId');
        var productId = component.get('v.ProductId');
        component.set("v.customerAccountId",component.get("v.customerAccount").Id);
        component.set("v.customerAccountName",component.get("v.customerAccount").Name);
    	if((assetId == null || assetId == '' || assetId == undefined) && (productId == null || productId == '' || productId == undefined)){
    		component.set("v.disableProduct",false);
    		component.set("v.disableAsset",false);
    	}
    },
    onProductChange : function(component, event, helper) {
    	console.log('############################### On Product Change ###############################');
    	component.set("v.disableAsset",true);
    	var assetId = component.get('v.AssetId');
        var productId = component.get('v.ProductId');
        console.log('The customer Account is: '+component.get("v.customerAccountName"));
    	if((assetId == null || assetId == '' || assetId == undefined) && (productId == null || productId == '' || productId == undefined)){
    		component.set("v.disableProduct",false);
    		component.set("v.disableAsset",false);
    	}
    },
    Screen1Next : function(component, event, helper) {
    	console.log('############################### Screen 1 Next ###############################');
        var assetId = component.get('v.AssetId');
        var productId = component.get('v.ProductId');
        
        console.log('The Customer Account is: '+component.get("v.customerAccountName"));
        console.log('The Asset is: '+assetId);
        if(assetId == null || assetId == '' || assetId == undefined){
        	component.set("v.customerAccountName",component.get("v.userContactInfo").Account.Parent.Name);
        }
    	
    	if((assetId == null || assetId == '' || assetId == undefined) && (productId == null || productId == '' || productId == undefined)){
    		if(component.get('v.CaseType') == 'Web'){
    			component.set("v.errorMessage",$A.get("$Label.c.Service_System_Product_Blank_Error"));
    		}else{
    			component.set("v.errorMessage",$A.get("$Label.c.Service_Asset_Blank_Error"));
    		}	
    		return;
    	}else{
    		component.set("v.errorMessage","");
    	}
    	
    	if(component.get("v.CaseSubType") == 'None' || component.get("v.CaseSubType") == undefined || component.get("v.CaseSubType") == null || component.get("v.CaseSubType") == ''){
	    	var status = helper.q1Validation(component, event, helper);
	    	if(status == 'Fail'){
	    		return;
	    	}
	    }
        
        // PM Schedule data while case creation  US-0006345 START
        // This method is created to return Service Appointment records based on the asset id.
        helper.getServiceAppointment(component,event, helper, assetId);
       	helper.getTimeframe(component,event, helper);
        
	    component.set("v.Screen1",false);
        if(component.get("v.CaseSubType") == 'PM'){
            component.set("v.SAScreen",true);
        }else{
            component.set("v.Screen2",true);
        }
        // PM Schedule data while case creation  US-0006345 END
    	component.set("v.Screen3",false);
    	if(component.get("v.AssetId") != null && component.get("v.AssetId") != '' && component.get("v.AssetId") != undefined){
    		component.set("v.showSSN",true);
    		component.set("v.showSL",true);
    		component.set("v.showProductName",false);
    	}else{
    		component.set("v.showSSN",false);
    		component.set("v.showSL",false);
    		component.set("v.showProductName",true);
    	}
    	console.log('End of Method: '+component.get("v.AssetId"));
    },
    Screen2Back : function(component, event, helper) {
    	console.log('############################### Screen 2 Back ###############################');
    	// PM Schedule data while case creation  US-0006345 START
        if(component.get("v.CaseSubType") == 'PM'){
            component.set("v.SAScreen",true);
        }else{
            component.set("v.Screen1",true);
        }
        // PM Schedule data while case creation  US-0006345 END
        component.set("v.Screen2",false);
    	component.set("v.Screen3",false);
    	
    	/*Reset Lookup Values*/
        if(component.get("v.CaseSubType") != 'PM'){
            component.set("v.AssetName","");
            component.set("v.AssetId","");
            component.set("v.AssetAccountId","");
            component.set("v.customerAccountId","");
            component.set("v.customerAccountName","");
            component.set("v.SerialNumber","");
            component.set("v.CommunityProductDesc","");
            component.set("v.InstallLocationLabel","");
            component.set("v.ProductName","");
            component.set("v.ProductId","");
            component.set("v.disableProduct",false);
            component.set("v.disableAsset",false);
        }
    },
    Screen2Next : function(component, event, helper) {
    	console.log('############################### Screen 2 Next ###############################');
    	var priorityStatus = helper.PriorityValidation(component, event, helper);
    	if(priorityStatus == 'Fail'){
    		return;
    	}
    	
    	var Type = component.get('v.CaseType');
    	var assetInputId = component.get('v.assetRecordId');
    	if(assetInputId != null && assetInputId != '' && assetInputId != undefined && assetInputId != 'None' && Type == 'Web'){
        	var status = helper.q1Validation(component, event, helper);
	    	if(status == 'Fail'){
	    		return;
	    	}
        }
        helper.saveCase(component, event, helper, 'Next');
    },
    Screen3Back : function(component, event, helper) {
    	console.log('############################### Screen 3 Back ###############################');
    	component.set("v.Screen1",false);
    	component.set("v.Screen2",true);
    	component.set("v.Screen3",false);
    },
    Screen2Save : function(component, event, helper) {
        helper.saveCase(component, event, helper, 'Save');
    },
    Screen3Save : function(component, event, helper) {
        helper.createServiceRequestComments(component, event, helper);
    },
    handleQ1Change : function(component, event, helper) {
    	console.log('############################### Handle Q1 Change ###############################');
        component.set("v.showQ1Error",false);
    	var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ1TextBox",true);
        }else{
            component.set("v.q1Answer",'');
            component.set("v.displayQ1TextBox",false);
        }
    },
	handleQ2Change : function(component, event, helper) {
		console.log('############################### Handle Q2 Change ###############################');
        component.set("v.q2Required",false);
        component.set("v.showQ2Error",false);
    	var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ2TextBox",true);
        }else{
            component.set("v.q2Answer",'');
            component.set("v.displayQ2TextBox",false);
        }
    },
    handleQ3Change : function(component, event, helper) {
    	console.log('############################### Handle Q3 Change ###############################');
        component.set("v.q3Required",false);
        component.set("v.showQ3Error",false);
    	var changeValue = event.getParam("value");
        if(changeValue == 'Yes'){
           component.set("v.displayQ3TextBox",true);
        }else{
            component.set("v.q3Answer",'');
            component.set("v.displayQ3TextBox",false);
        }
    },
    callChildCompMethod : function(component, event, helper) {
    	console.log('You are here 1');
    	var childCmp = component.find('childCmp');
    	console.log('You are here 2');
        childCmp.sampleMethod(component.get('v.NewSR.Subject')); 
        console.log('You are here 3');
    },
    
    // PM Schedule data while case creation  US-0006345 START
    // Next button on Service Appointment screeen
    SAScreenNext : function(component, event, helper) {
        component.set("v.Screen1",false);
    	component.set("v.Screen2",true);
    	component.set("v.Screen3",false);
        component.set("v.SAScreen",false);
    },
    // Back button on Service Appointment screeen
    SAScreenBack : function(component, event, helper) {
        component.set("v.Screen1",true);
    	component.set("v.Screen2",false);
    	component.set("v.Screen3",false);
    	component.set("v.SAScreen",false);
    	/*Reset Lookup Values*/
    	component.set("v.AssetName","");
    	component.set("v.AssetId","");
    	component.set("v.AssetAccountId","");
    	component.set("v.customerAccountId","");
    	component.set("v.customerAccountName","");
    	component.set("v.SerialNumber","");
    	component.set("v.CommunityProductDesc","");
    	component.set("v.InstallLocationLabel","");
    	component.set("v.ProductName","");
    	component.set("v.ProductId","");
    	component.set("v.disableProduct",false);
    	component.set("v.disableAsset",false);
        component.set("v.showSAEmptyMessage", false);
    }
    // PM Schedule data while case creation  US-0006345 END
})