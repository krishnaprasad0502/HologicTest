/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate OpportunityTrigger Framework
Tests Excecuted: insertandupdateprofiledata_Test-- to validate the method updates or insert the profile data records based on the 
                 values opportunity assay type and assay test name.
                 insertandupdateprofiledata_Test_V1-- to validate the method updates or insert the profile data records based on the 
                 values opportunity assay type and assay test name.


History:
<Date>      <Authors Name>    <Brief Description of Change>
11/05/2016  Mani Sundaresan   Initial Creation
5/18/17     Rich Varga        Add Bill to ,Ship To, Deliver tests
06/09/2017  Kasmoor Reddy     Added the test method to insert or update the profile data records(US-3316)
05/08/2018  Mani Sundaresan   Test method to validate the assignment of Pricebook and Currency based on Account's country(US-4158)
02/26/2019  Vinay Nallakadi     Test Method to validate the Growth mapping fields on Opportunity (US-0006699)
---------------------------------------------------------------------------------------------------------*/
@isTest(seealldata=false)
private class Test_OpportunityTrigger{
private static Account Acc;
private static Account siteAccount;    
    
    static testMethod Opportunity createOppty(){
        // setup data 
        TestUtility.setupConfigurationSettings();
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Opportunity__c siteCon = new Opportunity__c();
        siteCon.Name = 'Test';
        siteCon.Product_Names__c = 'Test Product';    
        insert siteCon;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;

        
        //Create Site Locations inactive
        // Rich Varga 5-18-18
        List<Site_Location__c> siteList1 = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation1'+string.valueOf(i);
            siteList1.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = custAcc.id, Active__c = true));
        }
        insert siteList1;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
        insert opp;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
        quote.SBQQ__Primary__c = true;
              insert quote;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        /* Rich Varga */
        prod.Quotable__c = FALSE;
        update prod;
        
        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
        quoteLine.SBQQ__Incomplete__c = true;
        //quoteLine.Quotable__c  = false;
        insert quoteLine;
        
        // Rich Varga
        // 5-18-17
        list <SBQQ__QuoteLineGroup__c> egroup  = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Name = 'Equipment'];
        
        // Rich Varga    
        if (egroup.size() > 0)
        quoteline.SBQQ__Group__c = egroup[0].id;
        update quoteline;
        
        Quote_Validation_on_Opportunity__c qvo = new Quote_Validation_on_Opportunity__c(Name='Test',Quote_Type__c='Accessories/Non-Committed Supplies');
        insert qvo;
        
        QuoteLine_validations_on_Opportunity__c qlvo = new QuoteLine_validations_on_Opportunity__c
        (Name='Test',Quote_Line_Group__c='Service Agreement');
        insert qlvo;
        
        Record_Type_IDs__c rt = new Record_Type_IDs__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_B_SH_Sales_Oppty__c = GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity'));
        insert rt;
        
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        update opp;
        return opp;
        
    }

    static testMethod Opportunity createOpptynondxa(){
    
        // setup data 
        TestUtility.setupConfigurationSettings();
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        
        
        Opportunity__c siteCon = new Opportunity__c();
        siteCon.Name = 'Test';
        siteCon.Product_Names__c = '';   
        siteCon.Non_DXA_Product_Names__c = 'TEST NON DXA';
        insert siteCon;
        
        Opportunity__c siteCon1 = new Opportunity__c();
        siteCon1.Name = 'Unifi Analytics Bundle';
        siteCon1.Product_Names__c = '';   
        siteCon1.Non_DXA_Product_Names__c = '';
        siteCon1.Unify_Products__c = 'Unifi Analytics Bundle';
        insert siteCon1;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        
        //Create Site Locations inactive
        // Rich Varga 5-18-18
        List<Site_Location__c> siteList1 = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation1'+string.valueOf(i);
            siteList1.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = custAcc.id, Active__c = true));
        }
        insert siteList1;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
        insert opp;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
        quote.SBQQ__Primary__c = true;
              insert quote;
        
        Product2 prod = TestUtility.newProduct('TEST NON DXA');
        insert prod;
        /* Rich Varga */
        prod.Quotable__c = TRUE;
        update prod;
        
        
        Test.startTest();
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
        qlList.add(quoteLine);
        
        insert qlList;
        
        
        // Rich Varga
        // 5-18-17
        list <SBQQ__QuoteLineGroup__c> egroup  = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Name = 'Equipment'];
        
        // Rich Varga    
        if (egroup.size() > 0)
        quoteline.SBQQ__Group__c = egroup[0].id;
             
        update quoteline;
        Test.stopTest();
        
        
        Quote_Validation_on_Opportunity__c qvo = new Quote_Validation_on_Opportunity__c(Name='Test',Quote_Type__c='Accessories/Non-Committed Supplies');
        insert qvo;
        
        QuoteLine_validations_on_Opportunity__c qlvo = new QuoteLine_validations_on_Opportunity__c
        (Name='Test',Quote_Line_Group__c='Service Agreement');
        insert qlvo;
        
        Record_Type_IDs__c rt = new Record_Type_IDs__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_B_SH_Sales_Oppty__c = GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity'));
        insert rt;
        
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        update opp;
        
        return opp;
        
        
    }
    
    static testMethod void createOpptyUnifyAdmin(){
    
        // setup data 
        TestUtility.setupConfigurationSettings();
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        
        Opportunity__c siteCon = new Opportunity__c();
        siteCon.Name = 'Unifi Analytics Bundle';
        siteCon.Product_Names__c = '';   
        siteCon.Non_DXA_Product_Names__c = '';
        siteCon.Unify_Products__c = 'Unifi Analytics Bundle';
        insert siteCon;
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        
        //Create Site Locations inactive
        // Rich Varga 5-18-18
        List<Site_Location__c> siteList1 = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation1'+string.valueOf(i);
            siteList1.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = custAcc.id, Active__c = true));
        }
        insert siteList1;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15));
        insert opp;
        
        SBQQ__Quote__c quote = TestUtility.newQuote(custAcc.Id,opp.Id);
        quote.SBQQ__Primary__c = true;
              insert quote;
        
        Product2 prod = TestUtility.newProduct('Unifi Analytics Bundle');
        insert prod;
        /* Rich Varga */
        prod.Quotable__c = TRUE;
        update prod;
        Test.startTest();
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c quoteLine = TestUtility.newQuoteLine(quote.Id,prod.Id,1000,1);
        qlList.add(quoteLine);
        
        insert qlList;
        
        // Rich Varga
        // 5-18-17
        list <SBQQ__QuoteLineGroup__c> egroup  = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Name = 'Equipment'];
        
        // Rich Varga    
        if (egroup.size() > 0)
        quoteline.SBQQ__Group__c = egroup[0].id;
             
        update quoteline;
         Test.stopTest();
        
        Quote_Validation_on_Opportunity__c qvo = new Quote_Validation_on_Opportunity__c(Name='Test',Quote_Type__c='Accessories/Non-Committed Supplies');
        insert qvo;
        
        QuoteLine_validations_on_Opportunity__c qlvo = new QuoteLine_validations_on_Opportunity__c
        (Name='Test',Quote_Line_Group__c='Service Agreement');
        insert qlvo;
        
        Record_Type_IDs__c rt = new Record_Type_IDs__c(SetupOwnerId=UserInfo.getOrganizationId(),Opportunity_B_SH_Sales_Oppty__c = GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity'));
        insert rt;
        
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        update opp;
       
        //return opp;
        
    }


    static testMethod void validateQuote(){
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        Test.startTest();
        Opportunity opp = createOppty();
        opp.StageName = 'Deliver';
        opp.Site_Readiness__c = null;
        opp.additional_primary_contact__c = null;
        opp.Purchasing_Agent_CFO__c = null;
        opp.iT_PACS_Administrator__c = null;
        opp.Mammography_MRI_Manager__c =  null;
        
        try{
            update opp;          
         }
        catch(DmlException ex){
       
       System.assertEquals('Please select Site Readiness',ex.getDmlMessage(0));
     }
        Test.stopTest();
    }
    
    static testMethod void validateQuoteNon(){
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
        TestUtility.insertCustSetting('DeleteZeroQtyStock');
        
        //Test.startTest();
        Opportunity opp = createOpptynondxa();
        opp.StageName = 'Deliver';
        opp.Site_Readiness__c = 'New Construction';
        opp.additional_primary_contact__c = null;
        opp.Purchasing_Agent_CFO__c = null;
        opp.iT_PACS_Administrator__c = null;
        opp.Mammography_MRI_Manager__c =  null;
        try{
            update opp;          
          }
        catch(DmlException ex){
       
       System.assertEquals('Please select Additional/Primary Contact, Purchasing Agent/CFO, IT/PACS Administrator , Mammography/MRI Manager using Site Contacts button',ex.getDmlMessage(0));
      }
        //Test.stopTest();
    }
    
   private static void changeOpptyTerritory()
    {        
        List<Territory2Type> terriType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'AM' LIMIT 1];
        Profile adminProfile = [select id, name from Profile where  name = 'B&SH Inside Sales User' LIMIT 1];
        
        
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'DeleteZeroQtyStock';
        ts1.Active__c = true;
        insert ts1;

        Territory2Model terrModel = new Territory2Model();
        terrModel .DeveloperName='ModelName'; // required field
        terrModel.Name = 'Name'; // required field
        insert terrModel ;

        Territory2 objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=terriType[0].Id);
        insert objTerr;

        //Profile p = adminProfile(0);  
        User u = new User(firstname= 'Test',
                  lastname='XXXX',
                  Alias='Test',
                  email = 'test1234@test.com',
                  username= 'test1234xxx@test.com', 
                  profileId= adminProfile.id, 
                  emailencodingkey='UTF-8',
                  languagelocalekey='en_US',
                  localesidkey='en_US',
                  timezonesidkey='America/Los_Angeles');
        insert u;

        UserTerritory2Association objUserTerritory2Association = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= u.Id, RoleInTerritory2='Sales / Marketing Manager');
        insert objUserTerritory2Association;
        
        Record_Type_IDs__c rtids = new Record_Type_IDs__c(SetupOwnerId=Userinfo.getUserId());
        rtids.Opportunity_B_SH_Sales_Oppty__c = (Id)String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Sales_Open_Opportunity')).substring(0,15);
        rtids.Opportunity_B_SH_Mammopad_Oppty__c = (Id)String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','B_SH_Mammopad_Opportunity')).substring(0,15);
        insert rtids;
        
        Opportunity op = createOppty();
        op.OwnerId = u.Id;
        update op;
        
    }
    static testMethod void insertandupdateprofiledata_Test(){
        Test.startTest();
        //setup configuration settings
        TestUtility.setupConfigurationSettings();
        //insert triggerswitch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        System.assertEquals(TRUE, ts.Active__c);
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'DeleteZeroQtyStock';
        ts1.Active__c = true;
        insert ts1;
        //insert account
        Acc=TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert Acc;
        System.assertEquals('Customer Account', Acc.Name);
        
        //insert site account
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', '100 Shipping Street', Acc.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        System.assertEquals('Site Account', siteAccount.Name);
        
        //insert profile date records to account
        List<Profile_Data__c> lstprofiledata = new List<Profile_Data__c>();
        Profile_Data__c prodata1 = new Profile_Data__c(RecordtypeId = GlobalUtility.getRecordTypeId('Profile_Data__c', 'Profile_Data'),Division__c = 'Diagnostics | Physician',Type__c = 'Physician Assay Volume',Assay_Type__c = 'HPV Office',Assay_Test_Name__c = 'APTIMA HPV',Volume__c = 200,Account__c = siteAccount.id);
        lstprofiledata.add(prodata1);
        Profile_Data__c prodata2 = new Profile_Data__c(RecordtypeId = GlobalUtility.getRecordTypeId('Profile_Data__c', 'Profile_Data'),Division__c = 'Diagnostics | Physician',Type__c = 'Physician Assay Volume',Assay_Type__c = 'Trich Office',Assay_Test_Name__c = 'Aptima Trich',Volume__c = 100,Account__c = siteAccount.id);
        lstprofiledata.add(prodata2);
        insert lstprofiledata;
        System.assertEquals(2, lstprofiledata.size());
        
        //insert opportunity
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',Acc.Id,date.today(),'Confirm','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Physician_Open_Opportunity')).substring(0,15));
        opp.Assay_Type__c = 'HPV Office';
        opp.Competitive_Assay_Type__c = 'Trich Office';
        opp.Competitive_Assay_Test_Name__c = 'Aptima Trich';
        opp.Remaining_Competitive_Assay_Volume__c = 100;
        opp.Assay_Volume__c = 200;
        opp.Assay_Test_Name__c = 'APTIMA HPV';
        opp.EMR_Code_Change_Process_Defined__c = true;
        opp.Account_Site__c = siteAccount.id;
        insert opp;
        
        Opportunity oppty = [select id,Name,Accountid,stageName from Opportunity where id=:opp.id];
        System.assertEquals('Test Opportunity', oppty.Name);
        Test.stopTest();
    }
    static testMethod void insertandupdateprofiledata_Test_V1(){
        Test.startTest();
        //setup configuration settings
        TestUtility.setupConfigurationSettings();
        //insert triggerswitch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        System.assertEquals(TRUE, ts.Active__c);
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'DeleteZeroQtyStock';
        ts1.Active__c = true;
        insert ts1;
        //insert account
        Acc=TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert Acc;
        System.assertEquals('Customer Account', Acc.Name);
        
        //insert site account
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', '100 Shipping Street', Acc.Id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        System.assertEquals('Site Account', siteAccount.Name);
        
        //insert opportunity
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',Acc.Id,date.today(),'Confirm','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','Diagnostic_Physician_Open_Opportunity')).substring(0,15));
        opp.Assay_Type__c = 'HPV Office';
        opp.Competitive_Assay_Type__c = 'Trich Office';
        opp.Competitive_Assay_Test_Name__c = 'Aptima Trich';
        opp.Remaining_Competitive_Assay_Volume__c = 100;
        opp.Assay_Volume__c = 200;
        opp.Assay_Test_Name__c = 'APTIMA HPV';
        opp.EMR_Code_Change_Process_Defined__c = true;
        opp.Account_Site__c = siteAccount.id;
        insert opp;
        
        Opportunity oppty = [select id,Name,Accountid,stageName from Opportunity where id=:opp.id];
        System.assertEquals('Test Opportunity', oppty.Name);
        
        
        //insert profile data records
        Profile_Data__c prodatarec = new Profile_Data__c(RecordtypeId = GlobalUtility.getRecordTypeId('Profile_Data__c', 'Profile_Data'),Division__c = 'Diagnostics | Physician',Type__c = 'Physician Assay Volume',Assay_Type__c = 'HPV Office',Assay_Test_Name__c = 'APTIMA HPV',Volume__c = 200,Account__c = siteAccount.id);
        insert prodatarec;
        
        Profile_Data__c pd = [select Id,Assay_Type__c,Opportunity__c,RecordTypeId,Account__c,Assay_Test_Name__c,Volume__c from Profile_Data__c where id=:prodatarec.id];
        System.assertEquals('HPV Office', pd.Assay_Type__c);
        Test.stopTest();
    }

    static testmethod void validatePricebookInfo(){
        
        //setup configuration settings
        TestUtility.setupConfigurationSettings();
        //insert triggerswitch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
        
        Trigger_Switch__c ts1 = new Trigger_Switch__c();
        ts1.Name = 'DeleteZeroQtyStock';
        ts1.Active__c = true;
        insert ts1;
        //Create international pricebooks
        
        Pricebook2 pb1 = TestUtility.newPricebook('CANADA COMMERCIAL PRICE BOOK');
        insert pb1;
        Pricebook2 pb2 = TestUtility.newPricebook('CANADA SERVICE PRICE BOOK');
        insert pb2;

        Account custAccInternational = TestUtility.newAccount('Test Cust Acc Intl','');
        custAccInternational.BillingCountry = 'Canada';
        insert custAccInternational;

        //Insert AccountConfiguration custom setting
        List<AccountConfiguration__c> accConfigList = new List<AccountConfiguration__c>();
        AccountConfiguration__c ac = new AccountConfiguration__c();
        ac.Name = 'Canada Commercial';
        ac.Country__c = 'Canada';
        ac.Currency__c = 'CAD';
        ac.RecordTypeId__c = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Capital_Sales_Opportunity');
        ac.PricebookId__c = pb1.Id;
        accConfigList.add(ac);

        AccountConfiguration__c ac1 = new AccountConfiguration__c();
        ac1.Name = 'Canada Service';
        ac1.Country__c = 'Canada';
        ac1.Currency__c = 'CAD';
        ac1.RecordTypeId__c = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Svc_Contract_Opportunity');
        ac1.PricebookId__c = pb2.Id;
        accConfigList.add(ac1);
        
        insert accConfigList;


        Test.startTest();
        
        Opportunity intlOppty = TestUtility.newOpportunity('Test Intl Opportunity', custAccInternational.Id, system.today(), 'Confirm', 'Expected');
        intlOppty.RecordTypeId = GlobalUtility.getRecordTypeId('Opportunity', 'Medical_Aesthetics_Capital_Sales_Opportunity');
        intlOppty.AccountId = custAccInternational.Id;
        insert intlOppty;
        
        Opportunity testIntlOppty = [SELECT Id, CurrencyIsoCode, Pricebook2Id from Opportunity where Id = :intlOppty.Id];

        //System.assertEquals('CAD', testIntlOppty.CurrencyIsoCode);
        //System.assertEquals(pb1.Id, testIntlOppty.Pricebook2Id);

        Test.stopTest();


        
    }
     static testMethod Opportunity ValidateGrowthMappingFields(){
        //setup configuration settings
        TestUtility.setupConfigurationSettings();
        //insert triggerswitch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
            
                 

        //insert account
        Acc=TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert Acc;
        //System.assertEquals('Customer Account', Acc.Name);
        //insert opportunity
        Validation_Rule_Exception__c VExpRec = new Validation_Rule_Exception__c();
         VExpRec.Opportunity_validations__c = true;
         insert VExpRec;
       Opportunity opp = TestUtility.newOpportunity('Test Opportunity',Acc.Id,date.today(),'Confirm','Expected');
       opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
             opp.Aware_of_Hologic__c ='1'; 
         
             opp.Hologic_personnel_known__c ='2'; 
         insert opp;
         opp.Aware_of_Hologic__c ='1'; 
         opp.Hologic_personnel_known__c ='1'; 
         opp.Contract_signed_CSS__c='1';
         Opp.Contractual_obligations_fulfilled__c='1';
                      
             Test.startTest();         
          try{
                  update opp;
           }
           catch(exception e){
               
           }
             test.stopTest(); 
              
        Opportunity oppty = [select id,Name,Accountid,stageName,RecordTypeId from Opportunity where id=:opp.id];
        System.assertEquals('Test Opportunity', oppty.Name);
                  
         return oppty;   
                        
         }
    static testMethod Opportunity ValidateGrowthMappingFields1(){
        //setup configuration settings
        TestUtility.setupConfigurationSettings();
        //insert triggerswitch
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'OpportunityTrigger';
        ts.Active__c = true;
        insert ts;
            
                 

        //insert account
        Acc=TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert Acc;
        //System.assertEquals('Customer Account', Acc.Name);
        //insert opportunity
        Validation_Rule_Exception__c VExpRec = new Validation_Rule_Exception__c();
         VExpRec.Opportunity_validations__c = false;
         insert VExpRec;
       Opportunity opp = TestUtility.newOpportunity('Test Opportunity',Acc.Id,date.today(),'Confirm','Expected');
       opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Diagnostics_Sales_Opportunity')).substring(0,15));
             opp.Aware_of_Hologic__c ='1'; 
         
             opp.Hologic_personnel_known__c ='2'; 
         insert opp;
         opp.Aware_of_Hologic__c ='1'; 
         opp.Hologic_personnel_known__c ='1'; 
         opp.Contract_signed_CSS__c='1';
         Opp.Contractual_obligations_fulfilled__c='1';
                      
             Test.startTest();         
          try{
                  update opp;
           }
           catch(exception e){
               
           }
             test.stopTest(); 
              
        Opportunity oppty = [select id,Name,Accountid,stageName,RecordTypeId from Opportunity where id=:opp.id];
        System.assertEquals('Test Opportunity', oppty.Name);
                  
         return oppty;   
                        
         }
     
     
        
  
}