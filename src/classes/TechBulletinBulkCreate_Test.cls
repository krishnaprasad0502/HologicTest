@isTest
private class TechBulletinBulkCreate_Test {
    
    @isTest
    public static void testCreateWorkOrders(){
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.Status = 'Installed';
        insert asst;
        
        Tech_Bulletin__c tb = new Tech_Bulletin__c();
        tb.Product__c = prod.Id;
        insert tb;
        
        Asset_Tech_Bulletin__c atb = new Asset_Tech_Bulletin__c();
        atb.Asset__c = asst.Id;
        atb.Tech_Bulletin__c = tb.Id;
        insert atb;
        
        //Start test
        Test.startTest();
        
        //Simulate page interaction
        TechBulletinBulkCreate cont = new TechBulletinBulkCreate();
        cont.tbId = tb.Id;
        cont.createType = 'workorder';
        cont.determineCreateType();
        cont.determineCreateType();
        cont.redirect();
        
        //Stop test
        Test.stopTest();
        
        WorkOrder wo;
        //Validate data
        if(atb != null){
	        wo = [
	            SELECT Id
	                  ,Asset_Tech_Bulletin__c
	              FROM WorkOrder
	             WHERE Asset_Tech_Bulletin__c = :atb.Id
	        ];
	        System.assertNotEquals(null, wo);
	        
	        atb = [
	            SELECT Id
	                  ,Work_Order__c
	              FROM Asset_Tech_Bulletin__c
	             WHERE Id = :atb.Id
	        ];
	        System.assertEquals(wo.Id, atb.Work_Order__c);
        }
    }
    
    @isTest
    public static void testCreateAssetTechBulletinsWithSerial(){
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.SerialNumber = '3';
        asst.Status = 'Installed';
        insert asst;
        
        Tech_Bulletin__c tb = new Tech_Bulletin__c();
        tb.Product__c = prod.Id;
        tb.Serial_Number_Start__c = '2';
        tb.Serial_Number_End__c = '4';
        insert tb;
        
        //Start test
        Test.startTest();
        
        //Simulate page interaction
        TechBulletinBulkCreate cont = new TechBulletinBulkCreate();
        cont.tbId = tb.Id;
        cont.createType = 'asset';
        cont.determineCreateType();
        cont.redirect();
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Asset_Tech_Bulletin__c atb = [
            SELECT Id
              FROM Asset_Tech_Bulletin__c
             WHERE Tech_Bulletin__c = :tb.Id
        ];
        System.assertNotEquals(null, atb);
    }
    
    @isTest
    public static void testCreateAssetTechBulletinsWithoutSerial(){
        //Create data
        TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Asset asst = TestUtility.newAsset('Test Asset', acc.Id, acc.Id, prod.Id);
        asst.Status = 'Installed';
        insert asst;
        
        Tech_Bulletin__c tb = new Tech_Bulletin__c();
        tb.Product__c = prod.Id;
        insert tb;
        
        //Start test
        Test.startTest();
        
        //Simulate page interaction
        TechBulletinBulkCreate cont = new TechBulletinBulkCreate();
        cont.tbId = tb.Id;
        cont.createType = 'asset';
        cont.determineCreateType();
        cont.redirect();
        
        //Stop test
        Test.stopTest();
        
        //Validate data
        Asset_Tech_Bulletin__c atb = [
            SELECT Id
              FROM Asset_Tech_Bulletin__c
             WHERE Tech_Bulletin__c = :tb.Id
        ];
        System.assertNotEquals(null, atb);
    }
}