({

    doInit : function(component, event, helper) {

        var action = component.get("c.getAddresses");
	    action.setParams({
	        caseId : component.get("v.recordId")
	    });
        
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                
                var results = a.getReturnValue(),
                    billTo = results.Bill_to_Site_Location__r,
                    shipTo = results.Install_Location__r;
                
                var billToName = billTo.Account__r.Parent.Name,
                    billToAddress = billTo.Address_Line_1__c,
                    billToCity = billTo.City__c,
                    billToState = billTo.State__c,
                    billToZip = billTo.Zip_Code__c,
                    billToCountry = billTo.Country__c;
                    
                var shipToName = shipTo.Account__r.Parent.Name,
                    shipToAddress = shipTo.Address_Line_1__c,
                    shipToCity = shipTo.City__c,
                    shipToState = shipTo.State__c,
                    shipToZip = shipTo.Zip_Code__c,
                    shipToCountry = shipTo.Country__c;
                
                if (billTo != undefined) {
                    component.set("v.hasCustomerInfo", true);
                    component.set("v.customerName", billToName);

                    component.set("v.customerAddress", billToAddress);
                    component.set("v.customerCity", billToCity);
                    component.set("v.customerState", billToState);
                    component.set("v.customerZip", billToZip);
                    component.set("v.customerCountry", billToCountry);
                }
                
                if (shipTo != undefined) {
                    component.set("v.hasLocationInfo", true);
                    component.set("v.locationInfo", results.Install_Location__r);

                    component.set("v.locationName", shipToName);
                    component.set("v.locationAddress", shipToAddress);
                    component.set("v.locationCity", shipToCity);
                    component.set("v.locationState", shipToState);
                    component.set("v.locationZip", shipToZip);
                    component.set("v.locationCountry", shipToCountry);
                }
                
                component.set("v.headerSiteName", results.Qualtrics_Customer_Name__c);
                component.set("v.headerName", results.Qualtrics_Contact_First_Name__c + " " + results.Qualtrics_Contact_Last_Name__c);
                component.set("v.headerPhone", results.Qualtrics_Contact_Phone__c);
                component.set("v.headerDate", $A.localizationService.formatDate(results.CreatedDate, "MMMM D, YYYY"));
                component.set("v.headerCaseNumber", results.CaseNumber);
                component.set("v.headerModel", results.Product_Description__c);
                component.set("v.headerSerialNumber", results.Asset_Serial_Number__c);
        		
            } else if (a.getState() === "ERROR") {
                component.set("v.error", a.getError());
                $A.log("Errors", a.getError());
            }
        });

        $A.enqueueAction(action);
    }
})