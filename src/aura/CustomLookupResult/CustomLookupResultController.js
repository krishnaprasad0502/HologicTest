({
	doInit: function(component, event, helper) {
        if(component.get("v.objectAPIName") == 'Asset'){
        	//console.log('The Object APi Name is: '+component.get("v.objectAPIName"));
            var str = component.get("v.oRecord.Install_Location_Label__c");
            //console.log('The Object APi Name is: '+str);
            if(str != undefined ){
            	str = str.replace(/<br>/g,',');
            }    
            component.set("v.oRecord.Install_Location_Label__c",str);
        }    
    },
	selectRecord : function(component, event, helper){       
		var getSelectRecord = component.get("v.oRecord");
		console.log('In Custom Lookup Result: ');
		console.log(getSelectRecord.Name);
		var compEvent = component.getEvent("oSelectedRecordEvent");
        compEvent.setParams({"recordByEvent" : getSelectRecord });  
        compEvent.fire();
    }
})