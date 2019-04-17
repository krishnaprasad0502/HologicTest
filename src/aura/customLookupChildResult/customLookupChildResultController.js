({
	
    doInit: function(component, event, helper) {
        if(component.get("v.ObjectType") == 'Asset'){
            var str = component.get("v.oRecord.Install_Location_Label__c");
            if(str != undefined ){
            	str = str.replace(/<br>/g,',');
            }    
            component.set("v.oRecord.Install_Location_Label__c",str);
        }    
    },
    /*Gets invoked on Asset record selection*/    
   	selectRecord : function(component, event, helper){      
      	var getSelectRecord = component.get("v.oRecord");
        var record = component.get("v.ObjectType");
        var compEvent = component.getEvent("oSelectedRecordEvent");  
		compEvent.setParams({"recordByEvent" : getSelectRecord,
                             "recordType" : record
                            });  
        compEvent.fire();
	}
})