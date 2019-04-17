({
    doInit: function(component) {
        
        // Adding Product Family Icon START US-0006345 //
        // To fetch custom setting values
        var config = component.get('c.fetchConfigData'); 
       	config.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());  
       	});
        $A.enqueueAction(config);
        // Adding Product Family Icon END
        
        var address=component.get('c.getProductFamilyData'); 
        address.setCallback(this, function(response) { 
            component.set("v.productFamilyList", response.getReturnValue()); 
        });
        var value = component.get('v.productFamilyList');
        $A.enqueueAction(address);
        
        
    },
    onProductViewChange: function(component) {
        var selectedOption = component.find("select1");
        var selectedOptionVal = selectedOption.get("v.value");
        component.set("v.listViewName",selectedOptionVal);
        if(selectedOptionVal == 'My Products') {
            var myProdFamily=component.get('c.getMyProductFamilyData'); 
            myProdFamily.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.productFamilyList", response.getReturnValue());
                }else if (state === "ERROR") {
                    var errors = response.getError();
                }
                
            });
            var value = component.get('v.productFamilyList');
            $A.enqueueAction(myProdFamily);
        }
        else{
            var address=component.get('c.getProductFamilyData'); 
            address.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.productFamilyList", response.getReturnValue());
                }else if (state === "ERROR") {
                    var errors = response.getError();
                } 
            });
            var value = component.get('v.productFamilyList');
            $A.enqueueAction(address);  
        }
    }
})