({
	doInit: function(component) {
        var action=component.get('c.getSobjectRecordName'); 
        action.setParams({ 
			sobjname : component.get("v.SobjType"),
            sobjRecId : component.get("v.recordId"),
            fieldName1 : component.get("v.sobjFieldName1"),
            fieldName2 : component.get("v.sobjFieldName2"),
            fieldName3 : ''
		});
        
        action.setCallback(this, function(response) { 
            component.set("v.sobjRecord", response.getReturnValue());  
        });
        var value = component.get('v.sobjRecord');
        $A.enqueueAction(action);
    },
    gotoMenuURL : function(component, event, helper) {
        var menuUrl = component.get("v.menuUrl");
        var productRec = component.get("v.sobjRecord");
        helper.gotoURL(component,productRec[0].value1);
        console.log('productRec*******',productRec[0].value1);
    }
})