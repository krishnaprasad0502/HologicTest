({    
    fetchAssets : function(component, event, helper) {    
        
        var getUrlParameter = function getUrlParameter(sParam){
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            
            for (i = 0; i < sURLVariables.length; i++){
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        
        var urlArtType = getUrlParameter('description');
        
        if(urlArtType != '' && urlArtType != null){
            urlArtType = urlArtType.split("+").join(" ") ;
            component.set("v.communityDescription", urlArtType);
        }
        
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting",response.getReturnValue());
            helper.fetchAccountrecords(component, event, helper);
        });
        $A.enqueueAction(address1);
        
       // helper.getDataHelper(component, event);
    }
})