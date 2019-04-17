({
  // Fetch the accounts from the Apex controller
  getAgreedPrices: function(component) {
    var action = component.get('c.getAgreedPrices');
    action.setParams({"accountId": component.get("v.accountId")});
    //action.setParams({"accountId": '0015B00000LmDJ4QAN'});

    // Set up the callback  
    var self = this;
    action.setCallback(this, function(actionResult) {
     component.set('v.agreedPrices', actionResult.getReturnValue());
    });
    $A.enqueueAction(action);
  },
    
  gotoDetail : function(component) {
    var navEvt = $A.get("e.force:navigateToSObject");
          navEvt.setParams({
          	"recordId": component.get("v.agreedPrice.contract__r.Id"),
          	"slideDevName": "detail"
        });
        navEvt.fire();

  }
})