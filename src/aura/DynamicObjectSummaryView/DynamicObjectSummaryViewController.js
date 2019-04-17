({
	doInit: function(component,event,helper) {
        if(component.get("v.isRelatedListView")){
            
            var action = component.get('c.getRelatedObjectId'); 
            action.setParams({ 
                parentRecordId : component.get("v.recordId"),
                relatedObjectApiName : component.get("v.childSobjType"),
                parentFieldName : component.get("v.parentObjectFieldAPIName")
            });
            action.setCallback(this, function(response) { 
                component.set("v.childRecordId", response.getReturnValue()); 
                component.set("v.isDataLoadComplete", true); 
            });
            
            var action2 = component.get('c.readFieldSet'); 
            action2.setParams({ 
                fieldSetName : component.get("v.fieldSetName"),
                objectName : component.get("v.childSobjType")
            });
            
            action2.setCallback(this, function(response) {
               component.set("v.fieldList", response.getReturnValue());  
            });
            $A.enqueueAction(action);
            $A.enqueueAction(action2);
            //helper.getChildRecordId(component);
        }else{
            if(component.get("v.parentObjectFieldAPIName")!= null && component.get("v.parentObjectFieldAPIName") != ''){
                
                var action = component.get('c.getParentObjectId'); 
                action.setParams({ 
                    parentRecordId : component.get("v.recordId"),
                    ObjectApiName : component.get("v.sobjType"),
                    parentFieldName : component.get("v.parentObjectFieldAPIName")
                });
                action.setCallback(this, function(response) { 
                    component.set("v.parentRecordId", response.getReturnValue()); 
                    component.set("v.isDataLoadComplete", true); 
                });
                
                var action2 = component.get('c.readFieldSet'); 
                action2.setParams({ 
                    fieldSetName : component.get("v.fieldSetName"),
                    objectName : component.get("v.childSobjType")
                });
                
                action2.setCallback(this, function(response) {
                    component.set("v.fieldList", response.getReturnValue());  
                });
                $A.enqueueAction(action);
                $A.enqueueAction(action2);
                
            }else {
            	var action2 = component.get('c.readFieldSet'); 
                action2.setParams({ 
                    fieldSetName : component.get("v.fieldSetName"),
                    objectName : component.get("v.sobjType")
                });
                
                action2.setCallback(this, function(response) { 
                   component.set("v.fieldList", response.getReturnValue()); 
                   component.set("v.isDataLoadComplete", true); 
                });
                
                $A.enqueueAction(action2);    
            }
        }
        /*var action = component.get('c.getCaseSummaryRecordId'); 
        action.setParams({ 
            caseRecordId : component.get("v.recordId")
		});
       	action.setCallback(this, function(response) { 
           component.set("v.childRecordId", response.getReturnValue());  
       	});

        $A.enqueueAction(action);*/
	}
})