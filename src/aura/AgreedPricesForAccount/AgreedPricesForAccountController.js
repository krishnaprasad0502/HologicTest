({
    doInit: function(component, event, helper) {      
        // Fetch the account list from the Apex controller   
        helper.getAgreedPrices(component);
    },
    
    gotoDetail : function(component, event, helper) {
        helper.gotoDetail(component);
    }
})