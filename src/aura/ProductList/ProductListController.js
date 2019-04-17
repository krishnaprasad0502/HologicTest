({
	onAllProductSelection : function(component, event, helper) {
        var products=component.get('v.products');
        component.set('v.showCount',products.length);
	},
    doInit: function(component) {
		var products=component.get('v.products');            
    }
})