/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: Test Class for SubmitNewCaseController class
Controller Class: SubmitNewCaseController

History:
<Date>              <Author Name>        <Brief description of change>      	<Copa.do US#>
18/09/2018          Vrushabh Kataria     Initial creation                  	 	US-0005701
02/11/2018          Nomita Walke         Updated testFetchUserAccount()    	 	US-0006062
18/12/2018          Vrushabh Katariya   Schedule PM Future and Historic data    US-0006345
01/21/2019			Vrushabh Katariya	Code change for Disposable Product 		US-0006553
****************************************************************************/
@isTest
public class SubmitNewCaseController_Test {
    
    @testsetup
    static void testSetup(){
        
        TestUtility.setupConfigurationSettings();
        Account testAccount = TestUtility.newAccount('TestAccount', 'TestAccount1');
        database.insert(testAccount) ;
        
        Contact cont = new Contact();
        cont.FirstName='testContact';
        cont.LastName='ContactLastName';
        cont.Phone= '+1-9009191923';
        cont.Accountid= testAccount.id;
        database.insert(cont);
        
        Profile p = [SELECT Id FROM Profile WHERE Name=: Label.Community_Profile_Name]; 
        User u = new User(Alias = 'testUser', Email='currentuser@test.com', 
                          EmailEncodingKey='UTF-8', FirstName='FirstName',LastName='LastName', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='currentuser@test.com', ContactId=cont.Id);
        database.insert(u);
    }
    
