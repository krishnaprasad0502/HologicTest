({
    init: function (component) {
        var imgurl = $A.get(component.get("v.IconName"));
        component.set("v.logoImageUrl",imgurl); 
        
        //FetchRecords
        var action = component.get("c.FetchRecords");
        action.setParams({ 
			Type : component.get("v.MenuType"),
		});
        action.setCallback(this,function(response){
			component.set("v.ReturnedRecords",response.getReturnValue());
        });
        var action1 = component.get('c.fetchConfigData'); 
       	action1.setCallback(this, function(response) { 
           component.set("v.configSetting", response.getReturnValue());
           
       });
		$A.enqueueAction(action);
        $A.enqueueAction(action1);
    },
    openModel: function(component, event, helper) {
		// for Display Model,set the "isOpen" attribute to "true"
		component.set("v.isOpen", true);
	},
 
	closeModel: function(component, event, helper) {
		// for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
		component.set("v.isOpen", false);
	},
    InvokeComponent: function(component, event, helper) {
        component.set("v.isOpen", true);
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var res = id_str.split("#");
        var assetRecordId = component.get("v.recordId");
        var Value1 = res[1];
        var Value2 = res[2];
        // Default the Priority for Submit an Issue to 'Sev 2' US=0006454
        var Value3 = res[3];
        var Title = res[4];
		$A.createComponent("c:SubmitNewCase",{
				"aura:id" : "CaseComp",
            	"CaseType" : Value1,
            	"CaseSubType" : Value2,
            	"CasePriority" : Value3,
            	"assetRecordId" : assetRecordId,
            	"CaseTitle" : Title
            }, function(newCmp,status,errorMessage) {
            	if (component.isValid()) {
					if(status == "ERROR") {
						console.log('Error Message--',errorMessage);
					}
					component.set("v.comp", newCmp);
				}
            }    
        );
    }    
})