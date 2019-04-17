({
	doInit : function(component, event, helper) {
        
        
        var address1 = component.get('c.fetchConfigData'); 
        address1.setCallback(this, function(response) { 
            component.set("v.configSetting",response.getReturnValue());
            var recId = helper.getParameterByName(component , event, 'recorddetailid');
            var assetaction = helper.getParameterByName(component , event, 'assetactionpanel');
            console.log('RECID',recId);
            helper.getServiceAppointment(component,event, helper, recId, assetaction);
        });
        $A.enqueueAction(address1);
        
        
        
	}
})