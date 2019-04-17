({
    /*Checks Whether the Asset record is favorite for the loggedin user.*/
	doInit : function(component, event, helper) {
		var action = component.get("c.CheckFavourite");
		action.setParams({ 
			RecId : component.get("v.recordId")
		});
		action.setCallback(this,function(response){
            component.set("v.display",response.getReturnValue());
		});
		$A.enqueueAction(action); 
	},
    
    /*Updates the record to user favorite on the click of Add to favorite button*/
    UpdateRecordtoFavourite : function(component, event, helper) {
    	var action = component.get("c.UpdateFavourite");
		action.setParams({ 
			RecId : component.get("v.recordId")
		});
        alert('You are here');
        action.setCallback(this,function(response){
            alert(response.getReturnValue());
            if(response.getReturnValue() == 'Success'){
                component.set("v.display","True");
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message:'Something Went Wrong',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error'
                });
                toastEvent.fire();
            }
        });
		$A.enqueueAction(action);     
    },
    
    /*Removes the record from Users favorite list on the click of Remove favorite button*/
	RemoveFavourite : function(component, event, helper) {
    	var action = component.get("c.RemoveFromFavourites");
		action.setParams({ 
			RecId : component.get("v.recordId")
		});
        alert('You are here');
        action.setCallback(this,function(response){
            alert(response.getReturnValue());
            if(response.getReturnValue() == 'Success'){
                component.set("v.display","False");
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error Message',
                    message:'Something Went Wrong',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error'
                });
                toastEvent.fire();
            }
        });
		$A.enqueueAction(action);   
    }    
})