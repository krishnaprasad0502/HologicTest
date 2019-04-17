({
   
    okay : function(component, event, helper) {
       //Update expense counters
        var id = component.get("v.recordId");
       console.log(id);
       var action=component.get("c.contactAddress");
       action.setParams({"externalcontactid":component.get("v.recordId")});
       action.setCallback(this, function(response) {
           
         var state = response.getState();
       //console.log("state");
         if(component.isValid() && state == "SUCCESS"){
               var c = response.getReturnValue();
               component.set("v.recordid",c);
               $A.get('e.force:refreshView').fire();
               $A.get("e.force:closeQuickAction").fire();
         }
         
           });
     
       $A.enqueueAction(action); 
    },
  cancelmethod : function(component,event,helper){
       $A.get("e.force:closeQuickAction").fire();
        
    },
     

})