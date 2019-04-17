/*--------------------------------------------------------------------------------------------------
Author:      Ronald Mendoza
Description:  Test class to validate OpportunityTriggerHandler Class for CEC Creation
Tests Executed:


History:
<Date>      <Authors Name>    <Brief Description of Change>
2/03/2017   Ronald Mendoza    Initial Creation
2/22/2017   Ronald Mendoza    Added Code to Test RelatedAccounts VF page and controller
---------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_OpportunityTriggerHandler{
    static{
        TestUtility.setupConfigurationSettings();
    }

    //US-0001741 - testCreateCECs Test Method
    static testMethod void testCreateCECs(){
    
        List<Contract> contractList = new List<Contract>();
        List<Agreed_Price__c> ap = new List<Agreed_Price__c>();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        User u = [SELECT Id from User where LastName='Administrator' AND FirstName='Salesforce' LIMIT 1];
        
        System.runAs(u){
    
            Trigger_Switch__c ts = new Trigger_Switch__c();
            ts.Name = 'OpportunityTrigger';
            Trigger_Switch__c ts2 = new Trigger_Switch__c(name = 'CreateContractAgreePrice', Active__c = true);
            insert ts2;
            ts.Active__c = true;
            insert ts;

            Trigger_Switch__c productTriggerSwitch = new Trigger_Switch__c();
            productTriggerSwitch.Name = 'ProductTrigger';
            Trigger_Switch__c productReplacementSwitch = new Trigger_Switch__c(name = 'ProductReplacement', Active__c = true);
            insert productReplacementSwitch;
            productTriggerSwitch.Active__c = true;
            insert productTriggerSwitch;

            //Create Test Account, Opportunity and Quote Data for Test
            Account custAcc =  TestUtility.newAccount('Test Site Account3', 'testSite3', 'ABC Street3', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
            insert custAcc;
            
            Opportunity opp = new Opportunity(Name='TestOpp', StageName='Qualify', CloseDate=System.today(), AccountId = custAcc.Id);
            insert opp;
            //Test.startTest();
            SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
            quote.SBQQ__Primary__c = true;
            insert quote;
            
            SBQQ__QuoteLineGroup__c qgp = new SBQQ__QuoteLineGroup__c(of_Boxes__c = 1, Name = 'Test Group', SBQQ__Number__c = 2, Shipment_Period__c = 'Monthly' ,SBQQ__Quote__c = quote.id, SBQQ__StartDate__c = system.today(), number_of_Months__c= 2, Tier__c = 2, Price_per_Test__c = 2.00 );
            insert qgp;
            
            Product2 prod = TestUtility.newProduct('Test Product');
            insert prod;
            
            SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
            insert quoteLine;
            quoteLine.Create_Agreed_Price__c = true;
            quoteLine.SBQQ__Group__c= qgp.id;
            update quoteLine;
            
            system.debug('quoteLine======'+quoteLine);
            
            Quote_Validation_on_Opportunity__c qvo = new Quote_Validation_on_Opportunity__c(Name='Test',Quote_Type__c='Accessories/Non-Committed Supplies');
            insert qvo;
            
            QuoteLine_validations_on_Opportunity__c qlvo = new QuoteLine_validations_on_Opportunity__c(Name='Test',Quote_Line_Group__c='Service Agreement');
            insert qlvo;
            
            Record_Type_IDs__c rt = new Record_Type_IDs__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_B_SH_Sales_Oppty__c = GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity'));
            insert rt;
            
            opp.SBQQ__PrimaryQuote__c = quote.Id;            
            update opp;

            Pricebook2 pb = new Pricebook2(Name='TestPB', IsActive=TRUE);
            insert pb;

            quote.SBQQ__StartDate__c = System.today();
            quote.SBQQ__EndDate__c = System.today().addMonths(12);  
             Test.startTest();          
            //Create new CECs to be back filled with Contract Data
            Customer_Eligible_Contract__c cec1 = new Customer_Eligible_Contract__c(Customer_Account__c = custAcc.Id, Quote__c = quote.id);
            insert cec1;

            Customer_Eligible_Contract__c cec2 = new Customer_Eligible_Contract__c(Customer_Account__c = custAcc.Id, Quote__c = quote.id);
            insert cec2;

            Customer_Eligible_Contract__c cec3 = new Customer_Eligible_Contract__c(Customer_Account__c = custAcc.Id, Quote__c = quote.id);
            insert cec3;
            
            Contract contract = new Contract(AccountId = custAcc.Id, Contract_End_Date__c = Date.Today().addDays(-1));
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
            //System.assert([select count() from Agreed_Price__c where Contract__c = :c2.Id] > 0);
            
            //test amending a price agreeement
            opp.SBQQ__AmendedContract__c=contract.id;
            update opp;
            //contractMap = OpportunityTriggerHandler.amendAgreementPrices(lst_opp);
            //System.assertNotEquals(contractMap, null);

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
            PageReference pageRef = Page.ContractNewAmendOpp;
            PageRef.getParameters().put('type','Renewal');
            Test.setCurrentPage(pageRef);
            ApexPages.standardController sta_controller = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerRenewal = new Ext_ContractNewAnR(sta_controller);
            //ApexPages.currentPage().getParameters().put('type', 'Renewal');
            //ApexPages.currentPage().getParameters().put('quoteId', quote.Id);
            //ApexPages.currentPage().getParameters().put('oppId', opp.Id);
            //contractControllerRenewal.opp = opp;
            Contract testRenewalContract = contractControllerRenewal.returnContract();
            contractControllerRenewal.RunThat();
            contractControllerRenewal.returnToPrevious();

            // create controller amendment
            PageReference pageRef3 = Page.ContractNewAmendOpp;
            PageRef3.getParameters().put('type','Amendment');
            Test.setCurrentPage(pageRef3);
            ApexPages.standardController amendController = new ApexPages.standardController(contract);
            Ext_ContractNewAnR contractControllerAmendment = new Ext_ContractNewAnR(amendController);
            //ApexPages.currentPage().getParameters().put('type', 'Amendment');
            //ApexPages.currentPage().getParameters().put('quoteId', quote.Id);
            //ApexPages.currentPage().getParameters().put('oppId', opp.Id);
            contractControllerAmendment.quoteId = quote.Id;
            contractControllerAmendment.opp = opp;
            Contract testAmendmentContract = contractControllerAmendment.returnContract();
            contractControllerAmendment.RunThat();
            contractControllerAmendment.gotoQuote();
            contractControllerAmendment.gotoOpp();

            //Testing goToOpp method
            /*Ext_ContractNewAnR goToOppController = new Ext_ContractNewAnR(sta_controller);
            ApexPages.currentPage().getParameters().put('type', 'Renewal');
            ApexPages.currentPage().getParameters().put('quoteId', quote.Id);
            ApexPages.currentPage().getParameters().put('oppId', opp.Id);
            //goToOppController.quoteId = quote.Id;
            //goToOppController.oppId = opp.Id;
            goToOppController.opp = opp;
            Contract testGoToOppContract = goToOppController.returnContract();
            goToOppController.RunThat();
            goToOppController.gotoOpp();*/
            
            //Update Opportunity to Set Pricing Agreement to True and Run Test
            contract.Automatic_Renewal__c = true;
            //contract.One_Time_Renewal__c = false;
            update contract;
    
           
            opp.Pricing_Agreement_Created__c = True;
            update opp;
            Test.stopTest();
            //Check if CECs have been associated to Contract Data
            Customer_Eligible_Contract__c ce1 = [SELECT Id, Contract__c, Effective_Date__c, Expiration_Date__c, Precedence_Value__c,Selected__c, Quote__c from Customer_Eligible_Contract__c where Id = :cec1.Id];
            System.assertEquals(True, ce1.Selected__c);
            System.assertEquals(Date.Today().addDays(-1), ce1.Effective_Date__c);
            //System.assertEquals(260, ce1.Precedence_Value__c);
            System.assertEquals(Date.Today().addDays(365), ce1.Expiration_Date__c);

            /*Customer_Eligible_Contract__c ce2 = [SELECT Id, Contract__c, Effective_Date__c, Expiration_Date__c, Precedence_Value__c,Selected__c, Quote__c from Customer_Eligible_Contract__c where Id = :cec2.Id];
            System.assertEquals(True, ce2.Selected__c);
            System.assertEquals(Date.Today().addDays(-1), ce2.Effective_Date__c);
            System.assertEquals(260, ce2.Precedence_Value__c);
            System.assertEquals(Date.Today().addDays(365), ce2.Expiration_Date__c);

            Customer_Eligible_Contract__c ce3 = [SELECT Id, Contract__c, Effective_Date__c, Expiration_Date__c, Precedence_Value__c,Selected__c, Quote__c from Customer_Eligible_Contract__c where Id = :cec3.Id];
            System.assertEquals(True, ce3.Selected__c);
            System.assertEquals(Date.Today().addDays(-1), ce3.Effective_Date__c);
            System.assertEquals(260, ce3.Precedence_Value__c);
            System.assertEquals(Date.Today().addDays(365), ce3.Expiration_Date__c);*/
            
        }
    }
}