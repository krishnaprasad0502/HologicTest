({
    /*Opens Case creation popup with Asset lookup and type: Complaint*/
    SubmitAnIssue : function(component, event, helper) {
        component.set("v.Type2","Web");
        component.set("v.SubType2","");//uncommented by Nikhil for DF 350
        component.set("v.Priority2","Sev 2");
        component.set("v.isListViewAction", false);
        // set CaseTitle to 'Submit an Issue' to defualt priority to Sev 2 US-0006454
        component.set("v.CaseTitle", "Submit an Issue");
    	helper.InvokeComponent(component, event, helper);
    },
    /*Opens Case creation popup with Product lookup */
    SubmitDisposableIssues : function(component, event, helper) {
        component.set("v.Type2","Web");
        component.set("v.SubType2","");
        component.set("v.Priority2","Sev 2");
        component.set("v.isListViewAction", false);
        // set CaseTitle to 'Submit an Issue' to defualt priority to Sev 2 US-0006454
        component.set("v.CaseTitle", "Disposable Product Issues");
    	helper.InvokeDisposableComponent(component, event, helper);
    },
    
    /*Opens Case creation popup with type: Scheduled Event and sub-type: PM and Priority: NA*/
	SchedulePreventiveMaintenance : function(component, event, helper) {
        component.set("v.Type2","Scheduled Event");
        component.set("v.SubType2","PM");
        component.set("v.Priority2","NA");
        component.set("v.isListViewAction", false);
        component.set("v.Subject","Request for PM Scheduling");
    	helper.InvokeComponent(component, event, helper);
    },
    
    /*Opens Case creation popup with type: Inquiry and sub-type: null and Priority: Sev 2*/
    GeneralInquiry : function(component, event, helper) {
        component.set("v.Type2","Web");
        component.set("v.SubType2","");
        component.set("v.Priority2","Sev 2");
        component.set("v.isListViewAction", true);
        // set CaseTitle to '' US-0006454
        component.set("v.CaseTitle", "");
    	helper.InvokeComponent(component, event, helper);
    },
    
    /*Opens Case creation popup with type: Scheduled Event and sub-type: Clincal Training and Priority: NA*/
	RequestTrainingServices : function(component, event, helper) {
        component.set("v.Type2","Scheduled Event");
        component.set("v.SubType2","Clincal Training");
        component.set("v.Priority2","NA");
        component.set("v.isListViewAction", false);
    	helper.InvokeComponent(component, event, helper);
    },
    
    /*Opens Case creation popup with type: Scheduled Event and sub-type: Service and Priority: NA*/
	RequestClinicalProfessionalServices	 : function(component, event, helper) {
        component.set("v.Type2","Scheduled Event");
        component.set("v.SubType2","Service");
        component.set("v.Priority2","NA");
    	helper.InvokeComponent(component, event, helper);
    },
    
    /*Opens Case creation popup with type: Inquiry and sub-type: null*/
	RequestConnectivityProfessionalServices : function(component, event, helper) {
        component.set("v.Type2","Inquiry");
        component.set("v.SubType2","");
    	helper.InvokeComponent(component, event, helper);
    },  
    ViewServiceAppointment : function(component, event, helper) {
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue());  
            helper.OpenServiceAppointments(component, event, helper);
        });
        $A.enqueueAction(address1);
    	
    }, 
    
    /*Closes the case creation pop up*/
    closeModel: function(component, event, helper) {
		component.set("v.isOpen", false);
	}
})