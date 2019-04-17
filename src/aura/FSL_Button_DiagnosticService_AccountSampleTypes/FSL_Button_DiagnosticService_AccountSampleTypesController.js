({
    showSampleTypes : function(component, event, helper) {
        var sampleTypes = null,

            action = component.get("c.getTypes"),
            urlEvent = $A.get("e.force:navigateToURL"),

            recordId = component.get("v.recordId");
        
        action.setCallback(this, function(response){
            if(response !== null && response.getState() == 'SUCCESS') {
                sampleTypes = response.getReturnValue();

                urlEvent.setParams({
                    "url": '/' + sampleTypes + '?pv0=' + recordId // Account.Id
                });
                urlEvent.fire();
            } else {
                console.log('Account Sample Types error');
            }
        });
        $A.enqueueAction(action);
    }
})