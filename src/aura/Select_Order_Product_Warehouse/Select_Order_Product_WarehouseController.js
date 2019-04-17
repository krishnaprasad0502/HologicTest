({
    handleClick : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/WarehouseSelection?Id=" + component.get("v.recordId")
        });
        urlEvent.fire();
	}
})