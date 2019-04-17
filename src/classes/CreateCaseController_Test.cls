/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        Apps Associates
Description:    Test class to validate CreateCaseController
                Test Executed:
                CaseWithSelectedContact :Verify that the case is created with the user selected contact from list.
                CaseWithoutSelectedContact : Verify that the contact is created with user entred deatils and the contact
                                             is mapped on case.
                Casewithaccountid : verify that whether the case creation process is handling from Account.
                Casewithduplicatecontact : Verify that whether the contact exists or not with the user ented email for new contact creation
                  .        
History:
<Date>          <Authors Name>          <Brief Description of Change>
05/29/2017       Amarendra Nagireddy     Initial Creation(US-0002746)
05/23/2017       Amarendra Nagireddy     Created new test methods Casewithaccountid,Casewithduplicatecontact to increase code coverage
06/01/2017       Amarendra Nagireddy     utilized TestUtility class to create TriggerSwitch custom setting test records
------------------------------------------------------------*/
@isTest
public class CreateCaseController_Test {
private static Account custAccount;
    private static Account siteAccount;
    private static Account ParentAccount;
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static Configuration_Settings__c orgDefaults;
    static{
        orgDefaults=TestUtility.setupConfigurationSettings();
        //06/01/2017(Amarendra Nagireddy)- create TriggerSwitch custom setting records by using TestUtility.insertCustSetting method
        TestUtility.insertCustSetting('ContactTrigger'); 
        TestUtility.insertCustSetting('CaseTrigger');
        TestUtility.insertCustSetting('ProductReplacement');
        
        
        List<NoteType__c> NoteType_List = new List<NoteType__c>();
        
        NoteType__c NoteType1=new NoteType__c();
        NoteType1.Name = 'Investigation';
        NoteType1.Note_Type__c = 'Investigation';
        NoteType_List.add(NoteType1);
        
        NoteType__c NoteType2=new NoteType__c();
        NoteType2.Name = 'Problem Description';
        NoteType2.Note_Type__c = 'Problem Description';
        NoteType_List.add(NoteType2);
            
        NoteType__c NoteType3=new NoteType__c();
        NoteType3.Name = 'Patient Impact';
        NoteType3.Note_Type__c = 'Patient Impact';
        NoteType_List.add(NoteType3);
        insert NoteType_List;
        
        //insert the customer account details
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
             
        insert new List<Account>{custAccount};
        orgDefaults.Return_Default_Customer_Account__c = custAccount.id;  
        update orgDefaults;
        
        // update org defaults
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';
        //siteAccount.Parentid = ParentAccount.id;
        insert siteAccount;
        //create Contact
        defaultContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', custAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', custAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        //insert product
        products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        insert products;
        //create Asset
        assets = new List<Asset>();
        for(Integer i = 0; i < 10; i++){
            Asset a1=TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
            a1.ContactId= defaultContact.Id;
            assets.add(a1);
            Asset a2= TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
            a2.ContactId= defaultContact.Id;
            assets.add(a2);
         }
        insert assets;
        system.debug('assets======'+assets);
    }
    static testMethod void CaseWithSelectedContact() {
       
        case c=TestUtility.newCase(assets[0].AccountId, defaultContact.id, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Issue', 'New', 'Low', 'Phone');
        c.Patient_Impact__c = 'Yes';
        c.Complaint__c='No';
        //c.CurrencyIsoCode='';
        c.System_Status__c='Down';
       // c.Subject='testsubject';
        date d=date.newInstance(1960, 2, 17);
        c.Incident_Date__c=d;
        //insert c;
        Test.startTest();
        PageReference pageRef = Page.CreateCaseOnAsset;
        pageRef.getParameters().put('aId', assets[0].id);
        pageRef.getParameters().put('aId','Asset');
        pageRef.getParameters().put('firstname', 'testfirstname');
        pageRef.getParameters().put('lastname', 'testlastname');
        pageRef.getParameters().put('accountName', 'accountName');
        pageRef.getParameters().put('customeraccount', 'customeraccount');
        pageRef.getParameters().put('email', 'email');
        pageRef.getParameters().put('phone', 'phone');
        pageRef.getParameters().put('extension', 'extension');
        pageRef.getParameters().put('extension', 'role');
        pageRef.getParameters().put('clearPagination', 'true');
        
        Test.setCurrentPage(pageRef);
         
        CreateCaseController createCaseOnAsset=new CreateCaseController();
        string getassetid=ApexPages.currentPage().getParameters().get('aId');
        createCaseOnAsset.selectedCaseType=null;
        createCaseOnAsset.newCase=c;
        createCaseOnAsset.selectedContact=defaultContact.id;
        createCaseOnAsset.runSearch();
        CreateCaseController.wrapperTaskList waTaskList=new CreateCaseController.wrapperTaskList();
        string email='test@testemail.com';
        CreateCaseController.validateEmail(email);
        createCaseOnAsset.getnewCase();
        createCaseOnAsset.setnewCase(c);
        createCaseOnAsset.setCaseComplaint();
        createCaseOnAsset.createRecords();
        createCaseOnAsset.getTotalContact();
        createCaseOnAsset.getPagination();
        Integer pagination=0;
        createCaseOnAsset.setPagination(pagination);
        createCaseOnAsset.runQuery();
        createCaseOnAsset.Cancel();
        createCaseOnAsset.addNewRowToTaskList();
       // createCaseOnAsset.removeRowFromTaskList();
        createCaseOnAsset.setSelectedContact();
        //createCaseOnAsset.testCheckBox();
        createCaseOnAsset.setNext();
        createCaseOnAsset.setPrevious();
        createCaseOnAsset.toggleSort();
        createCaseOnAsset.rowToRemove=1;
        createCaseOnAsset.removeRowFromTaskList();
        createCaseOnAsset.clearselectedcontact();
        //createcaseOnAsset.debugSoql=null;
        system.assertEquals(CreateCaseController.validateEmail(email) , true);
        system.assertEquals(c.ContactId, defaultContact.id);
        Test.stopTest();
    }
    static testMethod void CaseWithoutSelectedContact() {
        Test.startTest();
         PageReference pageRef = Page.CreateCaseOnAsset;
        pageRef.getParameters().put('aId', assets[0].id);
        pageRef.getParameters().put('Objname', 'Asset');
        pageRef.getParameters().put('firstname', 'firstname');
        pageRef.getParameters().put('lastname', 'lastname');
        pageRef.getParameters().put('accountName', 'accountName');
        
        pageRef.getParameters().put('email', 'email');
        pageRef.getParameters().put('customeraccount', 'customeraccount');
        pageRef.getParameters().put('phone', 'phone');
        pageRef.getParameters().put('extension', 'extension');
        pageRef.getParameters().put('extension', 'role');
        Test.setCurrentPage(pageRef);
        CreateCaseController CreateCase=new CreateCaseController();
        //createCaseOnAsset.selectedCaseType=null;
        CreateCase.selectedContact=null;
        CreateCase.runSearch();
        CreateCase.createRecords();
        system.assertEquals(null, CreateCase.selectedContact);
        Test.stopTest();
       }
     //5/23/2017(Amarendra Nagireddy)-Created new test method to cover handling Account id,while creating case from account
       static testMethod void Casewithaccountid() {
        Test.startTest();
         PageReference pageRef = Page.CreateCaseOnAsset;
         pageRef.getParameters().put('aId', custAccount.id);
         pageRef.getParameters().put('Objname', 'Account');
        pageRef.getParameters().put('firstname', 'firstname');
        pageRef.getParameters().put('lastname', 'lastname');
        pageRef.getParameters().put('accountName', 'accountName');
        pageRef.getParameters().put('customeraccount', 'customeraccount');
        pageRef.getParameters().put('email', 'email');
        pageRef.getParameters().put('phone', 'phone');
        pageRef.getParameters().put('extension', 'extension');
        pageRef.getParameters().put('extension', 'role');
         Test.setCurrentPage(pageRef);
         CreateCaseController CreateCase=new CreateCaseController();
         string email='testtestemailcom';
         CreateCaseController.validateEmail(email);
         CreateCase.runSearch();
        CreateCase.createRecords();
       Test.stopTest();
       }
    //5/24/2017(Amarendra Nagireddy)-Created new test method to cover if user doesn't select existing contact and try to create new contact with same email
       static testMethod void Casewithduplicatecontact() {
         Contact defaultContact1 = TestUtility.newContact('Default', 'Contact', custAccount.Id);
         defaultContact1.Email='test@testduplicateemail.com';
         Contact defaultContact2 = TestUtility.newContact('testfirstname', 'testlastname', custAccount.Id);
         defaultContact2.Email='test@testduplicateemail.com';  
         id nullaccount;
         Asset newasset=TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
           newasset.ContactId = defaultContact.id;
          Test.startTest();
           insert defaultContact1;
           insert defaultContact2;
           insert newasset;
        PageReference pageRef = Page.CreateCaseOnAsset;
        pageRef.getParameters().put('aId', newasset.id);
        pageRef.getParameters().put('Objname', 'Asset');
        pageRef.getParameters().put('firstname', 'testfirstname');
        pageRef.getParameters().put('lastname', 'testlastname');
        pageRef.getParameters().put('accountName', 'testaccountName');
        pageRef.getParameters().put('customeraccount', 'testcustomeraccount');
        pageRef.getParameters().put('email', 'test@testduplicateemail.com');
        pageRef.getParameters().put('phone', 'testphone');
        pageRef.getParameters().put('extension', 'testextension');
        pageRef.getParameters().put('extension', 'testrole');
        Test.setCurrentPage(pageRef);
         CreateCaseController CreateCase=new CreateCaseController();
         CreateCase.runSearch();
         CreateCase.createRecords();
         
       Test.stopTest();
       }
    
    
}