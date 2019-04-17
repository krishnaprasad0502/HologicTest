({
	doInit : function(component, event, helper) {

		if(component.get("v.Line1Header") == 'Large Header'){
			component.set("v.Line1Header","slds-text-heading_large");
		}
		else if(component.get("v.Line1Header") == 'Medium Header'){
			component.set("v.Line1Header","slds-text-heading_medium");
		}
		else if(component.get("v.Line1Header") == 'Small Header'){
			component.set("v.Line1Header","slds-text-heading_small");
		}
		else if(component.get("v.Line1Header") == 'Plain Text'){
			component.set("v.Line1Header","");
		}
        else if(component.get("v.Line1Header") == 'Colored Text'){
            component.set("v.Line1Header","ListHeader");
        }
		
		if(component.get("v.Line2Header") == 'Large Header'){
			component.set("v.Line2Header","slds-text-heading_large");
		}
		else if(component.get("v.Line2Header") == 'Medium Header'){
			component.set("v.Line2Header","slds-text-heading_medium");
		}
		else if(component.get("v.Line2Header") == 'Small Header'){
			component.set("v.Line2Header","slds-text-heading_small");
		}
		else if(component.get("v.Line2Header") == 'Plain Text'){
			component.set("v.Line2Header","");
		}
		else if(component.get("v.Line2Header") == 'Colored Text'){
            component.set("v.Line2Header","ListHeader");
        }
        
		if(component.get("v.Line3Header") == 'Large Header'){
			component.set("v.Line3Header","slds-text-heading_large");
		}
		else if(component.get("v.Line3Header") == 'Medium Header'){
			component.set("v.Line3Header","slds-text-heading_medium");
		}
		else if(component.get("v.Line3Header") == 'Small Header'){
			component.set("v.Line3Header","slds-text-heading_small");
		}
		else if(component.get("v.Line3Header") == 'Plain Text'){
			component.set("v.Line3Header","");
		}
		else if(component.get("v.Line3Header") == 'Colored Text'){
            component.set("v.Line3Header","ListHeader");
        }
        
		if(component.get("v.Line4Header") == 'Large Header'){
			component.set("v.Line4Header","slds-text-heading_large");
		}
		else if(component.get("v.Line4Header") == 'Medium Header'){
			component.set("v.Line4Header","slds-text-heading_medium");
		}
		else if(component.get("v.Line4Header") == 'Small Header'){
			component.set("v.Line4Header","slds-text-heading_small");
		}
		else if(component.get("v.Line4Header") == 'Plain Text'){
			component.set("v.Line4Header","");
		}
		else if(component.get("v.Line4Header") == 'Colored Text'){
            component.set("v.Line4Header","ListHeader");
        }
        
        if(component.get("v.Line5Header") == 'Large Header'){
			component.set("v.Line5Header","slds-text-heading_large");
		}
		else if(component.get("v.Line5Header") == 'Medium Header'){
			component.set("v.Line5Header","slds-text-heading_medium");
		}
		else if(component.get("v.Line5Header") == 'Small Header'){
			component.set("v.Line5Header","slds-text-heading_small");
		}
		else if(component.get("v.Line5Header") == 'Plain Text'){
			component.set("v.Line5Header","");
		}
        else if(component.get("v.Line5Header") == 'Colored Text'){
            component.set("v.Line5Header","ListHeader");
        }
		
		var action = component.get("c.fetchRecords");
		action.setParams({ 
			ObjectName : component.get("v.ListType"),
			FieldAPI : component.get("v.FieldName"),
			FieldAPI2 : component.get("v.FieldName2"),
            FieldAPI3 : component.get("v.FieldName3"),
            FieldAPI4 : component.get("v.FieldName4"),
            SortByAPI : component.get("v.SortBy"),
            LimitAPI : component.get("v.Limit"),
			RelationshipFieldName : component.get("v.RelatedFieldAPI"),
			RelatedRecordId : component.get("v.recordId"),
            FilterFieldAPI : component.get("v.FilterField"),
            FilterOperatorAPI : component.get("v.FilterOperator"),
            FilterValueAPI : component.get("v.FilterValue"),
            DCFilter : component.get("v.MapDataCategories"),
            DCField : component.get("v.DataCategoryField"),
            CurrentRecId : component.get("v.recordId"),
            LandingObjType : component.get("v.LandingPageObjectType")
		});
		action.setCallback(this,function(response){
			component.set("v.ReturnedRecords",response.getReturnValue().sobjectLists);
            component.set("v.configSetting",response.getReturnValue().communityConfig);
            
            //fetchDataCategory
            var CallCategoryMethod = component.get("v.MapDataCategories");
            var LVURL = component.get("v.ListViewURL");
            
            //alert(CallCategoryMethod);
            if(CallCategoryMethod){
                var action2 = component.get("c.fetchDataCategory");
                action2.setParams({
                    RecordId : component.get("v.recordId"),
                    ObjectName : component.get("v.LandingPageObjectType"),
                    FieldAPI : component.get("v.DataCategoryField")
                }); 
                action2.setCallback(this,function(response2){
                    if(response2.getReturnValue() != null && response2.getReturnValue() != ''){
                        if(LVURL.indexOf("?") != -1){
                            LVURL += '&category='+response2.getReturnValue();
                            component.set("v.ListViewURL",LVURL);
                        }else{
                            LVURL += '?category='+response2.getReturnValue();
                            component.set("v.ListViewURL",LVURL);
                        }
                    }  
                    
                }); 
                $A.enqueueAction(action2);
            }
		});
		$A.enqueueAction(action);
        
	},
    
    gotoMenuURL : function(component, event, helper) {
        helper.gotoURL(component);
    }   
})