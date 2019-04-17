({
    /*Initialize - Fetch State Picklist Values*/
    initialize: function(component, event, helper) {
        console.log('initialize');
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap2}).fire();        
        component.set('v.extraFields', helper.getExtraFields(component, event, helper));
        
        var action2 = component.get("c.FetchStatePicklistValues");
        action2.setParams({
            'objDetail' : component.get("v.objDetail")
        });
        action2.setCallback(this, function(response){
        	var rtnValue = response.getReturnValue();
            component.set("v.stateValues",response.getReturnValue());			           
        });
        $A.enqueueAction(action2);
        
        // to fetch the country Picklist values
        var action3 = component.get("c.FetchCountryPicklistValues");
        action3.setParams({
            'objDetail' : component.get("v.objDetail")
        });
        action3.setCallback(this, function(response){
        	var rtnValue1 = response.getReturnValue();
            component.set("v.countryValues",response.getReturnValue());            
        });
        $A.enqueueAction(action3);
        
        // Fetch TimeZone 
        helper.fetchTimeZone(component, 'Community_Timezone__c');
    },
    OnTermsSelection: function(component, event, helper) {
        var checkCmp = component.find("taskCheckBox"); 
        var cboxValue = checkCmp.get("v.value");
        console.log("value : " + checkCmp.get("v.value"));
        component.set("v.termsCheckbox",cboxValue);
    }, 
    
    /*Gets invoked while upon the click of Request Account */
    handleSelfRegister: function (component, event, helper) {
        // console.log('ProdInt: ' + component.get("v.ProductInterest") + ' serial' + component.get("v.SerialNumber"));
        component.set("v.disablebutton",true);
        if(!component.get("v.termsCheckbox")){
            //alert('Please accept terms to proceed further.');
            var Error = $A.get("$Label.c.Support_Self_Register_Error_Message");
            component.set("v.errorMessage",Error);
            component.set("v.showError",true);
            component.set("v.disablebutton",false);
            return;
        }   
        
        helper.handleSelfRegister(component, event, helper);
    },
    
    /*Set Start Url*/
    setStartUrl: function (component, event, helper) {
        var startUrl = event.getParam('startURL');
        if(startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },
    
    /*Set Exp Id*/
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    
    /*On the click of enter - handleSelfRegisterid invoked*/
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helper.handleSelfRegister(component, event, helper);
        }
    }   
})