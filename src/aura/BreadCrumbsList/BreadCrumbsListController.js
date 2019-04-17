({
	doInit : function(component, event, helper) {
		var getUrlParameter = function getUrlParameter(sParam){
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            console.log('url is'+window.location.pathname);
            for (i = 0; i < sURLVariables.length; i++){
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        
        var urlArtType = getUrlParameter('ReportType');
        if(urlArtType == 'History'){
            component.set("v.firstLevelNavLabel",'Generate Service History Report')
        }
        
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting", response.getReturnValue());  
        });
        
        if(component.get("v.recordId") != 'undefined'){
            var action = component.get('c.fetchRecordName'); 
            action.setParams({
                currentRecId : component.get("v.recordId"),
                fieldAPI : component.get("v.fieldName"),
                objType : component.get("v.ListType")
            });
            action.setCallback(this, function(response) { 
                component.set("v.currentPageLabel", response.getReturnValue());  
            });
        }
        $A.enqueueAction(address1);
        $A.enqueueAction(action);
	}
})