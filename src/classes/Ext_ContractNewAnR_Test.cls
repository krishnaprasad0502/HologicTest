/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Class which supports the VFPage 'ContractNewAmmendopp' and 'CreatePA_Opp'.

History:
<Date>          <Authors Name>         <Brief Description of Change>
12/13/2017      Kasmoor Reddy          Initial Creation (US3566)
01/08/2018      Mani Sundaresan        Validate logic to create Amended quote when invoked from Opportunity related to Diagnostic Lab Open opporunity (US-0003784)
----------------------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class Ext_ContractNewAnR_Test {
    static{
        // insert configuration settings
        TestUtility.setupConfigurationSettings();
        
        //TestUtility.insertCustSetting('OpportunityTrigger');
        //TestUtility.insertCustSetting('ProductTrigger');
        
         
          
    }

    
    static testMethod void testCreateCECs(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        //User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        // insert user
        User u = new User(Alias = 'standt', Email='standarduser1z@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Administrator',FirstName='Salesforce',LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1z@testorg.com');
            insert u;
            
        //Creating Diagnostics Opportunity RecordType Id custom settings
        Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
        insert diagRTIds;
        
        System.runAs(u){
    
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger');  

            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Perinatal_Open_Opportunity')).substring(0,15));
            opp.Revenue_Class__c = 'New Customer';
            opp.Install_Date__c = system.today();
            opp.Type = 'Amendment';
            insert opp;
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;

             
            Test.startTest();
            //create contract          
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Division__c = 'Surgical',Contract_End_Date__c = Date.Today().addDays(-1));
            insert contract;
            List<Opportunity> lst_opp = new List<Opportunity>();
            lst_opp.add(opp);
            List<Contract> lst_con = new List<Contract>();
            lst_con.add(contract);
            
            // test creating a contract
            Map<String, String> contractMap = OpportunityTriggerHandler.createContract(lst_opp);
            //System.assertNotEquals(contractMap, null);

            //test creating agreed prices
            OpportunityTriggerHandler.createAgreementPrices(lst_con);
            
            
            //test amending a price agreeement
            opp.SBQQ__AmendedContract__c=contract.id;
            update opp;
            

            //Update Opportunity to Set Pricing Agreement to False and Run Test
            contract.Automatic_Renewal__c = false;
            contract.SBQQ__Quote__c = quote.id;
            //contract.One_Time_Renewal__c = true;
            update contract;
            
            
            //US-0002330- Test VF Page for related account output, setup page and parameters to test RelatedAccounts VF Page
            PageReference pageRef2 = Page.RelatedAccountsOutput;
            PageRef2.getParameters().put('qid',quote.Id);
            Test.setCurrentPage(pageRef2);
            RelatedAccountsController rlController = new RelatedAccountsController();
            system.assertNotEquals(rlController.cecs, null);

            // create controller renewal            
            contract.status = 'Activated';
            update contract;
            
            
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();

            // create controller amendment
            PageReference pageRef3 = Page.ContractNewAmendOpp;
            PageRef3.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef3);
            ApexPages.standardController amendController = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerAmendment = new Ext_ContractNewAnR(amendController);
            
            contractControllerAmendment.quoteId = quote.Id;
            contractControllerAmendment.opp = opp;
            Contract testAmendmentContract = contractControllerAmendment.returnContract();
            contractControllerAmendment.RunThat();
            contractControllerAmendment.gotoQuote();
            contractControllerAmendment.gotoOpp();
            //Update Opportunity to Set Pricing Agreement to True and Run Test
            contract.Automatic_Renewal__c = true;
            //contract.One_Time_Renewal__c = false;
            update contract;
            opp.Pricing_Agreement_Created__c = True;
            update opp;
            Test.stopTest();
               
        }
    }
    
    static testMethod void testCreateCECs3(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Surgical Sales User'];
        
        //User u = [SELECT Id from User where profileid = : p.id and Isactive = true limit 1];
        //insert user
        User u = new User(Alias = 'standt', Email='standarduser4z@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Administrator',LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser4z@testorg.com',Isactive = true);
            insert u;
            
        //Creating Diagnostics Opportunity RecordType Id custom settings
        Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
        insert diagRTIds;
        
        System.runAs(u){
    
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger'); 

            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
            insert opp;
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__SubscriptionTerm__c = 10;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;

            
            Test.startTest();
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Contract_End_Date__c = Date.Today().addDays(-1),Division__c = 'BSH');
            insert contract;
            
            
            List<Opportunity> lst_opp = new List<Opportunity>();
            lst_opp.add(opp);
            List<Contract> lst_con = new List<Contract>();
            lst_con.add(contract);
            
            //US-0002330- Test VF Page for related account output, setup page and parameters to test RelatedAccounts VF Page
            PageReference pageRef2 = Page.RelatedAccountsOutput;
            PageRef2.getParameters().put('qid',quote.Id);
            Test.setCurrentPage(pageRef2);
            RelatedAccountsController rlController = new RelatedAccountsController();
            system.assertNotEquals(rlController.cecs, null);

            // create controller renewal            
            contract.status = 'Activated';
            update contract;
            PageReference pageRef = Page.ContractNewAmendOpp;
            PageRef.getParameters().put('type','Renewal');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();

            // create controller amendment
            /*PageReference pageRef3 = Page.ContractNewAmendOpp;
            PageRef3.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef3);*/
            ApexPages.standardController amendController = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerAmendment = new Ext_ContractNewAnR(amendController);
            
            contractControllerAmendment.quoteId = quote.Id;
            contractControllerAmendment.opp = opp;
            Contract testAmendmentContract = contractControllerAmendment.returnContract();
            contractControllerAmendment.RunThat();
            contractControllerAmendment.gotoQuote();
            contractControllerAmendment.gotoOpp();
            Test.stopTest();
            
        }
    }
    
    static testMethod void testCreateCECs2(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        //User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        //create user
        User u = new User(Alias = 'standt', Email='standarduser1z@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Administrator',FirstName='Salesforce',LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1z@testorg.com');
            insert u;
            
        //Creating Diagnostics Opportunity RecordType Id custom settings
        Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
        insert diagRTIds;
        
        System.runAs(u){
        
            //Creating Diagnostics Opportunity RecordType Id custom settings
            //Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF'
                                                                                                            //,Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
        
            //insert diagRTIds;
    
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger'); 

            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
            insert opp;
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__SubscriptionTerm__c = 10;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;

            
            Test.startTest();
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Division__c = 'Diagnostics',Contract_End_Date__c = Date.Today().addDays(-1));
            insert contract;
            
            Contract contract1 = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Division__c = '',Contract_End_Date__c = Date.Today().addDays(-1));
            insert contract1;
            
            

            List<Opportunity> lst_opp = new List<Opportunity>();
            lst_opp.add(opp);
            List<Contract> lst_con = new List<Contract>();
            lst_con.add(contract);
            
             //US-0002330- Test VF Page for related account output, setup page and parameters to test RelatedAccounts VF Page
            PageReference pageRef2 = Page.RelatedAccountsOutput;
            PageRef2.getParameters().put('qid',quote.Id);
            Test.setCurrentPage(pageRef2);
            RelatedAccountsController rlController = new RelatedAccountsController();
            system.assertNotEquals(rlController.cecs, null);

            // create controller renewal            
            contract.status = 'Activated';
            update contract;
           
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();

            // create controller amendment
            PageReference pageRef3 = Page.ContractNewAmendOpp;
            PageRef3.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef3);
            ApexPages.standardController amendController = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerAmendment = new Ext_ContractNewAnR(amendController);
            
            contractControllerAmendment.quoteId = quote.Id;
            contractControllerAmendment.opp = opp;
            Contract testAmendmentContract = contractControllerAmendment.returnContract();
            contractControllerAmendment.RunThat();
            contractControllerAmendment.gotoQuote();
            contractControllerAmendment.gotoOpp();
            
            
            Test.stopTest();
            
        }
    }
    
   /* static testMethod void testCreateCECs1(){
    
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        //User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        //insert user
        User u = new User(Alias = 'standt', Email='standarduser1z@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Administrator',FirstName='Salesforce',LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1z@testorg.com');
            insert u;
            
        //Creating Diagnostics Opportunity RecordType Id custom settings
        Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
        insert diagRTIds;
        
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ProductTrigger');
        
     Test.startTest();  
    
            System.runAs(u){
            
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
            insert opp;
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            insert quote;
            //create quotelinegroup
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;

            
             //Test.startTest();          
            
            //create contract
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Contract_End_Date__c = Date.Today().addDays(-1));
            insert contract;
            
            List<Opportunity> lst_opp = new List<Opportunity>();
            lst_opp.add(opp);
            List<Contract> lst_con = new List<Contract>();
            lst_con.add(contract);
            
     
            // test creating a contract
            Map<String, String> contractMap = OpportunityTriggerHandler.createContract(lst_opp);
            

            //test creating agreed prices
            OpportunityTriggerHandler.createAgreementPrices(lst_con);
            
           
           //Update Opportunity to Set Pricing Agreement to False and Run Test
            contract.Automatic_Renewal__c = false;
            contract.SBQQ__Quote__c = quote.id;
            
            update contract;
            
           
            //US-0002330- Test VF Page for related account output, setup page and parameters to test RelatedAccounts VF Page
            PageReference pageRef2 = Page.RelatedAccountsOutput;
            PageRef2.getParameters().put('qid',quote.Id);
            Test.setCurrentPage(pageRef2);
            RelatedAccountsController rlController = new RelatedAccountsController();
            system.assertNotEquals(rlController.cecs, null);

            
            PageReference pageRef = Page.ContractNewAmendOpp;
            PageRef.getParameters().put('type','Renewal');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            
            contractControllerRenewal.opp = opp;
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();

            
           
            
            
        }
          // test.startTest(); 
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account4', 'testSite4', 'ABC Street4', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity1',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
            insert opp;
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            insert quote;
            //create quotelinegroup
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;
        
            
            //create contract
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Contract_End_Date__c = Date.Today().addDays(-1));
            insert contract;
            
            List<Opportunity> lst_opp = new List<Opportunity>();
            lst_opp.add(opp);
            List<Contract> lst_con = new List<Contract>();
            lst_con.add(contract);
            
           
            // test creating a contract
           
            Map<String, String> contractMap = OpportunityTriggerHandler.createContract(lst_opp);
            

            //test creating agreed prices
            OpportunityTriggerHandler.createAgreementPrices(lst_con);
            
            
           //Update Opportunity to Set Pricing Agreement to False and Run Test
            contract.Automatic_Renewal__c = false;
            contract.SBQQ__Quote__c = quote.id;
            
            update contract;
            
            
            //US-0002330- Test VF Page for related account output, setup page and parameters to test RelatedAccounts VF Page
            PageReference pageRef2 = Page.RelatedAccountsOutput;
            PageRef2.getParameters().put('qid',quote.Id);
            Test.setCurrentPage(pageRef2);
            RelatedAccountsController rlController = new RelatedAccountsController();
            system.assertNotEquals(rlController.cecs, null);

            
            PageReference pageRef = Page.ContractNewAmendOpp;
            PageRef.getParameters().put('type','Renewal');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            
            contractControllerRenewal.opp = opp;
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();
            
            Test.stopTest();
            
        
        
    }*/
    
    static testMethod void testAmendedQuoteOnOppty(){
    
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
            //User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
            // insert user
            User u = new User(Alias = 'standt', Email='standarduser1z@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Administrator',FirstName='Salesforce',LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1z@testorg.com');
            insert u;
            
            //Creating Diagnostics Opportunity RecordType Id custom settings
            Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
            insert diagRTIds;
            
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger');
            
        
            System.runAs(u){
    
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity1',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Lab_Open_Opportunity')).substring(0,15));
            opp.Revenue_Class__c = 'New Customer';
            opp.Install_Date__c = system.today();
            opp.Type = 'Amendment';
            insert opp;
            
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
           // quote.SBQQ__SubscriptionTerm__c = 12;
                quote.SBQQ__StartDate__c=system.today();
                quote.SBQQ__EndDate__c=system.today()+365;
              
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;
            
            
            
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Contract_End_Date__c = Date.Today().addDays(-1),Division__c = 'Diagnostics',SBQQ__Opportunity__c=opp.Id);
            insert contract;
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id;          
            update opp;
            
            PageReference pageRef = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController con = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','DiagnosticAmendment');
            
            Ext_ContractNewAnR controllerRenewal = new Ext_ContractNewAnR(con);
            controllerRenewal.RunThatOpp();
            controllerRenewal.goToContract();
            controllerRenewal.gotoOpp();
            
            }
            
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account6', 'testSite6', 'ABC Street6', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity3',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Lab_Open_Opportunity')).substring(0,15));
            opp.Revenue_Class__c = 'New Customer';
            opp.Install_Date__c = system.today();
            opp.Type = 'Amendment';
            insert opp;
            
            Test.startTest();
            
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__SubscriptionTerm__c = 12;
        quote.SBQQ__StartDate__c=system.today();
        quote.SBQQ__EndDate__c=system.today()+365;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;
            
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Contract_End_Date__c = Date.Today().addDays(-1),Division__c = 'Diagnostics',SBQQ__Opportunity__c=opp.Id);
            insert contract;
            
            //update primary quote on oppty
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id;          
            update opp;
            
            PageReference pageRef = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController con = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','DiagnosticAmendment');
            
            Ext_ContractNewAnR controllerRenewal = new Ext_ContractNewAnR(con);
            controllerRenewal.RunThatOpp();
            controllerRenewal.goToContract();
            controllerRenewal.gotoOpp();
            
            Test.stopTest();
            
    }
    
    static testMethod void testAmendedQuoteOnOppty1(){
    
           
            //Creating Diagnostics Opportunity RecordType Id custom settings
            Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
            insert diagRTIds;
            
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger');
            
           
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity1',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Lab_Open_Opportunity')).substring(0,15));
            opp.Revenue_Class__c = 'New Customer';
            opp.Install_Date__c = system.today();
            opp.Type = 'Amendment';
            insert opp;
            
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__SubscriptionTerm__c = 12;
          quote.SBQQ__StartDate__c=system.today();
                quote.SBQQ__EndDate__c=system.today()+365;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            test.startTest();
            
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;
            
           
             
            List<Contract> contractList = new List<Contract>(); 
            
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Contract_End_Date__c = Date.Today().addDays(-1),Division__c = 'Diagnostics',SBQQ__Opportunity__c=opp.Id);
            insert contract;
            
            //update primary quote on oppty
            //opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id;          
            update opp;
            
            PageReference pageRef = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController con = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','DiagnosticAmendment');
            
            Ext_ContractNewAnR controllerRenewal = new Ext_ContractNewAnR(con);
            controllerRenewal.RunThatOpp();
            controllerRenewal.goToContract();
            controllerRenewal.gotoOpp();
            
            quote.ApprovalStatus__c = 'Executed';
        quote.SBQQ__EndDate__c=system.today()+365;
        quote.SBQQ__Status__c='Executed';
            update quote;
            opp.SBQQ__AmendedContract__c = null;          
            update opp;
            
            PageReference pageRef1 = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef1);
            
            ApexPages.StandardController con1 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','New');
            
            Ext_ContractNewAnR controllerRenewal1 = new Ext_ContractNewAnR(con1);
            controllerRenewal1.RunThatOpp();
            
            ////////////////////////////////////////////////////////////////////////////
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = null; 
        //OPP.Pricing_Agreement_Created__c=TRUE;
        //OPP.StageName='Closed Won';
            update opp;
           ApexPages.StandardController con11 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Amendment');
            
            Ext_ContractNewAnR controllerRenewal11 = new Ext_ContractNewAnR(con11);
            controllerRenewal11.RunThatOpp();
            ////////////////////////////////////////////////////////////////////////////////
            opp.SBQQ__RenewedContract__c=null;
        update opp;
           ApexPages.StandardController con12 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Renewal');
            
            Ext_ContractNewAnR controllerRenewal12 = new Ext_ContractNewAnR(con11);
            controllerRenewal12.RunThatOpp();
            ////////////////////////////////////////////////////////////////////////////////
            
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id; 
        //OPP.Pricing_Agreement_Created__c=TRUE;
       // OPP.StageName='Closed Won';
            update opp;
            ApexPages.StandardController con3 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','New');
            
            Ext_ContractNewAnR controllerRenewal3 = new Ext_ContractNewAnR(con3);
            controllerRenewal3.RunThatOpp();
              opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id; 
        OPP.Pricing_Agreement_Created__c=TRUE;
        OPP.StageName='Closed Won';
            update opp;
            
            ApexPages.StandardController con4 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Amendment');
            
            Ext_ContractNewAnR controllerRenewal4 = new Ext_ContractNewAnR(con4);
            controllerRenewal4.RunThatOpp();
            
            contractList.add(contract);

            //CreateAmendRenewalHelper carh = new CreateAmendRenewalHelper();
            CreateAmendRenewalHelper.FindOpp(contractList);
                        
            /*opp.SBQQ__PrimaryQuote__c = null;          
            update opp;
            
            ApexPages.StandardController con5 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Renewal');
            
            Ext_ContractNewAnR controllerRenewal5 = new Ext_ContractNewAnR(con5);
            controllerRenewal5.RunThatOpp();*/
            
            Test.stopTest();
            
    }
        static testMethod void testAmendedQuoteOnOppty2(){
    
           
            //Creating Diagnostics Opportunity RecordType Id custom settings
            Diagnostic_Opportunity_Record_Type_IDs__c diagRTIds = new Diagnostic_Opportunity_Record_Type_IDs__c(Diagnostic_Lab_Open_Opportunity__c = '01261000000ixmE', Diagnostic_Perinatal_Open_Opportunity__c = '01261000000ixmF',Diagnostic_Physician_Open_Opportunity__c = '01261000000ixmG',Diagnostic_Service_Opportunity__c = '01261000000XwtN');
            insert diagRTIds;
            
            TestUtility.insertCustSetting('OpportunityTrigger');
            TestUtility.insertCustSetting('ProductTrigger');
            
           
            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            
            //create oppty
            Opportunity opp = TestUtility.newOpportunity('Test Opportunity1',custAcc.Id,date.today(),'Close','Expected');
            opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Lab_Open_Opportunity')).substring(0,15));
            opp.Revenue_Class__c = 'New Customer';
            opp.Install_Date__c = system.today();
            opp.Type = 'Amendment';
            insert opp;
            
            //create quote
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            quote.SBQQ__SubscriptionTerm__c = 12;
              quote.SBQQ__StartDate__c=system.today();
                quote.SBQQ__EndDate__c=system.today()+365;
            insert quote;
            //create quoteline group
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            //create product
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            //create quoteline
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            
            
            //create pricebook
            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;
            
             Test.startTest();
             
            List<Contract> contractList = new List<Contract>(); 
            
            //create contract 
            Contract contract = new Contract(AccountId = custAcc.Id,ContractTerm = 1,Marketing_Program__c = 'Evaluation Agreement',Contract_End_Date__c = Date.Today().addDays(-1),Division__c = 'Diagnostics',SBQQ__Opportunity__c=opp.Id);
            insert contract;
            
            //update primary quote on oppty
            //opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id;          
            update opp;
            
            PageReference pageRef = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardController con = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','DiagnosticAmendment');
            
            Ext_ContractNewAnR controllerRenewal = new Ext_ContractNewAnR(con);
            controllerRenewal.RunThatOpp();
            controllerRenewal.goToContract();
            controllerRenewal.gotoOpp();
            
            quote.ApprovalStatus__c = 'Executed';
        quote.SBQQ__EndDate__c=system.today()+365;
        quote.SBQQ__Status__c='Executed';
            update quote;
        opp.SBQQ__PrimaryQuote__c = quote.Id; 
            opp.SBQQ__AmendedContract__c = contract.id;          
            update opp;
            
            PageReference pageRef1 = Page.CreatePA_Opp;
            Test.setCurrentPage(pageRef1);
            
            ApexPages.StandardController con1 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','else');
            
            Ext_ContractNewAnR controllerRenewal1 = new Ext_ContractNewAnR(con1);
            controllerRenewal1.RunThatOpp();
            
            ////////////////////////////////////////////////////////////////////////////
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = null; 
        //OPP.Pricing_Agreement_Created__c=TRUE;
        //OPP.StageName='Closed Won';
            update opp;
           ApexPages.StandardController con11 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Amendment');
            
            Ext_ContractNewAnR controllerRenewal11 = new Ext_ContractNewAnR(con11);
            controllerRenewal11.RunThatOpp();
            ////////////////////////////////////////////////////////////////////////////////
            opp.SBQQ__RenewedContract__c=null;
         opp.SBQQ__AmendedContract__c = contract.id;
        update opp;
           ApexPages.StandardController con12 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Renewal');
            
            Ext_ContractNewAnR controllerRenewal12 = new Ext_ContractNewAnR(con11);
            controllerRenewal12.RunThatOpp();
            ////////////////////////////////////////////////////////////////////////////////
            
            opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id; 
        //OPP.Pricing_Agreement_Created__c=TRUE;
       // OPP.StageName='Closed Won';
            update opp;
            ApexPages.StandardController con3 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','New');
            
            Ext_ContractNewAnR controllerRenewal3 = new Ext_ContractNewAnR(con3);
            controllerRenewal3.RunThatOpp();
              opp.SBQQ__PrimaryQuote__c = quote.Id;  
            opp.SBQQ__AmendedContract__c = contract.Id; 
        OPP.Pricing_Agreement_Created__c=TRUE;
        OPP.StageName='Closed Won';
            update opp;
            
            ApexPages.StandardController con4 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Amendment');
            
            Ext_ContractNewAnR controllerRenewal4 = new Ext_ContractNewAnR(con4);
            controllerRenewal4.RunThatOpp();
            
            contractList.add(contract);

            //CreateAmendRenewalHelper carh = new CreateAmendRenewalHelper();
            CreateAmendRenewalHelper.FindOpp(contractList);
                        
            /*opp.SBQQ__PrimaryQuote__c = null;          
            update opp;
            
            ApexPages.StandardController con5 = new ApexPages.StandardController(opp);
            ApexPages.currentPage().getParameters().put('id',opp.id);
            ApexPages.currentPage().getParameters().put('type','Renewal');
            
            Ext_ContractNewAnR controllerRenewal5 = new Ext_ContractNewAnR(con5);
            controllerRenewal5.RunThatOpp();*/
            
            Test.stopTest();
            
    }

    /** Test Method to cover the uncovered sections of CreateAmendRenewalHelper class  **/
    static testMethod void testCreateAmendRenewalHelper(){
    
            
    }
}