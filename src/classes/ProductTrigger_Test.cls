/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Test class to validate ProductTrigger
                Tests Excecuted:

                testPBEntryCreation - verify that on insert of a product, that a standard pricebook entry is created
History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2016      Marc Goldstein      Added attachSOLI test case (US1315)
------------------------------------------------------------*/

@isTest
private class ProductTrigger_Test {
    
    
    static testMethod void testPBEntryCreation() {
        
        List<Product2> prodList = new List<Product2>();
    
        TestUtility.setupConfigurationSettings();   
        String prodName='';

        Id pricebookId = Test.getStandardPricebookId();


        for(Integer i=0; i<200; i++){
            prodName = 'Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true));
        }
        
        
            insert prodList;
        Test.startTest();
        
        
        Integer intCnt=0;
        for(PricebookEntry pbe : [Select Id,Name from PricebookEntry]){
            intCnt++;
        }
        System.assertEquals(400, intCnt);
        Test.stopTest();
    }

    static testMethod void testDefaultWarranty() {
        
        
        List<Product2> prodList = new List<Product2>();
    
        TestUtility.setupConfigurationSettings();   
        String prodName='';

        Id pricebookId = Test.getStandardPricebookId();


        
        Product2 warProd = new Product2(Name = 'Warranty', ProductCode='Warranty', IsActive = true);

        insert warProd;

        Configuration_Settings__c orgDef = Configuration_Settings__c.getOrgDefaults();
        orgDef.B_SH_Default_Warranty_ID__c=warProd.Id;
        update orgDef;



        for(Integer i=0; i<200; i++){
            prodName = 'Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, System__c=true));
        }
        
        insert prodList;
        
        Test.startTest();
            Id warrantyID = warProd.Id;

            for(Product2 prods : [select warranty_coverage__c from product2 where productcode!='Warranty']){    
                System.assertEquals(prods.warranty_coverage__c, warrantyID);
            }
            
        Test.stopTest();
    }
    
}