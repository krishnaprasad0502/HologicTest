/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Trigger framework for the Product2 object
Test Class:     ProductTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/14/2016      Marc Goldstein      Initial Creation (US1315)
------------------------------------------------------------*/
public with sharing class ProductTriggerActions {
    
    /*------------------------------------------------------------
    Author:         Marc Goldstein
    Company:        Salesforce.com
    Description:    Ensures that when a product is created that a standard pricebook entry is added
    Inputs:         products - The list of Products being created
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    06/14/2016      Marc Goldstein      Initial Creation (US1315)
    ------------------------------------------------------------*/
    public static void createStandardPriceBookEntries(List<Product2> products){ 
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        Id stdId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id From Pricebook2 WHERE IsStandard = true].Id;
    
        for(Product2 p : products){
              pbEntry.add(new PricebookEntry(
                Pricebook2Id = stdId,
                Product2Id = p.ID, 
                UnitPrice = 0.00, 
                IsActive = p.IsActive, 
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD')
            );
            pbEntry.add(new PricebookEntry(
                Pricebook2Id = stdId,
                Product2Id = p.ID, 
                UnitPrice = 0.00, 
                IsActive = p.IsActive, 
                UseStandardPrice = false,
                CurrencyIsoCode = 'CAD')
            );
        }
        insert pbEntry;
    }
    
    /*------------------------------------------------------------
    Author:         Marc Goldstein
    Company:        Salesforce.com
    Description:    Defaults warranty coverage for systems when null
    Inputs:         products - The list of Products being created
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/09/2016      Marc Goldstein      Initial Creation (US1445)
    ------------------------------------------------------------*/
    public static void setDefaultWarrantyCoverage(List<Product2> products){ 
        //Gets default warranty product
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
        Id defaultWarranty;

        if(!String.isBlank(orgDefaults.B_SH_Default_Warranty_ID__c)){
            defaultWarranty = orgDefaults.B_SH_Default_Warranty_ID__c;
                    
            for(Product2 p : products){
                if(p.System__c && p.Warranty_Coverage__c == null){
                    p.Warranty_Coverage__c = defaultWarranty;
                }
            }
        }
    }   

}