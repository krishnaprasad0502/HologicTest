/*----------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Test class to validate DeliveryInfoDetails Apex class used for B&SH Install Case Email Template
        Tests Excecuted:
        
        myUnitTest - 
        
 History:
<Date>      <Authors Name>    <Brief Description of Change>
08/19/2016  Mani Sundaresan    Initial Creation(US1334)
09/15/2017  Raj Sharan         Update for Custom Settings for Trigger Switch
-------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_DeliveryInfoDetails{

    //Variable Declaration Section
    static Account custAccount;
    static PageReference pageRef;
    static addOrderLineItems aol;
    static User otherUser;
    static final Id runningUserId = UserInfo.getUserId();
    private static Product_Source_Division__c psd; 

    static{
        TestUtility.setupConfigurationSettings();
        // 13/09/2017-Krishna Prasad & Raj Sharan -Added trigger switch to fix case Trigger isuue  
         TestUtility.insertCustSetting('CaseTrigger');
         TestUtility.insertCustSetting('WorkOrderTrigger');
         TestUtility.insertCustSetting('OrderLineProductReplacement');
         TestUtility.insertCustSetting('OpportunityTrigger');
        // INSERTED BY RL 04/03/2018
        TestUtility.insertCustSetting('sitelocTrigger');
                
    }
    
    public static testMethod void myUnitTest(){
    
         // insert an account
        custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert custAccount;
        
        //insert an User
        otherUser = TestUtility.newUser(UserInfo.getProfileId(), 'other');
        insert otherUser;
 
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;

        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
       
        //insert a Product
        Product2 p2 = TestUtility.newProduct('Test Product TRADE');
        p2.Product_Source_Division__c = psd.Id;
        insert p2;
        
        Product2 p3 = TestUtility.newProduct('Test Product');
        p3.Product_Source_Division__c = psd1.Id;
        insert p3;
        
        //insert Pricebook
        Pricebook2 pb2 =TestUtility.newPricebook('Test Pricebook');
        insert pb2;
        
        //insert PricebookEntry
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb2.Id,p2.Id,double.valueOf('1.0000'));
        insert pbe;
        
        //insert PricebookEntry
        PricebookEntry pbe1 = TestUtility.newPricebookEntry(pb2.Id,p3.Id,double.valueOf('2.0000'));
        insert pbe1;
        
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
        
       
//RL STILL NEEDED ?? DeliveryInfoDetails seems to need a CASE       
// OLD CODE        Id caseRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByName().get('B&SH Install').getRecordTypeId();
         Id caseRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        
         //insert a Case
        Case c1 = TestUtility.newCase(custAccount.Id,null,null,null, caseRecordTypeId,'Inquiry','New','Sev 3','');
        c1.Order__c = ord.Id;
        c1.Delivery_Date__c = System.now();
        c1.Confirmed_Install_Date__c = System.today();
        c1.Pickup_Date_Time__c =System.now();
        
        insert c1;
        
        
//RL STILL NEEDED ??        
//        Id workOrderRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('Install/Upgrade/Move').getRecordTypeId(); 
        
           //insert WorkOrder
        //WorkOrder wo = TestUtility.newWorkOrder(custAccount.Id, caseList[0].Id,null,workOrderRecordTypeId, 'New');
        //insert wo;
        
        
          List<OrderItem> orderItemList = new List<OrderItem>();
        //insert OrderItems
        OrderItem ord1 = TestUtility.newOrderItem(ord.id,null,pbe.Id,Decimal.valueOf('1.00'),Decimal.valueOf('1.00'));
        ord1.Unit_of_Measure__c = 'tes';
        ord1.Ship_To_Site_Location__c = siteloc.id;
        ord1.Scheduled_Ship_Date__c = Date.Today();
        ord1.PricebookEntryId = pbe.Id;
        ord1.Case__c = c1.Id;
        orderItemList.add(ord1);
        
        OrderItem ord2 = TestUtility.newOrderItem(ord.id,null,pbe1.Id,Decimal.valueOf('2.00'),Decimal.valueOf('2.00'));
        ord2.Case__c = c1.Id;
        ord2.Unit_of_Measure__c = 'tes';
        ord2.Ship_To_Site_Location__c = siteloc.id;
        ord2.Scheduled_Ship_Date__c = Date.Today();
        ord2.PricebookEntryId = pbe1.Id;
        orderItemList.add(ord2);
        
        
        insert orderItemList;
        
        
        System.runAs(otherUser){
        
        Test.startTest();
        
        
        DeliveryInfoDetails controller = new DeliveryInfoDetails();
        controller.caseVal = c1;
        controller.getOrderLineItems();
        controller.getDeliveryTime();
        System.assertEquals(Date.today(),controller.Today);
        System.assertEquals(Date.today(),controller.getDeliveryDate());
        //System.assertEquals(System.now().addSeconds(1).format('hh:mm:ss a'),controller.getDeliveryTime());
        System.assertEquals(Date.today().format(),controller.getconfirmInstall());
        //SYstem.assertEquals(System.now().format(),controller.getpickupDateandTime());
        
        DeliveryInfoDetails controller1 = new DeliveryInfoDetails();
        controller1.caseVal = null;
        System.assertEquals(Date.today(),controller1.Today);
        System.assertEquals(null,controller1.getDeliveryDate());
        System.assertEquals(null,controller1.getDeliveryTime());
        System.assertEquals(null,controller1.getconfirmInstall());
        SYstem.assertEquals(null,controller1.getpickupDateandTime());
       
        Test.stopTest();
        
        }
     }

}