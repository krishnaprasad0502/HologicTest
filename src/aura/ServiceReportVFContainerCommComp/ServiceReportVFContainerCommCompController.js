({
	doInit : function(component, event, helper) {
        var action = component.get('c.fetchConfigData'); 
       	action.setCallback(this, function(response) { 
        component.set("v.configSetting", response.getReturnValue());
           
       	});
		$A.enqueueAction(action);
        // the function that reads the url parameters
        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            console.log('page URL: ' + window.location);
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
            return 'BLANK';
        };
        
        
       //Get paramter passed to URL 
       //ID can be of Account or Asset 
       //Possible Values for RecordType - Customer and Site
	   var objectId = getUrlParameter('Id');
       var recordType = getUrlParameter('RecordType');
       var reportType = getUrlParameter('ReportType');
       //var baseURL = component.get("v.communityURL");
       component.set("v.link", "/apex/ServiceReportVFContainer?Id=" + objectId +"&RecordType=" + recordType + "&ReportType="+ reportType);
     	//	component.set("v.link",baseURL +"/apex/ServiceReportVFContainer?Id=" + objectId +"&RecordType=" + recordType + "&ReportType="+ reportType);
        console.log(component.get("v.link"));
    }
})