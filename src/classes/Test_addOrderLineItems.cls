/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Company:    Salesforce.com
Description:  Test class to validate CaseAddOrderLineItems page and addOrderLineItems extension controller
        Tests Excecuted:
        
         init - verifies that the test data gets created successfully
        
        addLineItems - verifies that the page can add the line items successfully
        
        loadAddedLineItems - verifies that existing Line items are loaded successfully
        
        errorHandling - verifies that errors are handled when there is no Order associated to the Install Case
        
 History:
<Date>      <Authors Name>    <Brief Description of Change>
08/01/2016  Mani Sundaresan    Initial Creation
09/15/2017  Raj Sharan         Update for Trigger Switch and Product Source Division
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_addOrderLineItems{
    
    static Account custAccount;
    static PageReference pageRef;
    static addOrderLineItems aol;
    static User otherUser;
    static final Id runningUserId = UserInfo.getUserId();
    // Added to address Products needing a Product Source Division for Order related activities. 
    private static Product_Source_Division__c psd; 

    static{
        TestUtility.setupConfigurationSettings();        
        
         // 13/09/2017-Krishna Prasad & Raj Sharan -Added trigger switch to fix order item Trigger isuue  
         TestUtility.insertCustSetting('OrderLineProductReplacement');         
         TestUtility.insertCustSetting('CaseTrigger');
         TestUtility.insertCustSetting('WorkOrderTrigger');                 
         TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('sitelocTrigger');

    }
    
    private static void init(){
    
        // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert custAccount;
        
        //insert an User
        otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
        insert otherUser;

        // Added to address Products needing a Product Source Division for Order related activities. 
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;

        //insert a Product
        Product2 p2 = TestUtility.newProduct('Test Product');
        p2.Product_Source_Division__c = psd.Id;
        insert p2;
        
        //insert Pricebook
        Pricebook2 pb2 =TestUtility.newPricebook('Test Pricebook');
        insert pb2;
        
        //insert PricebookEntry
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb2.Id,p2.Id,double.valueOf('1.0000'));
        insert pbe;
        
        //insert an Opportunity
        Opportunity opp = TestUtility.newOpportunity('Test Oppty',custAccount.Id,Date.Today(),'Target',null);
        insert opp;
        
        Order orde1 = TestUtility.newOrder(custAccount.Id,pb2.Id,null,'BOOKED',Date.Today());
        insert orde1;
        
        Site_Location__c siteloc = new Site_Location__c(Name = 'Test Site',Account__c =custAccount.Id,Address_Line_1__c = 'Test');
        insert siteloc;
        
        
        //insert an Order
        Order ord = TestUtility.newOrder(custAccount.Id,pb2.Id,null,'DRAFT',Date.Today());
        ord.Opportunity = opp;
        ord.OriginalOrder = orde1;
        insert ord;
        
       
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        //insert OrderItems
        OrderItem ord1 = TestUtility.newOrderItem(ord.id,null,pbe.Id,Decimal.valueOf('1.00'),Decimal.valueOf('1.00'));
        ord1.Unit_of_Measure__c = 'tes';
        ord1.Ship_To_Site_Location__c = siteloc.id;
        ord1.Scheduled_Ship_Date__c = Date.Today();
        orderItemList.add(ord1);
        
        OrderItem ord2 = TestUtility.newOrderItem(ord.id,null,pbe.Id,Decimal.valueOf('2.00'),Decimal.valueOf('2.00'));
        orderItemList.add(ord2);
        
        
        insert orderItemList;
        
        Id caseRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByName().get('XB&SH Install').getRecordTypeId();
        
         System.runAs(otherUser){
        
        //insert a Case
       
        Case c1 = TestUtility.newCase(custAccount.Id,null,null,null, caseRecordTypeId,'Inquiry','New','Sev 3','');
        c1.Order__c = ord.Id;
        insert c1;
        
        Case c2 = TestUtility.newCase(custAccount.Id,null,null,null, caseRecordTypeId,'Inquiry','New','Sev 2','');
        insert c2;
        
        orderItemList[1].Case__c = c2.Id;
        update orderItemList;
        
        
        }
        
     }
     
       static testMethod void errorHandling(){
         
         init();
         Case c1 = [SELECT Id from Case where RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByName().get('XB&SH Install').getRecordTypeId() and Priority = 'Sev 2'];
         c1.Order__c = null;
         update c1;
         
         pageRef = Page.CaseAddOrderLineItems;
         Test.setCurrentPage(pageRef);
         
         ApexPages.StandardController con = new ApexPages.StandardController(c1);
         ApexPages.currentPage().getParameters().put('id',c1.id);
         ApexPages.currentPage().getParameters().put('Order','');
         aol = new addOrderLineItems(con);
         
         Test.startTest();
        
            // Check that the error message you are expecting is in pageMessages
            Boolean messageFound = false;

            for(ApexPages.Message message : ApexPages.getMessages()) {
                System.debug('Messages:'+message.getDetail());
                 system.assert(message.getDetail().contains('An Order is not associated to this Case. Kindly select an Order on the Case to add Line Items.'));   
            }

         System.assertEquals(true,aol.noOrder);
         
         Test.stopTest();
         
     }
     
     static testMethod void addLineItems(){
     
         init();
         
         Case c1 = [SELECT Id from Case where RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByName().get('XB&SH Install').getRecordTypeId() and Priority = 'Sev 3'];
         Order ord = [SELECT Id from Order where Status = 'DRAFT'];
         c1.Order__c = ord.Id;
         //OrderItem oli = [SELECT Id, Case__c from OrderItem limit 1];
         
         pageRef = Page.CaseAddOrderLineItems;
         pageRef.getParameters().put('id',c1.id);
         pageRef.getParameters().put('Order',ord.Id);
        
         Test.setCurrentPage(pageRef);
        
         ApexPages.StandardController con = new ApexPages.StandardController(c1);
         aol = new addOrderLineItems(con);
         
         Test.startTest();
         
         System.assertEquals(2,aol.getOrderItem().size());
       
         aol.getOrderItem()[0].selected = true;
         pageRef.getParameters().put('OrderItem', aol.getOrderItem()[0].oi.Id);
         pageRef.getParameters().put('Selected','true');
         
         aol.setSelected();
         
         aol.getOrderItem()[1].selected = true;
         pageRef.getParameters().put('OrderItem', aol.getOrderItem()[0].oi.Id);
         pageRef.getParameters().put('Selected','true');
         
         aol.setSelected();
         
         //aol.disabledChkBox = true;
         
         aol.processSelected();
         
         System.assertEquals(2,[SELECT Count() from OrderItem where Case__c = :c1.Id]);
         
         
                    
         aol.Previous();
         aol.Next();
         aol.getDisablePrevious();
         aol.getDisableNext();
         
         
         con = new ApexPages.StandardController(c1);
         aol = new addOrderLineItems(con);
         
         aol.getOrderItem();
         
         
         Test.stopTest();
     
     }
     
     static testMethod void loadAddedLineItems(){
         
          init();
         
          Case c1 = [SELECT Id from Case where RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByName().get('XB&SH Install').getRecordTypeId() and Priority = 'Sev 3'];
          Order ord = [SELECT Id from Order where Status = 'DRAFT'];
          
         
          pageRef = Page.CaseAddOrderLineItems;
          pageRef.getParameters().put('id',c1.id);
          pageRef.getParameters().put('Order',ord.Id);
        
          Test.setCurrentPage(pageRef);
        
          ApexPages.StandardController con = new ApexPages.StandardController(c1);
          aol = new addOrderLineItems(con);
         
          Test.startTest();
          
          aol.getOrderItem();
          
          Test.stopTest();
          
     }
     
     static testMethod void removeAddedLineItems(){
         
         init();
         
         Case c1 = [SELECT Id from Case where RecordTypeId = :Schema.SObjectType.Case.getRecordTypeInfosByName().get('XB&SH Install').getRecordTypeId() and Priority = 'Sev 2'];
         //insert an Opportunity
         Opportunity opp = TestUtility.newOpportunity('Test Oppty',custAccount.Id,Date.Today(),'Target',null);
         insert opp;
         
         Order ord = [SELECT Id, OpportunityId from Order where Status = 'DRAFT'];
         ord.OpportunityId = opp.Id;
         //update ord;
         
         List<OrderItem> ordItem = [SELECT Id, Case__c, OriginalOrderItemId from OrderItem where Order.Id = :ord.Id];
         
        
         c1.Order__c = ord.Id;
         update c1;
         
         Site_Location__c siteloc = new Site_Location__c(Name = 'Test Site',Account__c =custAccount.Id,Address_Line_1__c = 'Test');
         insert siteloc;
         
         for(OrderItem oi : ordItem){
             oi.Case__c = c1.Id;
             oi.Unit_of_Measure__c = null;
             oi.Ship_To_Site_Location__c = null;
             oi.Scheduled_Ship_Date__c = null;
             //oi.OriginalOrderItemId = oi.Id;
         }
         update ordItem;
         
         pageRef = Page.CaseAddOrderLineItems;
         Test.setCurrentPage(pageRef);
         
         ApexPages.StandardController con = new ApexPages.StandardController(c1);
         ApexPages.currentPage().getParameters().put('id',c1.id);
         ApexPages.currentPage().getParameters().put('Order',ord.Id);
         aol = new addOrderLineItems(con);
         
         Test.startTest();
         
         aol.getOrderItem();
         
         aol.getOrderItem()[1].selected = false;
                  
         aol.processSelected();
         
         aol.OffsetSize = 0;
         aol.getDisablePrevious();
         
         aol.QueryLimit = 0;
         aol.getDisableNext();
         
         Test.stopTest();
         
         
         
     
     }
     
     
   
}