    /*Test method to test fucntionality of controller method -"fetchUser()"*/
    @isTest
    static void testFetchUser(){
        List<Asset> AssetList =  SubmitNewCaseController.fetchLookUpValues('', 'Asset');
        AssetList =  SubmitNewCaseController.fetchLookUpValues('QRNT', 'Asset');
        
        Test.startTest();
        User u = SubmitNewCaseController.fetchUser();
        system.assertEquals(u.Id,UserInfo.getUserID());
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchLookUpValues()"*/
    @isTest
    static void testFetchLookUpValues(){
        Product2 prod = new Product2(Name = 'TestProd',Community_Visible__c = True);
        database.insert(prod);
        Test.startTest();
        List<Product2> ProductList =  SubmitNewCaseController.fetchLookUpValues('sdm', 'Product2');
        ProductList =  SubmitNewCaseController.fetchLookUpValues('', 'Product2');
        system.assertEquals(True,ProductList[0].Community_Visible__c);
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchAssetRecord()"*/
    @isTest
    static void testFetchAssetRecord(){
        
        Test.startTest();
        
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        Asset AssetRec= SubmitNewCaseController.fetchAssetRecord(newAsset.Id);
        system.assertequals('Test Asset',AssetRec.Name); 
        
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchAssetProduct()"*/
    @isTest
    static void testFetchAssetProduct(){
        
        Test.startTest();
        
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Product2 prod = new Product2(Name = 'TestProd');
        database.insert(prod);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id,product2Id=prod.Id);
        database.insert(newAsset);
        Product2 ProductRec= SubmitNewCaseController.fetchAssetProduct(newAsset.Id);
        system.assertEquals(ProductRec.Name,'TestProd');
        
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"GetSelectOptions()"*/
    @isTest
    static void testGetSelectOptions(){
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Test.startTest();
        List <String> plicklistVal = SubmitNewCaseController.getselectOptions(TestC, 'Priority');
        system.assertequals('NA',plicklistVal[0]);
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"GetSelectOptions()"*/
    @isTest
    static void testGetselectOptions1(){
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 2');
        database.insert(TestC);
        Test.startTest();
        List <String> plicklistVal = SubmitNewCaseController.getselectOptions(TestC, 'Status');
        Boolean result = plicklistVal.contains('Open');
        System.assertEquals(true, result);
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"fetchUserContact()"*/
    @isTest
    static void testFetchUserContact(){
        
        account newAcc = [Select Id, Name from Account where Name = 'testAccount'];
        contact newCon = [Select Id, Name,FirstName from Contact where FirstName = 'testContact'];
        User u =  [Select Id,Name from User where firstname ='FirstName'];
        System.runAs (u) 
        { 
            test.startTest();
            Contact newContact = SubmitNewCaseController.fetchUserContact();
            test.stopTest();
            System.assertEquals(newCon.Id, newContact.Id);
        }
        
    }
    
    /*Test method to test fucntionality of controller method -"fetchUserAccount()"*/
    @isTest
    static void testFetchUserAccount(){
        
        account newAcc = [Select Id, Name from Account where Name = 'testAccount'];
        contact newCon = [Select Id, Name from Contact where FirstName = 'testContact'];
        User u =  [Select Id,Name from User where firstname ='FirstName'];
        System.runAs (u) 
        { 
            test.startTest();
            Account newAcc1 = SubmitNewCaseController.fetchUserAccount();
            test.stopTest();
            System.assertEquals('TestAccount', newAcc1.Name);
            SubmitNewCaseController.fetchConfigData();
        }
        
    }
    
    /*Test method to test fucntionality of controller method -"fetchProductRecord()"*/
    @isTest
    static void testFetchProductRecord(){
        User UName =  [Select Id,Name from User where firstname ='FirstName'];
        Test.startTest();
        system.runAs(UName){ 
            Product2 prod = new Product2(Name = 'TestProd');
            database.insert(prod);
            Product2 ProductRec= SubmitNewCaseController.fetchProductRecord(prod.Id);
            system.assertEquals(ProductRec.Name,'TestProd');
        }
        Test.stopTest();
    }
    
    /*Test method to test fucntionality of controller method -"AssignCase()"*/
    @isTest
    static void testAssignCase(){
        User UName =  [Select Id,Name from User where firstname ='FirstName'];
        Test.startTest();
        system.runAs(UName){ 
            Case c = new Case(Subject = 'Test', Priority = 'Medium');
            database.insert(c);
            String CaseRec= SubmitNewCaseController.AssignCase(c.Id);
            system.assertEquals(CaseRec,c.Id);
        }
        Test.stopTest();
    }
    
    
    static testMethod void testCaseCommentsCreation(){
        account newAcc = [Select Id, Name from Account where Name = 'testAccount'];
        contact newCon = [Select Id, Name from Contact where FirstName = 'testContact'];
        User U =  [Select Id,Name from User where firstname ='FirstName'];
        System.runAs (u) 
        { 
            test.startTest();
            Case c = new Case(Subject = 'Test', Priority = 'Medium');
            database.insert(c);
            SubmitNewCaseController.insertCaseComments('test QA1','test QA2','test QA3',c.Id);
            
            Account newAcc1 = SubmitNewCaseController.fetchUserAccount();
            test.stopTest();
            System.assertEquals('TestAccount', newAcc1.Name);
        }
    }
    
    /*Test method to test CreateServiceRequest method*/
    @isTest
    static void testCreateServiceRequest(){
        
        Test.startTest();
        
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        Asset AssetRec= SubmitNewCaseController.fetchAssetRecord(newAsset.Id);
        system.assertequals('Test Asset',AssetRec.Name); 
        
        SubmitNewCaseController.createCase('Sev2','Web','PM','Web','Test Subject','Test desc','',AssetRec.Id,AssetRec.accountId,AssetRec.accountId,'9090909090');
        SubmitNewCaseController.createCase('Sev2','Web','PM','Web','Test Subject','Test desc','',AssetRec.Id,AssetRec.accountId,'','9090909090');
        SubmitNewCaseController.insertServiceRequestComments(true,'Test QA 1','Test QA 2','Test QA 3',TestC.Id,'Web');
        
        Test.stopTest();
    }
    
    /* Schedule PM Future and Historic data US-0006345 */
    /*Test method to test fetchServiceAppointment method*/
    @isTest
    static void testfetchServiceAppointment(){
        Test.startTest();
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        SubmitNewCaseController.fetchServiceAppointment('ServiceAppointment','CommunitySAFieldsOnSchedulePM',newAsset.Id);
        
        system.assertequals('Test Asset',newAsset.Name); 
        
        Test.stopTest();
    }
    
    /*Test method to test createDisposableCase method*/
    @isTest
    static void testcreateDisposableCase(){
        
        Test.startTest();
        
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Product2 prod = new Product2(Name = 'TestProd',Community_Visible__c = True);
        database.insert(prod);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        Asset AssetRec= SubmitNewCaseController.fetchAssetRecord(newAsset.Id);
        system.assertequals('Test Asset',AssetRec.Name); 
        
        SubmitNewCaseController.createDisposableCase('Sev2','Web','PM','Web','Test Subject',prod.Id,AssetRec.accountId,'1324156','description');
        
        Test.stopTest();
    }
    
    /*Test method to test createDisposableCase method*/
    @isTest
    static void testinsertDisposableCaseComments(){
        
        Test.startTest();
        
        Account newAcc = new Account(Name = 'TestAccount');
        database.insert(newAcc);
        Product2 prod = new Product2(Name = 'TestProd',Community_Visible__c = True);
        database.insert(prod);
        Case TestC = new Case(Subject='Test Controller Acct Case', Priority='Sev 1');
        database.insert(TestC);
        Asset newAsset = new Asset(Name = 'Test Asset',SerialNumber = 'QUREWOFFN',accountId=newAcc.Id);
        database.insert(newAsset);
        Asset AssetRec= SubmitNewCaseController.fetchAssetRecord(newAsset.Id);
        system.assertequals('Test Asset',AssetRec.Name); 
        
        SubmitNewCaseController.insertDisposableCaseComments('description',TestC.Id);
        
        Test.stopTest();
    }
    /* Schedule PM Future and Historic data US-0006345 */
    /*Test method to test fetchTimeframe method*/
    @isTest
    static void testfetchTimeframe(){
        Test.startTest();
        SubmitNewCaseController.DateResult result = new SubmitNewCaseController.DateResult();
        result = SubmitNewCaseController.fetchTimeframe();
        system.assertequals(result.CurrentDate,date.today()); 
        Test.stopTest();
    }
    
    
}