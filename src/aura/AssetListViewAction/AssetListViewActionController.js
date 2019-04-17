({
	/*Opens Case creation popup with type: Inquiry and sub-type: null and Priority: Sev 2*/
    GeneralInquiry : function(component, event, helper) {
        component.set("v.Type","Web");
        component.set("v.SubType","");
        component.set("v.Subject","Support Portal - Requesting Access to Systems for Additional Locations");
        component.set("v.Priority","Sev 3");
        component.set("v.isListViewAction", true);
    	helper.InvokeComponent(component, event, helper);
    },
    
    /*Closes the case creation pop up*/
    closeModel: function(component, event, helper) {
		component.set("v.isOpen", false);
	}
})