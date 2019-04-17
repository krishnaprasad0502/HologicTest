({
    doInit: function(component,event,helper) {
        var action = component.get('c.getServiceAppointment');
        action.setParams({ 
            objectRecordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) { 
            component.set("v.ServiceAppointmentRecord", response.getReturnValue()); 
            var reportID = component.get("v.ServiceAppointmentRecord.Community_Service_Report_ID__c");
            if( reportID != undefined ){
                component.set("v.isReportReady",true);
            }
        });
        $A.enqueueAction(action);
    }
})