({
	doInit: function(component) {
        var action=component.get('c.getSobjectRecordName'); 
        action.setParams({ 
			sobjname : component.get("v.SobjType"),
            sobjRecId : component.get("v.recordId"),
            fieldName1 : component.get("v.sobjFieldName1"),
            fieldName2 : component.get("v.sobjFieldName2"),
            fieldName3 : component.get("v.sobjFieldName3"),
            fieldName4 : component.get("v.sobjFieldName4")
		});
        action.setCallback(this, function(response) { 
            component.set("v.sobjRecord", response.getReturnValue());
        });
        var value = component.get('v.sobjRecord');
        $A.enqueueAction(action);
        
    }
})