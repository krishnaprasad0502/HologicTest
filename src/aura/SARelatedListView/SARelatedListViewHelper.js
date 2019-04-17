({
	// This method is created to return Service Appointment records based on the asset id.
    
    getServiceAppointment : function(component, event, helper, recId, assetaction) {
        
        
        component.set('v.mycolumns', [
            {label: 'Appointment No',  fieldName: 'SAlinkName', type: 'url', 
             typeAttributes: {label: { fieldName: 'AppointmentNumber' }, target: '_blank'}},
            {label: 'Case No', fieldName: 'SACaseNoLink', type: 'url', 
             typeAttributes: {label: { fieldName: 'SACaseNo' }, target: '_blank'}},
            {label: 'Status', fieldName: 'Status', type: 'text'},
            {label: 'System', fieldName: 'SAAssetName', type: 'text'},
            {label: 'Serial Number', fieldName: 'SASystemSerialNo', type: 'text'},
            {label: 'WO Record Type', fieldName: 'SAworkorderType', type: 'text'},
            {label: 'Scheduled Start', fieldName: 'SchedStartTime', type: 'date'},
            {label: 'Subject', fieldName: 'Subject', type: 'text'}
		]); 
        
        var action = component.get("c.fetchServiceAppointment");
        action.setParams({
            "strObjectName" : component.get("v.SAsObjectName"),
            "strFieldSetName" : component.get("v.SAFieldSetName"),
            "AssetId" : recId,
            "assetaction" : assetaction
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var records =response.getReturnValue();
            	var siteUrl = component.get("v.configSetting").SiteURL__c ;
            	var homeUrl = component.get("v.configSetting").Hologic_Home__c
                records.forEach(function(record){
                    record.SAlinkName = siteUrl+homeUrl+'serviceappointment/'+record.Id;
                    if(record.Case_No__c !=null || record.Case_No__c !=undefined){ 
                        record.SACaseNo = record.Case_No__r.CaseNumber; 
                        record.SACaseNoLink = siteUrl+homeUrl+'case/'+record.Case_No__c; 
                    }else{ 
                        record.SACaseNo = '';
                        record.SACaseNoLink = '';
                    }
                    record.SAAssetName = record.Related_Work_Order__r.Asset.Name;
            		record.SASystemSerialNo = record.Related_Work_Order__r.Asset_Serial_Number__c;
                    record.SAworkorderType = record.Related_Work_Order__r.RecordType.Name;
            
                });
                component.set("v.SAList", response.getReturnValue()); 
           		component.set("v.ServiceAppointmentList", response.getReturnValue());
                console.log('component.get(v.ServiceAppointmentList)>>>>>',component.get('v.ServiceAppointmentList'));
                if(component.get('v.ServiceAppointmentList') == null || component.get('v.ServiceAppointmentList') == '' || component.get('v.ServiceAppointmentList') == undefined){
                    component.set("v.showSAEmptyMessage", true); 
                }
            }else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log('Something went wrong, Please check with your admin');
            }
        });
        $A.enqueueAction(action);	
    },
    
    // Method is used to read URL parameter and user it.
    
    getParameterByName: function(component, event, name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
})