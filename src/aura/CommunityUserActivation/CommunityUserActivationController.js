({
	doInit : function(component, event, helper) {       
		helper.checkExistingUser(component);
	},
    enableCustomerUser : function(component, event, helper) {
		helper.enableCustomerUser(component);
	},
    disableCustomerUser : function(component, event, helper) {
		helper.disableCustomerUser(component);
	}
})