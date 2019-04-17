({
	doInit: function(component) {
        var address = component.get('c.fetchConfigData'); 
       	address.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());  
       	});
        var action=component.get('c.getSobjectRecordName'); 
        action.setParams({ 
			sobjname : component.get("v.SobjType"),
            sobjRecId : component.get("v.recordId"),
            fieldName1 : component.get("v.sobjFieldName1"),
            fieldName2 : component.get("v.sobjFieldName2")
		});
        action.setCallback(this, function(response) { 
            component.set("v.sobjRecord", response.getReturnValue());  
             
        });
        var address1 = component.get('c.fetchOrgURL'); 
        address1.setCallback(this, function(response) { 
           component.set("v.orgBaseUrl", response.getReturnValue());  
        });

        $A.enqueueAction(action);
        $A.enqueueAction(address1);
        $A.enqueueAction(address);
	},
})