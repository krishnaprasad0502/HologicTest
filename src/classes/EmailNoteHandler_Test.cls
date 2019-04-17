/*------------------------------------------------------------
Author:      Yogi
Company:    
Description:  Test Class for EmailNoteHandler
Test Cases:
- attachNoteToCase : Attach a note to case with multiple attachments
- attachNoteToWO : Attach a note to WO with multiple attachments
- attachNoteInvalidObject : Test the error handling where invalid object was specificed in Email subject
- attachNoteMissingCase : Test the error handling where invalid case number was specified
- attachNoteMissingWO : Test the error handling where invalid WO number was specified
- invalidSubject : Test the error when invalid subject was specified

History:
<Date>      <Authors Name>    <Brief Description of Change>
06/12/2017    Yogi      Initial Creation 
07/17/2017    Yogi      Updated to include test for EmailMessage on case
20/1/2018       KRISHNA PRASAD       CREATE RECORD EMIAL COMMUNITION OBJECT
------------------------------------------------------------*/
@isTest
public class EmailNoteHandler_Test {
    private static Configuration_Settings__c orgDefaults;
    private static Record_Type_IDs__c rtIds;
    private static Account custAccount;
    private static Account siteAccount;
    private static Account houseAccount;
    private static Account internalAcc;
    private static Account internalSiteAcc;
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static List<Case> cases = new List<Case>();
    private static List<Case> serviceCases = new List<Case>();
    private static List<Case> installCases = new List<Case>();
    private static User sysAdminUser;  
    private static Pricebook2 pricebook;
    private static Pricebook2 internalPricebook;
    
    private static Coverage_Group__c coverageGroup;
    private static List<Coverage_Template__c> coverageTemplates;
    private static List<Entitlement> workorderEntitlements;
    private static Map<Id, List<Entitlement>> assetToEntitlement;
    
