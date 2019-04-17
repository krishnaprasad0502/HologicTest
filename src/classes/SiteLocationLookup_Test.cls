/*------------------------------------------------------------
Author:     Kasmoor Reddy
Company:    Apps Associates
Description:  Test class to validate SiteLocationLookup apex class
Tests Excecuted: SiteLocationLookupMethod--This method is to validate
                 whether the records are displayed based on the specific 
                 criteria.
                
History:
<Date>        <Authors Name>   <Brief Description of Change>
06/05/2017    Kasmoor Reddy    Initial Creation(US3714) 
------------------------------------------------------------*/
@isTest
public class SiteLocationLookup_Test {
    //Varaiable Declaration
    private static Configuration_Settings__c orgDefaults;
    private static Account siteAccount;
    static testMethod void SiteLocationLookupMethod()
    {
        orgDefaults = TestUtility.setupConfigurationSettings();
         //Trigger switch for 'AccountTrigger'
        TestUtility.insertCustSetting('AccountTrigger');
         //Trigger switch for 'OpportunityTrigger'
        TestUtility.insertCustSetting('OpportunityTrigger');
         //Trigger switch for 'ContractTrigger'
        TestUtility.insertCustSetting('ContractTrigger');
         //Trigger switch for 'sitelocTrigger'
        TestUtility.insertCustSetting('sitelocTrigger');
        
        
        // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }
        
        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){
            
            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        insert accList;
        System.assertNotEquals(accList,null,'success');
        // Insert siteAccount
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';    
        
        insert siteAccount;
         System.assertEquals('Site Account', siteAccount.Name);
        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
       
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='',Address_Line_3__c='test2', Account__c = siteAccount.id, Active__c = true));
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='test1',Address_Line_3__c='', Account__c = siteAccount.id, Active__c = true));
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='',Address_Line_3__c='', Account__c = siteAccount.id, Active__c = true));
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='test1',Address_Line_3__c='test2', Account__c = siteAccount.id, Active__c = true));
        //Insert Site Location
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
        system.debug('siteList----'+siteList);
        List<Site_Location__c> siterecords=[select id,Account__c,Account__r.ParentId from Site_Location__c];
        system.debug(siterecords);
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        //Insert Products
        insert prodList;
        
        
        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();
        
        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }
        
        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'Test' ));
        }
        //Insert Contract 
        System.assertNotEquals(contractList,null,'success');
        insert contractList;
        
        
        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   
        
        //Update Contract
        System.assertNotEquals(contractList,null,'success');
        update contractList;
        //Insert Agreed Price
        System.assertNotEquals(agree_price_lines,null,'success'); 
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);
        
        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        //Insert Customer Eligible Contract for an Account
        System.assertNotEquals(eligible,null,'success'); 
        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c,Tier__c from Customer_Eligible_Contract__c]);
        system.debug(cecs);
        
        
        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        //Insert Opportunities
        
        insert newOpp;
        System.assertEquals('OppTest',newOpp.Name);
        
        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        insert q;
         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,SBQQ__Number__c=i+1,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today()));
        }
        //Insert Quote Lines
        System.assertNotEquals(quoteLines,null,'success');
        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //Reference to the VFPage SiteLocationPopup
        PageReference pageRef = Page.SiteLocationPopup;
        //Set Current Page to the VfPage 'SiteLocationPopup'
        Test.setCurrentPage(pageRef);
        //Set a value to the variables passed through URL from VFPage and referred in SiteLocationLookup Class 
        ApexPages.currentPage().getParameters().put('linenum','1');
        ApexPages.currentPage().getParameters().put('a','2');
        ApexPages.currentPage().getParameters().put('oN',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('oN1',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('billaccid',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('delaccid',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('delaccid1',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('billaccid1',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('qlineid',quoteLines[0].id);
        ApexPages.currentPage().getParameters().put('qlsize','0');
        
        //Start Test 
        Test.startTest();
        //Create a object the Class 'SiteLocationLookup'
        SiteLocationLookup s=new SiteLocationLookup();
        //set values to variables in 'SiteLocationLookup'
        s.shiptositepopup='shiplocation';
        s.shiptositepopupline='shiplocation';
        s.shiptositepopupid='shiplocation';
        s.shiptositepopuplineid='shiplocation';
        s.billtositepopupid='shiplocation';
        s.billtositepopuplineid='shiplocation';
        s.devtositepopupline='shiplocation';
        s.devtositepopuplineid='shiplocation';
        s.billtositepopup='shiplocation';
        s.billtositepopupline='shiplocation';
        s.devtositepopup='shiplocation';
        s.devtositepopupline='shiplocation';
        s.devtositepopupid='shipLocation';
        //Call methods in the Class
        s.displayRecords();
        s.Search();
        s.searchStringLine='siteName';
        s.Search();
        s.searchStringLine='SiteLocation';
        s.Search();
        s.searchStringLine='';
        s.searchString='siteName';
        s.Search();
         s.searchString='SiteLocation';
        s.Search();
        s.searchString='';
        s.searchStringbill='siteName';
        s.Search();
        s.searchStringbill='';
        s.searchStringbill='SiteLocation';
        s.Search();
        s.searchStringbill='';
        s.searchStringbillline='siteName';
        s.Search();
        
        /*s.Search();
         s.searchStringdelv='SiteLocation';
        s.Search();
        s.searchStringdelv='';
        s.searchStringdelvline='siteName';
        s.Search();
        s.searchStringdelvline='SiteLocation';
        s.Search();*/
        
        
        //set values to the variables that are passed as parameters from VFPage
        ApexPages.currentPage().getParameters().put('shiptositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopuplineid','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopuplineid','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopuplineid','shiplocation');
        
        //Fetch SiteLocation Record 
        /*Site_Location__c sitelocation=[select id,Address_Line_1__c,Address_line_2__c,Address_line_3__c from Site_Location__c limit 1];
        Site_Location__c sitelocation1=[select id,Address_Line_1__c,Address_line_2__c,Address_line_3__c from Site_Location__c where Address_line_3__c='' limit 1];
        //Call the Inner Class Using the Outer Class , Passing Vlaues to Paramiterized Constructor
        SiteLocationLookup.InnerClass display=new SiteLocationLookup.InnerClass(sitelocation.id,sitelocation.Address_Line_1__c);
        //Variable Initialization for Inner Class Variables.
        display.Site_id=sitelocation.id;
        display.Site_Address=sitelocation.Address_Line_1__c;*/
     
       
        //stop Test
        Test.stopTest();
        
    }//End of the testmethod.
    
    static testMethod void SiteLocationLookupMethod1()
    {
        orgDefaults = TestUtility.setupConfigurationSettings();
         //Trigger switch for 'AccountTrigger'
        TestUtility.insertCustSetting('AccountTrigger');
         //Trigger switch for 'OpportunityTrigger'
        TestUtility.insertCustSetting('OpportunityTrigger');
         //Trigger switch for 'ContractTrigger'
        TestUtility.insertCustSetting('ContractTrigger');
         //Trigger switch for 'sitelocTrigger'
        TestUtility.insertCustSetting('sitelocTrigger');
        
        
        // Create Account(s)
        List<Account> accList=new List<Account>();
        for(Integer i=0; i<=3; i++){
            String accName='1234567' + string.valueOf(i);
            accList.add(TestUtility.newAccount(accName, accName));
        }
        
        //insert accList;
        
        Integer k=0;
        for(Account acc:accList){
            
            acc.Oracle_Party_Id__c=String.valueOf(k);
            k++;
        }
        insert accList;
        System.assertNotEquals(accList,null,'success');
        // Insert siteAccount
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
        siteAccount.BillingCountryCode = 'US';
        siteAccount.BillingStateCode = 'NY';    
        
        insert siteAccount;
         System.assertEquals('Site Account', siteAccount.Name);
        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'site'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName,Address_Line_2__c='test1',Address_Line_3__c='test2', Account__c = siteAccount.id, Active__c = true));
        }
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='',Address_Line_3__c='test2', Account__c = siteAccount.id, Active__c = true));
         siteList.add(new Site_Location__c(Name='siteName', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='test1',Address_Line_3__c='', Account__c = siteAccount.id, Active__c = true));
         siteList.add(new Site_Location__c(Name='siteName1', Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = 'siteName',Address_Line_2__c='',Address_Line_3__c='', Account__c = siteAccount.id, Active__c = true));
        //Insert Site Location
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
        system.debug('siteList----'+siteList);
         List<Site_Location__c> siterecords=[select id,Account__c,Account__r.ParentId from Site_Location__c];
        system.debug(siterecords);
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        //Insert Products
        insert prodList;
        
        
        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();
        
        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }
        
        //insert priceentires;
        
        //Create Contract(s) for each Account
        List<Contract> contractList=new List<Contract>();
        for(Integer i=0; i<=3; i++){
            String conName='Test Contract ' + string.valueOf(i);
            contractList.add(new Contract(StartDate=system.today().addDays(-5), Accountid=accList.get(i).id, Contract_End_Date__c=system.today().addYears(10),Contract_Source__c = 'test' ));
        }
        //Insert Contract 
        System.assertNotEquals(contractList,null,'success');
        insert contractList;
        
        
        //Create Pricing Agreement Lines for each Contract
        List<Agreed_Price__c> agree_price_lines=new List<Agreed_Price__c>();
        
        for(Contract con:contractList){
            for(Integer i=0; i<=5; i++){
                agree_price_lines.add(new Agreed_Price__c(Active__c=true, Contract__c=con.id, Start_Date__c=system.today().addDays(-5), End_Date__c=system.today().addDays(10), Price__c=2000.00, Product__c=prodList.get(i).id));
            }
            con.Status='Activated';
        }   
        
        //Update Contract
        System.assertNotEquals(contractList,null,'success');
        update contractList;
        //Insert Agreed Price
        System.assertNotEquals(agree_price_lines,null,'success'); 
        insert agree_price_lines;
        
        
        system.debug(agree_price_lines);
        
        //Create Relationship/Predence for an Account (Custom Agreement Relationship)
        List<Customer_Eligible_Contract__c> eligible=new List<Customer_Eligible_Contract__c>();
        for(Integer i=0; i<=3; i++){
            eligible.add(new Customer_Eligible_Contract__c(Selected__c=true, Contract__c=contractList.get(i).id, Effective_Date__c=system.today(),Expiration_Date__c=system.today().addYears(1),  Customer_Account__c=accList.get(0).id, Precedence_Value__c=i));
        }
        //Insert Customer Eligible Contract for an Account
        System.assertNotEquals(eligible,null,'success'); 
        insert eligible;
        List<Customer_Eligible_Contract__c> cecs=new List<Customer_Eligible_Contract__c>([Select id, Contract__c, Agreement_Active__c,Tier__c from Customer_Eligible_Contract__c]);
        system.debug(cecs);
        
        
        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        //Insert Opportunities
        
        insert newOpp;
        System.assertEquals('OppTest',newOpp.Name);
        
        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today());
        insert q;
         System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap=new Map<Id,SBQQ__QuoteLine__c>();
        
        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=accList.get(1).id, Deliver_To_Account__c=accList.get(2).id, Ship_To_Account__c=accList.get(3).id,SBQQ__Number__c=i+1,BillTo_Site__c= siteList[0].id,ShipTo_Site__c= siteList[0].id,DeliverTo_Site__c= siteList[0].id,Requested_Date__c = system.today()));
        }
        //Insert Quote Lines
        System.assertNotEquals(quoteLines,null,'success');
        //insert quoteLines;
        quotelineMap.putAll(quoteLines);

        if(quotelineMap.size()>0){
            insert quotelineMap.values();
        }
        //Reference to the VFPage SiteLocationPopup
        PageReference pageRef = Page.SiteLocationPopup;
        //Set Current Page to the VfPage 'SiteLocationPopup'
        Test.setCurrentPage(pageRef);
        //Set a value to the variables passed through URL from VFPage and referred in SiteLocationLookup Class 
        ApexPages.currentPage().getParameters().put('linenum','1');
        ApexPages.currentPage().getParameters().put('a','2');
        //ApexPages.currentPage().getParameters().put('oN',acclist[0].id);
        //ApexPages.currentPage().getParameters().put('oN1',acclist[0].id);
        //ApexPages.currentPage().getParameters().put('billaccid',acclist[0].id);
        ApexPages.currentPage().getParameters().put('delaccid',siterecords[0].Account__r.ParentId);
        ApexPages.currentPage().getParameters().put('delaccid1',siterecords[0].Account__r.ParentId);
        //ApexPages.currentPage().getParameters().put('billaccid1',acclist[0].id);
        ApexPages.currentPage().getParameters().put('qlineid',quoteLines[0].id);
        ApexPages.currentPage().getParameters().put('qlsize','0');
        
        //Start Test 
        Test.startTest();
        //Create a object the Class 'SiteLocationLookup'
        SiteLocationLookup s=new SiteLocationLookup();
        //set values to variables in 'SiteLocationLookup'
        s.shiptositepopup='shiplocation';
        s.shiptositepopupline='shiplocation';
        s.shiptositepopupid='shiplocation';
        s.shiptositepopuplineid='shiplocation';
        s.billtositepopupid='shiplocation';
        s.billtositepopuplineid='shiplocation';
        s.devtositepopupline='shiplocation';
        s.devtositepopuplineid='shiplocation';
        s.billtositepopup='shiplocation';
        s.billtositepopupline='shiplocation';
        s.devtositepopup='shiplocation';
        s.devtositepopupline='shiplocation';
        s.devtositepopupid='shipLocation';
        //Call methods in the Class
        //s.displayRecords();
        // s.searchStringbillline='SiteLocation';
      
        s.searchStringbillline='';
        s.searchStringdelv='siteName';
        s.Search();
        s.searchStringbillline='';
        s.searchStringdelv='siteName';
        s.Search();
        s.searchStringdelv='site';
        s.Search();
        s.searchStringdelv='SiteLocation';
        s.Search();
        s.searchStringdelv='';
        s.searchStringdelvline='siteName';
        s.Search();
         s.searchStringdelvline='site';
        s.Search();
        s.searchStringdelvline='SiteLocation';
        s.Search();
        
        s.onselect();
        s.previous();
        s.next();
        s.getprev();
        s.getnxt();
        //set values to the variables that are passed as parameters from VFPage
        ApexPages.currentPage().getParameters().put('shiptositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopuplineid','shiplocation');
        ApexPages.currentPage().getParameters().put('shiptositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('billtositepopuplineid','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopup','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopupline','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopupid','shiplocation');
        ApexPages.currentPage().getParameters().put('devtositepopuplineid','shiplocation');
        
        //Fetch SiteLocation Record 
        Site_Location__c sitelocation=[select id,Address_Line_1__c,Address_line_2__c,Address_line_3__c from Site_Location__c limit 1];
        Site_Location__c sitelocation1=[select id,Address_Line_1__c,Address_line_2__c,Address_line_3__c from Site_Location__c where Address_line_3__c='' limit 1];
        //Call the Inner Class Using the Outer Class , Passing Vlaues to Paramiterized Constructor
        SiteLocationLookup.InnerClass display=new SiteLocationLookup.InnerClass(sitelocation.id,sitelocation.Address_Line_1__c);
        //Variable Initialization for Inner Class Variables.
        display.Site_id=sitelocation.id;
        display.Site_Address=sitelocation.Address_Line_1__c;
     
       
        //stop Test
        Test.stopTest();
        
    }//End of the testmethod.
    
}//End of the test class.