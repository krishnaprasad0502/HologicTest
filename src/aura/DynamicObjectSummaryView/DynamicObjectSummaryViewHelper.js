({
	getChildRecordId : function(component) {
        var action = component.get('c.getRelatedObjectId');
        action.setParams({ 
            parentRecordId : component.get("v.recordId"),
            relatedObjectApiName : component.get("v.childSobjType"),
            parentFieldName : component.get("v.parentObjectFieldAPIName")
        });
        var self = this ;
        action.setCallback(this, function(response) { 
            component.set("v.childRecordId", response.getReturnValue()); 
            alert('Entered Test1'+ response.getReturnValue());
            self.method2(component);
        });
        $A.enqueueAction(action);
	},
    method2 : function(component) {
        alert('Entered Test1'+ component.get("v.childRecordId"));
        var action2 = component.get('c.readFieldSet'); 
        action2.setParams({ 
            fieldSetName : component.get("v.fieldSetName"),
            objectName : component.get("v.childSobjType")
        });
        
        action2.setCallback(this, function(response) {
            component.set("v.fieldList", response.getReturnValue());  
        });
        $A.enqueueAction(action2);
	}
})