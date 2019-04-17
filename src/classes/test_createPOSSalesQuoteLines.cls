/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Test Class for createPOSSalesQuoteLines

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2018      Kasmoor Reddy       Initial Creation 
----------------------------------------------------------------------------------------------------------------*/
@isTest
public class test_createPOSSalesQuoteLines {
    //Variable Declaration
    
    private static Account siteAccount;
    private static User testUser;
    private static Id accountCustomerRecordTypeId = GlobalUtility.getRecordTypeId('Account', 'Customer');
    private static Configuration_Settings__c orgDefaults;
    public static List<Product2> prodList=new List<Product2>();
    public static Opportunity newOpp = new Opportunity();
    public static  List<Account> accList=new List<Account>();
    public static  PriceBook2 pricebook ;
    /*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:     Test Method1 to invoke createPOSSalesQuoteLines (for conditions of productSourceDivision)

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2018      Kasmoor Reddy       Initial Creation 
----------------------------------------------------------------------------------------------------------------*/    
    static testMethod void testMethod1()
    {
        Test.startTest();
        CreateData();
        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        //q.CurrencyIsoCode = newOpp.CurrencyIsoCode;
        insert q;
        SBQQ__Quote__c q1=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today(),POS_Quote__c=q.id);
        //q1.CurrencyIsoCode = newOpp.CurrencyIsoCode;
        insert q1;
        System.debug('quote currency:'+q1.CurrencyIsoCode);
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<1; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        }
        //Insert Quote Lines
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        Test.stopTest();
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,POS_Quote__c,ShipTo_Site__c,BillTo_Site__c,DeliverTo_Site__c FROM SBQQ__Quote__c where POS_Quote__c!=null limit 1];
        List<Id> quoteListId=new List<Id>();
        quoteListId.add(thisQuote.Id);
       //Calling apex method
        createPOSSalesQuoteLines.createPOSQuoteLines(quoteListId);
    }
    /*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:     Test Method2 to invoke createPOSSalesQuoteLines (for conditions of productSourceDivision)

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2018      Kasmoor Reddy       Initial Creation 
----------------------------------------------------------------------------------------------------------------*/  
    static testMethod void testMethod2()
    {
        Test.startTest();
        CreateData();
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        SBQQ__Quote__c q1=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today(),POS_Quote__c=q.id);
        insert q1;
        
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<1; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(1).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        }
        //Insert Quote Lines
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        Test.stopTest();
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,POS_Quote__c,ShipTo_Site__c,BillTo_Site__c,DeliverTo_Site__c FROM SBQQ__Quote__c where POS_Quote__c!=null limit 1];
        List<Id> quoteListId=new List<Id>();
        quoteListId.add(thisQuote.Id);
       //Calling apex method
        createPOSSalesQuoteLines.createPOSQuoteLines(quoteListId);
    }
    /*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Test Method3 to invoke createPOSSalesQuoteLines (for conditions of productSourceDivision)

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2018      Kasmoor Reddy       Initial Creation 
----------------------------------------------------------------------------------------------------------------*/   
    static testMethod void testMethod3()
    {
        Test.startTest();
        CreateData();
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        SBQQ__Quote__c q1=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today(),POS_Quote__c=q.id);
        insert q1;
        
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<1; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(2).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,Requested_Date__c = system.today()));
        }
        //Insert Quote Lines
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        Test.stopTest();
        SBQQ__Quote__c thisQuote = [SELECT Id,SBQQ__Account__c,POS_Quote__c,ShipTo_Site__c,BillTo_Site__c,DeliverTo_Site__c FROM SBQQ__Quote__c where POS_Quote__c!=null limit 1];
        List<Id> quoteListId=new List<Id>();
        quoteListId.add(thisQuote.Id);
      //Calling apex method
        createPOSSalesQuoteLines.createPOSQuoteLines(quoteListId);
    }

    /*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Method for Data Insertion

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/21/2018      Kasmoor Reddy       Initial Creation 
----------------------------------------------------------------------------------------------------------------*/   
    public static void CreateData() {
        //insert configuration settings
        TestUtility.setupConfigurationSettings();
        // Create test User
        //insert trigger switch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        
        insert ts;
        System.assertEquals('OpportunityTrigger', ts.Name);
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'ContractTrigger';
        ts1.Active__c = true;
        insert ts1;
        System.assertEquals('ContractTrigger', ts1.Name);
        TestUtility.insertCustSetting('sitelocTrigger'); 
        
        List<AccountConfiguration__c> accConfigList = new List<AccountConfiguration__c>();
        AccountConfiguration__c accConfig = new AccountConfiguration__c();
        accConfig.Name = 'Canada Commercial';
        accConfig.Country__c = 'Canada';
        accConfig.Currency__c = 'CAD';
        accConfig.RecordTypeId__c = '012f00000006jf8AAA';
        accConfig.PricebookId__c = '01sf0000000PZm5AAG';
        accConfigList.add(accConfig);
        
        AccountConfiguration__c accConfig1 = new AccountConfiguration__c();
        accConfig1.Name = 'Canada Service';
        accConfig1.Country__c = 'Canada';
        accConfig1.Currency__c = 'CAD';
        accConfig1.RecordTypeId__c = '012f00000006jf9AAA';
        accConfig1.PricebookId__c = '01sf0000000PZmZAAW';
        accConfigList.add(accConfig1);
        
        
        
        insert accConfigList;
        
        // Create Account(s)
        
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            Account acc = TestUtility.newAccount(accName, accName);
            acc.CurrencyIsoCode = UserInfo.getDefaultCurrency();
            accList.add(acc);
        }
        
        //insert accList;
        System.assertNotEquals(accList,null,'success');
        insert accList;
        System.debug('account currency:'+accList[0].CurrencyIsoCode);
        //insert product source division
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd.Source_Division_Number__c='200';
        Insert psd;
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd1.Source_Division_Number__c='300';
        Insert psd1;
        Product_Source_Division__c psd2 = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        psd2.Source_Division_Number__c='310';
        Insert psd2;
        
        //Create Products
        
        
        prodList.add(new Product2(Name = 'PLATINUM BONE', IsActive = true, Quotable__c = true,Product_Source_Division__c = psd.Id,POS_Coverage_Eligible__c =true));
        prodList.add(new Product2(Name = 'PLATINUM BREVERA', IsActive = true, Quotable__c = true,POS_Coverage_Eligible__c =true,Product_Source_Division__c = psd1.Id));
        prodList.add(new Product2(Name = 'PLATINUM MAMMO', IsActive = true, Quotable__c = true,POS_Coverage_Eligible__c =true,Product_Source_Division__c = psd2.Id));
        prodList.add(new Product2(Name = 'PLATINUM MAMMO', IsActive = true, Quotable__c = true,POS_Coverage_Eligible__c =true,Product_Source_Division__c = psd2.Id,Trade_In_Product__c =true,Hologic_Trade_in__c =true));


        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        //Insert Products
        insert prodList;
        //Create Price Book 
        pricebook = new Pricebook2(name='Test Pricebook');
        insert pricebook;
        //Create Opp
        
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        insert newOpp;
        System.debug('OpptyCurrency:'+newOpp.CurrencyIsoCode);
        System.assertEquals('OppTest',newOpp.Name);
    }
    
    
}