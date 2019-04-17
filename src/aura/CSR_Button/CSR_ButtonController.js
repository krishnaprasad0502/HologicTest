({
    handleClick : function(component, event, helper) {
        
        var objectType = component.get("v.sObjectName"),
            recId = component.get("v.recordId"),
            recRes = recId.substring(0, recId.length - 3),
            buildURL = "/apex/CSRIntakeFormLegasy?Id=" + recRes,
            
            rType = component.get("v.simpleRecord.RecordType.Name");
        
        if (objectType == "Account") {
            // buildURL += "&RecordType=" + rTypeId;
            buildURL += "&RecordType=" + rType;
            // buildURL += "&RecordType=" + objectType;
        }
        
        console.log("CSR Button","buildURL",buildURL);
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": buildURL
        });
        urlEvent.fire();
	}
})