    static{
        orgDefaults = TestUtility.setupConfigurationSettings();
        rtIds = TestUtility.setupRecordTypeIds();
         // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue  
        TestUtility.insertCustSetting('CaseTrigger'); 
        TestUtility.insertCustSetting('WorkOrderTrigger');   
        TestUtility.insertCustSetting('EmailCommunicationTrigger'); 
        
        // insert pricebooks
        pricebook = TestUtility.newPricebook('Test Pricebook');
        internalPricebook = TestUtility.newPricebook('Test Internal Pricebook');
        insert new List<Pricebook2> {pricebook, internalPricebook}; 
            
            // insert an account
        houseAccount = TestUtility.newAccount('House Account', 'houseAcc', 'Holgoic Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        custAccount.BillingCountryCode = 'US';
        custAccount.BillingStateCode = 'NY';        
        insert new List<Account>{custAccount, houseAccount};
            
            // update org defaults
            //orgDefaults.Default_B_SH_Parts_Pricebook2Id__c = pricebook.Id;
        //orgDefaults.Default_B_SH_Service_Pricebook2Id__c = internalPricebook.Id;
        orgDefaults.Default_B_SH_House_AccountId__c = houseAccount.Oracle_Party_Id__c;
        update orgDefaults;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', custAccount.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';            
        insert siteAccount;
        
        internalAcc = TestUtility.newAccount('Test Internal Account','1054');
        insert internalAcc;
        
        internalSiteAcc = TestUtility.newAccount('Site Account1', 'testSite1', 'ABC Street1', internalAcc.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        internalSiteAcc.BillingCountryCode = 'US';
        internalSiteAcc.BillingStateCode = 'NY';            
        insert internalSiteAcc;
        
        defaultContact = TestUtility.newContact('Default', 'Contact', custAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', custAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', custAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
            
        products = new List<Product2>();
        products.add(TestUtility.newProduct('Product 01'));
        products.add(TestUtility.newProduct('Product 02'));
        insert products;
        
        assets = new List<Asset>();
        for(Integer i = 0; i < 15; i++){
            Asset sys1 = TestUtility.newAsset(siteAccount.Name + ' Asset 01', siteAccount.Id, custAccount.Id, products[0].Id);
            sys1.ContactId = defaultContact.Id; 
            Asset sys2 = TestUtility.newAsset(siteAccount.Name + ' Asset 02', siteAccount.Id, custAccount.Id, products[1].Id);
            sys2.ContactId = defaultContact.Id;
            assets.add(sys1);
            assets.add(sys2);
        }
        
        Asset sys3 = TestUtility.newAsset(internalSiteAcc.Name + 'Asset internal', internalSiteAcc.Id, internalAcc.Id, products[0].Id);
        sys3.ContactId = defaultContact.Id;
        assets.add(sys3);
        insert assets;
        
        sysAdminUser = TestUtility.newUser([Select Id From Profile Where Name = 'System Administrator' Limit 1].Id,'tstadmin');        
        insert sysAdminUser;
        Case newCase = TestUtility.newCase(siteAccount.Id, null, assets[0].Id, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Applications'), 'Combo', 'New', 'Low', 'Phone');
        newCase.Bill_to_Customer__c = custAccount.Id;
        newCase.Customer_Name__c = custAccount.Id;        
        cases.add(newCase);
       insert cases;
     
        System.debug('cases: ' + cases);
  String caseNum1 = [select casenumber from case where Id =:cases[0].ID][0].casenumber;
        System.debug('cases: ' + caseNum1);

       
    }
    

    //Attach a note to case with multiple attachments
    static testMethod void   attachNoteToCase(){
        String caseNum = [select casenumber from case where Id =:cases[0].ID][0].casenumber;
        system.debug('CaseNumValue' + casenum );
        Test.startTest();
            createAndSendEmail('[case:' + caseNum + '] a Case Subject', 'Test Email Body');
        Test.stopTest();

        //check activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :cases[0].Id];

        System.assertEquals(1, taskList.size());
        System.assertEquals('Inbound Email: [case:' + caseNum + '] a Case Subject', taskList[0].Subject);
        System.assertEquals('Test Email Body', taskList[0].Description);
        System.assertEquals('Email', taskList[0].Type);

        //Check EmailMessage
        List<EmailMessage> emList = [select Id, ParentId, Subject from EmailMessage where ParentId = :cases[0].Id];
        System.assertEquals(1, emList.size());
        System.assertEquals('[case:' + caseNum + '] a Case Subject', emList[0].subject);
        
        //check attachments
        List<attachment> attachmentList = [select Id, Name, ParentId from attachment where ParentId = :emList[0].Id];
        //System.assertEquals(2, attachmentList.size());
        //System.assertEquals('textfile.txt', attachmentList[0].Name);       
      
    } 
    
    //Attach a note to WO with attachments
    static testMethod void attachNoteToWO(){

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        system.debug('WorkOrderList**' + workOrderList);
        
        for(Case c : cases){
            
            workOrderList.add(TestUtility.newWorkOrder(siteAccount.Id, c.Id, assets[0].Id, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'New'));
        }
        
        Test.startTest();
        insert workOrderList;
        
       
        String WONum = [select WorkOrderNumber from WorkOrder where Id = :workOrderList[0].ID][0].WorkOrderNumber;
        
        createAndSendEmail('[wo:' + WONum + '] a WO Subject', 'Test Email Body');
        Test.stopTest();

        //check activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :workOrderList[0].Id];

        System.assertEquals(1, taskList.size());
        System.assertEquals('Inbound Email: [wo:' + WONum + '] a WO Subject', taskList[0].Subject);
        System.assertEquals('Test Email Body', taskList[0].Description);
        System.assertEquals('Email', taskList[0].Type);

        //check attachments
        List<attachment> attachmentList = [select Id, Name, ParentId from attachment where ParentId = :taskList[0].Id];
        //System.assertEquals(2, attachmentList.size());
        //System.assertEquals('textfile.txt', attachmentList[0].Name);
    }
      
    //Test the error handling where invalid object was specificed in Email subject
    static testMethod void attachNoteInvalidObject(){

        Test.startTest();
       
        createAndSendEmail('[ :' + 123 + '] a Case Subject', 'Test Email Body');
       
        
        Test.stopTest();

        //check no activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :cases[0].Id];

        System.assertEquals(0, taskList.size());
        
    }
     
    //Test the error handling where invalid case number was specified
    static testMethod void attachNoteMissingCase(){
        
        Test.startTest();
   
       
        createAndSendEmail('[case:' + 123 + '] a Case Subject', 'Test Email Body');
      
       
       
        Test.stopTest();

        //check no activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :cases[0].Id];

        System.assertEquals(0, taskList.size());
        
    }
     
    //Test the error handling where invalid WO number was specified
    static testMethod void attachNoteMissingWO(){

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        
        Test.startTest();

        for(Case c : cases){
            workOrderList.add(TestUtility.newWorkOrder(siteAccount.Id, c.Id, assets[0].Id, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'New'));
        }

        insert workOrderList;
        String WONum = [select WorkOrderNumber from WorkOrder where Id = :workOrderList[0].ID][0].Id;
        
        createAndSendEmail('[wo:' + 123 + '] a WO Subject', 'Test Email Body');
        
        
        Test.stopTest();

        //check no activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :workOrderList[0].Id];

        System.assertEquals(0, taskList.size());
        
    }
    
    //Test the error handling where invalid Subject was spefied
    static testMethod void invalidSubject(){

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        
        Test.startTest();

        for(Case c : cases){
            workOrderList.add(TestUtility.newWorkOrder(siteAccount.Id, c.Id, assets[0].Id, GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_FE_Install_Upgrade_Move'), 'new'));
        }

        insert workOrderList;
        String WONum = [select WorkOrderNumber from WorkOrder where Id = :workOrderList[0].ID][0].Id;
       
        
            createAndSendEmail('[wo' + 123 + '] a WO Subject', 'Test Email Body'); // missing ':' in subject ->invalid
       
        Test.stopTest();

        //check no activity got created
        List<Task> taskList = [select Id, WhatId, Subject, Type, Status, Description from Task where WhatId = :workOrderList[0].Id];

        System.assertEquals(0, taskList.size());
        
    }
    //Common method to create and send email to the Email handler
    private static void createAndSendEmail(String subject, String body){
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.Header header= new Messaging.InboundEmail.Header();
         
        email.headers=new Messaging.InboundEmail.Header[1];
        header.name='Date'; header.value='Tue, 28 Apr 2009 14:08:37 -0700';
        
        // setup the data for the email
        email.subject = subject;
        email.plainTextBody = body;
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
        email.fromAddress = 'someaddress@email.com';
        email.ccAddresses = new List<String>{'someaddress2@hologic.com'};
        email.htmlbody='Hello';
        email.headers[0]=header;
        
    
        
      
        // add a binary attachment
       Messaging.InboundEmail.BinaryAttachment battachment = new Messaging.InboundEmail.BinaryAttachment();
          battachment.body = blob.valueOf('my attachment text');
          battachment.fileName = 'textfile.txt';
          battachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { battachment };
        
        // add a binary attachment
        Messaging.InboundEmail.TextAttachment tattachment = new Messaging.InboundEmail.TextAttachment();
        tattachment.body = 'my attachment text';
        tattachment.fileName = 'textfile.txt';
        tattachment.mimeTypeSubType = 'text/plain';
        system.debug('**EmailValues**' + email);
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { tattachment };  
            
        // call the email service class and test it with the data in the testMethod
        EmailNoteHandler emailProcess = new EmailNoteHandler();
        emailProcess.handleInboundEmail(email, env);
    
    }
    
}