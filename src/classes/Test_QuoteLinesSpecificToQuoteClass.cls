/*------------------------------------------------------------
Author:     Kasmoor Reddy     
Company:    Apps Associates   
Description:Test class for QuoteLinesSpecificToQuoteClass  


History:
<Date>      <Authors Name>    <Brief Description of Change>
11/26/2018   Kasmoor Reddy     Initial Creation (US-)
------------------------------------------------------------*/
@isTest
public class Test_QuoteLinesSpecificToQuoteClass {
/*------------------------------------------------------------
Author:     Kasmoor Reddy     
Company:    Apps Associates   
Description:Test Method for QuoteLinesSpecificToQuoteClass  


History:
<Date>      <Authors Name>    <Brief Description of Change>
11/26/2018   Kasmoor Reddy     Initial Creation (US-)
------------------------------------------------------------*/
    @isTest
    public static void Test_Method1()
    {
       
        TestUtility.setupConfigurationSettings();
        //Create a user to insert accounts
        List<Profile> userProfile = [SELECT Id FROM profile WHERE Name='System Administrator' LIMIT 1];
        User testUser = TestUtility.newUser(userProfile[0].Id,'GetTaxIn');
        testUser.Operating_Unit__c = 'HOLX_US_OU';    
        //User inserted
        insert testUser; 
        //Account
        Account siteAccount;
        List<Account> accList=new List<Account>();
        // Create Account(s)
        system.runAs(testUser)
        {
            
            for(Integer i=0; i<=3; i++){
                String accName='1234567' + string.valueOf(i);
                accList.add(TestUtility.newAccount(accName, accName));
            }
            Integer k=0;
            for(Account acc:accList){
                
                acc.Oracle_Party_Id__c=null;
                k++;
            }
            
            //insert accList;
            
            System.assertNotEquals(accList,null,'success');
            insert accList;
            //insert siteaccount
            
            siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', accLIst[0].id, GlobalUtility.getRecordTypeId('Account', 'Site'));
            siteAccount.BillingCountryCode = 'US';
            siteAccount.BillingStateCode = 'NY';            
            insert siteAccount;
        }
        
        //Create Site Locations
        List<Site_Location__c> siteList = new List<Site_Location__c>();
        for(Integer i=0; i<=3; i++){
            String siteName = 'SiteLocation'+string.valueOf(i);
            siteList.add(new Site_Location__c(Name=siteName, Deliver_To__c = true, Bill_To__c = true, Ship_To__c = true, Address_Line_1__c = siteName, Account__c = siteAccount.id, Active__c = true));
        }
        System.assertNotEquals(siteList,null,'success');
        insert siteList;
        
        
        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true,Description='test product'));
        }
        prodList[0].CPQ_Bundle__c=true;
        System.assertNotEquals(prodList,null,'success');
        insert prodList;
        
        
        //Create Price Book Entries
        PriceBook2 pricebook = new Pricebook2(name='Test Pricebook');
        List<PricebookEntry> priceentires=new List<PricebookEntry>();
        
        for(Integer i=0; i<=5; i++){
            priceentires.add(new PricebookEntry(Pricebook2Id = pricebook.Id, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
        }
        
        //insert priceentires;
        
        //Create Opp
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = accList.get(0).id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebook.Id;
        
        insert newOpp;
        System.assertEquals('OppTest',newOpp.Name);
        
        //Create Quote/Quote Lines
        SBQQ__Quote__c q=new SBQQ__Quote__c(Quote_Name__c='OrderConfirmationPageTest Quote', Order_Type__c='DANBURY SYSTEM ORDER', Operating_Unit__c='HOLX_US_OU', SBQQ__Account__c=accList.get(0).id, SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebook.Id,Requested_Date__c = system.today());
        insert q;
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        
        
        q.SBQQ__Primary__c = false;
        
        update q;
        
        
        //q.SBQQ__Primary__c = false;
        //update q;
        
        System.assertEquals('OrderConfirmationPageTest Quote',q.Quote_Name__c);
        List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();
        set<SBQQ__QuoteLine__c> quoteLineset=new set<SBQQ__QuoteLine__c>();
        //SBQQ__QuoteLine__c q1=new SBQQ__QuoteLine__c();
        
        for(Integer i=0; i<=5; i++){
            quoteLineset.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(i).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,SBQQ__Number__c=i+1,Requested_Date__c = system.today(),Integration_Status__c='E'));
        }
        
        quoteLines.addall(quoteLineset);
        
        //quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, Account__c=accList.get(0).id, Include_In_Order__c=true, SBQQ__Product__c=prodList.get(0).Id, SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Bill_To_Account__c=null, Deliver_To_Account__c=null, Ship_To_Account__c=null,SBQQ__Number__c=6,BillTo_Site__c=null,ShipTo_Site__c=null,DeliverTo_Site__c=null,Requested_Date__c = system.today()));
        
        //quotelineMap.putAll(quoteLines);
        
        System.assertNotEquals(quoteLines,null,'success');
        insert quoteLines;
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        QuoteLinesSpecificToQuoteClass qu=new QuoteLinesSpecificToQuoteClass(sc);
        qu.next();
        qu.previous();
        qu.getnxt();
        qu.getprev();
        qu.OffsetSize=5;
        qu.getprev();
        qu.OffsetSize=0;
        qu.LimitSize=0;
        qu.getnxt();
        qu.ReturnToQuote();
        qu.SaveQuoteLines();
        
        
        
    }
    
}