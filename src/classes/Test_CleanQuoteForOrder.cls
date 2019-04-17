/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Test class to validate UpdateQuoteLineTest from SBQQ_QuoteTrigger
                Tests Excecuted:

                UpdateQuoteLineTest - verifies that key null quote line items are set from the quote when order "sent"
                testDefaultOperatingUnit - verifies that salesrep operating unit is written to the quote
History:
<Date>          <Authors Name>      <Brief Description of Change>
06/15/2016      Marc Goldstein      Initial Creation
06/21/2016      Marc Goldstein      Added testDefaultOperatingUnit() to test defaulting of operating unit
------------------------------------------------------------*/

@isTest 
private class Test_CleanQuoteForOrder 
{
    private static Account parent;
    

    static testMethod void UpdateQuoteLineTest() 
    {

        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('sitelocTrigger');        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
        
        parent = TestUtility.newAccount('CustAccount-', 'custParty', null, null, GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert parent;

        Site_Location__c shipLocation = new Site_Location__c();
        shipLocation = TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street','Suite 2','','','Philadelphia','PA','19123','US', parent.Oracle_Party_Id__c, parent.Id,true);
        shipLocation.Ship_To__c=true;
        shipLocation.Deliver_to__c = true;
        shipLocation.Active__c=true;

        insert shipLocation;


        Site_Location__c billLocation = new Site_Location__c();
        billLocation = TestUtility.newSiteLocation('123 A Street Suite 1', '123 A Street','Suite 2','','','Philadelphia','PA','19123','US', parent.Oracle_Party_Id__c, parent.Id,true);
        billLocation.Bill_To__c=true;
        billLocation.Active__c=true;

        insert billLocation;

        

        Id pricebookId = Test.getStandardPricebookId();

        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = parent.Id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        newOpp.Pricebook2Id = pricebookId;
        newOpp.RecordTypeId=GlobalUtility.getRecordTypeId('Opportunity','Surgical_Open_Opportunity');
      
        insert newOpp;


        //Create Products
        List<Product2> prodList=new List<Product2>();
        for(Integer i=0; i<=5; i++){
            String prodName='Product ' + string.valueOf(i);
            prodList.add(new Product2(Name = prodName, IsActive = true, Quotable__c = true));
        }

        insert prodList;
        

        //Create Price Book Entries
        //List<PricebookEntry> priceentires=new List<PricebookEntry>();

      //  for(Integer i=0; i<=5; i++){
    //        priceentires.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(i).id, UnitPrice= 2000.00, IsActive = true));
  //      }

 //       insert priceentires;
        
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=parent.Id
            , SBQQ__Opportunity2__c=newOpp.id
            ,ShipTo_Site__c = shipLocation.Id
            ,BillTo_Site__c=billLocation.Id
            ,DeliverTo_Site__c=shipLocation.Id, FOB__c='ORIGIN',
            Operating_Unit__c='HOLX_US_OU',Order_Type__c='DANBURY SYSTEM ORDER',Shipping_Method_Code__c='3-3 DAY',
            Payment_Terms_Freight__c='CFR',SBQQ__PaymentTerms__c='0-20-80',Ship_Date__c=system.today(),Requested_Date__c=system.today(),SBQQ__SalesRep__c=userinfo.getUserId(),SBQQ__SubscriptionTerm__c=2);
 q.Create_Order__c=false;
        insert q;
       
         SBQQ__Quote__c q1=new SBQQ__Quote__c(SBQQ__Account__c=parent.Id
            , SBQQ__Opportunity2__c=newOpp.id
            ,ShipTo_Site__c = shipLocation.Id
            ,BillTo_Site__c=billLocation.Id
            ,DeliverTo_Site__c=shipLocation.Id, FOB__c='ORIGIN',
            Operating_Unit__c=null,Shipping_Method_Code__c='3-3 DAY',
            Payment_Terms_Freight__c='CFR',SBQQ__PaymentTerms__c='0-20-80',Ship_Date__c=system.today(),Requested_Date__c=system.today(),SBQQ__SalesRep__c=userinfo.getUserId(),SBQQ__SubscriptionTerm__c=2,ApprovalStatus__c='Executed');
 q.Create_Order__c=false;
        insert q1;
         List<SBQQ__QuoteLine__c> quoteLines=new List<SBQQ__QuoteLine__c>();

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1,FOB__C=null));
        }

        for(Integer i=0; i<=5; i++){
            quoteLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodList.get(i).Id ,  SBQQ__ListPrice__c = 100, SBQQ__Quantity__c=1, Include_In_Order__c=false,FOB__C=null));
        }

        insert quoteLines;
        
          List<SBQQ__Quote__c> qu=[select id,SBQQ__Account__c,ApprovalStatus__c,SBQQ__Opportunity2__c,ShipTo_Site__c,BillTo_Site__c,DeliverTo_Site__c,
                              Operating_Unit__c,FOB__c,Payment_Terms_Freight__c,SBQQ__PaymentTerms__c,Shipping_Method_Code__c,
                              Ship_Date__c,Requested_Date__c,SBQQ__SalesRep__c,SBQQ__SubscriptionTerm__c,Create_Order__c,QuoteLines_Ready_for_Order__c from SBQQ__Quote__c where id =: q.id];
        
         
        List<SBQQ__Quote__c> quoteList=new  List<SBQQ__Quote__c>();
        quoteList.add(q);
        
          List<SBQQ__Quote__c> quoteList1=new  List<SBQQ__Quote__c>();
         quoteList1.add(q1);
         Map<Id,SBQQ__Quote__c> QuoteMap=new Map<Id,SBQQ__Quote__c>(quoteList);
        qu[0].ApprovalStatus__c='Executed';
    qu[0].Create_Order__c=true;
         //quoteList[0].QuoteLines_Ready_for_Order__c =0;
        update qu;
        
    
        
         CleanQuoteForOrder.CreateOrder(qu,QuoteMap);
        CleanQuoteForOrder.SetOperatingUnit(quoteList1, QuoteMap);

       
       
        
        //will break below 6 (system validation)
        Integer cnt=1;
        Id qlID;
        for(SBQQ__QuoteLine__c ql : quoteLines){
            if (cnt==1)
                qlID=ql.Id;
            if (cnt>6)
                ql.SBQQ__RequiredBy__c=qlID;
            cnt++;
        
            if(ql.Ready_For_Integration__c==true){
            //ql.Include_In_Order__c = true;
            ql.Received_By_Integration__c = false;
            ql.ShipTo_Site__c = null;
            ql.DeliverTo_Site__c = null;
            ql.BillTo_Site__c = null;
            ql.Ship_To_Account__c = null;
            ql.FOB__c = null;
            ql.Shipping_Method_Code__c = null;
            }
            
            
        }
        update quoteLines;
       

        List<Id> quoteIDs = new List<Id>();
        quoteIDs.add(q.Id);


        Test.startTest();

        List<SBQQ__QuoteLine__c> ql = [Select ShipTo_Site__c,SBQQ__Quote__r.ShipTo_Site__c
            ,DeliverTo_Site__c,SBQQ__Quote__r.DeliverTo_Site__c 
            ,BillTo_Site__c,SBQQ__Quote__r.BillTo_Site__c
            ,Ship_To_Account__c,SBQQ__Quote__r.Ship_To_Account__c
            ,Deliver_To_Account__c,SBQQ__Quote__r.Deliver_To_Account__c
            ,Bill_To_Account__c,SBQQ__Quote__r.Bill_To_Account__c
            ,FOB__c,SBQQ__Quote__r.FOB__c
            ,Ship_Date__c,SBQQ__Quote__r.Ship_Date__c
            ,Requested_Date__c,SBQQ__Quote__r.Requested_Date__c
            ,Payment_Terms__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c
            ,Shipping_Method_Code__c, SBQQ__Quote__r.Shipping_Method_Code__c
            ,Ready_For_Integration__c,SBQQ__Quote__r.SBQQ__SalesRep__c
            from SBQQ__QuoteLine__c where Ready_For_Integration__c=true];
            
         System.debug('Hello World:'+ql);
         CleanQuoteForOrder.updateItemsFromQuote(ql);
        //CleanQuoteForOrder.validateAllComponensSelected(ql);
       
         
        
        for(SBQQ__QuoteLine__c l : ql){
            System.assertEquals(l.ShipTo_Site__c,l.SBQQ__Quote__r.ShipTo_Site__c);
            System.assertNotEquals(l.ShipTo_Site__c,null);
        }

        List<SBQQ__QuoteLine__c> ql2 = [Select ShipTo_Site__c,SBQQ__Quote__r.ShipTo_Site__c
            ,DeliverTo_Site__c,SBQQ__Quote__r.DeliverTo_Site__c 
            ,BillTo_Site__c,SBQQ__Quote__r.BillTo_Site__c
            ,Ship_To_Account__c,SBQQ__Quote__r.Ship_To_Account__c
            ,Deliver_To_Account__c,SBQQ__Quote__r.Deliver_To_Account__c
            ,Bill_To_Account__c,SBQQ__Quote__r.Bill_To_Account__c
            ,FOB__c,SBQQ__Quote__r.FOB__c
            ,Ship_Date__c,SBQQ__Quote__r.Ship_Date__c
            ,Requested_Date__c,SBQQ__Quote__r.Requested_Date__c
            ,Payment_Terms__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c
            ,Shipping_Method_Code__c, SBQQ__Quote__r.Shipping_Method_Code__c
            ,Ready_For_Integration__c 
            from SBQQ__QuoteLine__c where Ready_For_Integration__c=false];
        
        for(SBQQ__QuoteLine__c l2 : ql2){
            System.assertNotEquals(l2.ShipTo_Site__c,l2.SBQQ__Quote__r.ShipTo_Site__c);
            System.assertEquals(l2.ShipTo_Site__c,null);
        }

        Test.stopTest();

    }   

    static testMethod void testDefaultOperatingUnit()
    {
        /*
        Trigger_Switch__c cs1 = new Trigger_Switch__c(name = 'CreateContractAgreePrice', Active__c = true);
        insert cs1;
        Trigger_Switch__c cs2 = new Trigger_Switch__c(name = 'SBQQ_QuoteTrigger', Active__c = true);
        insert cs2;     
        */
        TestUtility.setupConfigurationSettings();        
        
        Trigger_Switch__c tsop= new Trigger_Switch__c();
        tsop.Name = 'OpportunityTrigger';
        tsop.Active__c = true;
        insert tsop;
                 
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'Contracttrigger';
        ts.Active__c = true;
        insert ts;
           
        Account acc = TestUtility.newAccount('Account0', 'Account0');
        insert acc;
        Contract contract = new Contract();
        contract.AccountId = acc.Id;
        contract.Status = 'Draft';
        contract.StartDate = System.today();
        contract.Contract_End_Date__c = System.today() + 5;
        insert contract;
       
        contract.Status = 'Activated';
        update contract;
       
        Id pricebookId = Test.getStandardPricebookId();

        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = acc.Id;
        newOpp.StageName = 'Target';
        newOpp.CloseDate = System.today();
        newOpp.Name = 'OppTest';
        //newOpp.Pricebook2Id = pb2.Id;
        insert newOpp;
        
        User spUser=TestUtility.newUser(UserInfo.getProfileId(), 'JoeSmith');
        spUser.operating_unit__c='HOLX_BE_OU';
        insert spUser;


        //fails with 200
        SBQQ__Quote__c q=new SBQQ__Quote__c(SBQQ__Account__c=acc.Id , SBQQ__Opportunity2__c=newOpp.id,SBQQ__PriceBook__c=pricebookId);
 
        insert q;

        q.SBQQ__SalesRep__c=spUser.Id;
        update q;
        
        for(SBQQ__Quote__c sbq : [Select SBQQ__SalesRep__r.Operating_Unit__c, Operating_Unit__c from SBQQ__Quote__c where Id=:q.Id]){
            System.assertEquals(sbq.SBQQ__SalesRep__r.Operating_Unit__c, 'HOLX_BE_OU');
            System.assertNotEquals(sbq.Operating_Unit__c, 'HOLX_BE_OU');
            
        }

        
    }

}