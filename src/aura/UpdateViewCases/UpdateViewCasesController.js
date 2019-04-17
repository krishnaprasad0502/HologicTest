({
	/*doInit : function(component, event, helper) {       
		helper.updateRelationship(component);
	}*/   
    doInit: function(component, event, helper) {
      // call the fetchPickListVal(component, field_API_Name, aura_attribute_name_for_store_options) -
      // method for get picklist values dynamic  
        helper.fetchPickListVal(component, 'Community_View_All_Cases__c', 'ratingPicklistOpts');
    },
       
    inlineEditRating : function(component,event,helper){   
        // show the rating edit field popup 
        component.set("v.ratingEditMode", true); 
        // after set ratingEditMode true, set picklist options to picklist field 
        component.find("accRating").set("v.options" , component.get("v.ratingPicklistOpts"));
        // after the 100 millisecond set focus to input field   
        setTimeout(function(){ 
            component.find("accRating").focus();
        }, 100);
    },
 
    onRatingChange : function(component,event,helper){ 
        // if picklist value change,
        // then show save and cancel button by set attribute to true
        component.set("v.showSaveCancelBtn",true);
    },      
    
    closeRatingBox : function (component, event, helper) {
       // on focus out, close the input section by setting the 'ratingEditMode' att. as false
        component.set("v.ratingEditMode", false); 
    },    
})