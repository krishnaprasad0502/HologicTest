({
	fetchAccountrecords : function(component, event, helper) {
        
        component.set('v.mycolumns', [
            {label: 'Favorites', fieldName: 'isFavourite', type: 'text'},
            {label: 'System Name', fieldName: 'systemlinkName', type: 'url',
             typeAttributes: {label: { fieldName: 'Community_Custom_Asset_Name__c' }, target: '_blank'}},
            {label: 'Serial Number', fieldName: 'SerialNumber', type: 'text'},
            {label: 'Product', fieldName: 'Community_Product_Description__c', type: 'text'},
            {label: 'Asset Location', fieldName: 'Asset_Location__c', type: 'text'}
        ]);
        var action = component.get("c.fetchAssetsList");
        action.setParams({
            "communityDescription":component.get("v.communityDescription")
        });
        action.setCallback(this, function(response){
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
            	var siteUrl = component.get("v.configSetting").SiteURL__c ;
            	var homeUrl = component.get("v.configSetting").Hologic_Home__c
                records.forEach(function(record){
                    record.linkName = siteUrl+homeUrl+'asset/'+record.Id;
                    record.systemlinkName = siteUrl+homeUrl+'asset/'+record.Id;
                    if($A.util.isEmpty(record.Community_Custom_Asset_Name__c)){
                        record.Community_Custom_Asset_Name__c = record.Name ;
                    }    
                    if(record.Community_Favorite_Asset__c){
                        record.isFavourite = 'Y' ;
                    }
                });
                component.set("v.assetList", records);
            }
        });
                   
        $A.enqueueAction(action);
    },
    
    getDataHelper : function(component, event) {
        var action = component.get("c.getObjRecords");
        //Set the Object parameters and Field Set name
        action.setParams({
            strObjectName : 'Asset',
            strFieldSetName : 'Service_Community_Asset_List_View',
            communityDescription: component.get("v.communityDescription")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                component.set("v.mycolumns", response.getReturnValue().lstDataTableColumns);
                component.set("v.mydata", response.getReturnValue().lstDataTableData);    
            }else if (state === 'ERROR'){
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log('Something went wrong, Please check with your admin');
            }
        });
        $A.enqueueAction(action);	
    }
})