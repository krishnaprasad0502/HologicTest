/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate siteContacts page and opportunitySiteContacts extension controller
        Tests Excecuted:
        
         init - verifies that the test data gets created successfully
        
      
        
 History:
<Date>      <Authors Name>    <Brief Description of Change>
02/16/2017  Mani Sundaresan    Initial Creation
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_opportunitySiteContacts{

    static PageReference pageRef;
    static opportunitySiteContact sic;

     static testMethod Opportunity createOppty(){
    
        // setup data 
        TestUtility.setupConfigurationSettings();
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        
        
        Opportunity__c siteCon = new Opportunity__c();
        siteCon.Name = 'Test';
        siteCon.Product_Names__c = 'Test Product';
        siteCon.Non_DXA_Product_Names__c = 'Test';
        insert siteCon;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        
        Contact cont1 = TestUtility.newContact('Test','Contact1',custAcc.Id);
        insert cont1;
        
        Contact cont2 = TestUtility.newContact('Test','Contact2',custAcc.Id);
        insert cont2;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
        insert opp;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
        quote.SBQQ__Primary__c = true;
        insert quote;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
        insert quoteLine;
        
        Quote_Validation_on_Opportunity__c qvo = new Quote_Validation_on_Opportunity__c(Name='Test',Quote_Type__c='Accessories/Non-Committed Supplies');
        insert qvo;
        
        QuoteLine_validations_on_Opportunity__c qlvo = new QuoteLine_validations_on_Opportunity__c(Name='Test',Quote_Line_Group__c='Service Agreement');
        insert qlvo;
        
        Record_Type_IDs__c rt = new Record_Type_IDs__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_B_SH_Sales_Oppty__c = GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity'));
        insert rt;
        
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        
        update opp;
        
        return opp;
        
    }
       static testMethod void validateSiteContactsPage(){
        
        Test.startTest();
        
        
        Opportunity opp = createOppty();
        
        pageRef = Page.SiteContacts;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController con = new ApexPages.StandardController(opp);
        ApexPages.currentPage().getParameters().put('id',opp.id);
        sic = new opportunitySiteContact(con);
        
        sic.saveSiteContact();
        sic.cancelSiteContact();
        
        Test.stopTest();
        
        
        
    }
}