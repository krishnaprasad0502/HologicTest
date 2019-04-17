({
    /*Search knowledge articles depending upon the input from Subject in Case creation component*/
	myAction : function(component, event, helper) {
		console.log('You are here 4');
        var params = event.getParam('arguments');
        var param1 = params.searchString;
        console.log('You are here 5'+param1);
		var action = component.get("c.searchArticles");
        action.setParams({ 
			searchString : param1 
		});
        action.setCallback(this, function(response) {
            console.log('The articles are:');
            console.log(param1);
            console.log(response.getReturnValue());
            component.set("v.Articles",response.getReturnValue());
        });
        $A.enqueueAction(action);
	},
	navigateToArticleDetail : function(component, event, helper) {

        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;

        var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	      "recordId": id_str
	    });
	    navEvt.fire();
	}
})