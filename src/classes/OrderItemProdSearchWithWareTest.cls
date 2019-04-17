@isTest
public class OrderItemProdSearchWithWareTest {
    
    private final static List<String> divisionValues = new List<String>{'BREAST HEALTH', 'SKELETAL HEALTH', null};
    private static User otherUser;
    private static Order testOrder;
    private static Account customerAccount;
    private static List<String> caseRecordTypeNames = new List<String>(GlobalUtility.getAllObjectRecordTypeById('Case').values());  
    private static List<String> caseTypes = GlobalUtility.getFieldPickListValues(Case.Type);
    private static List<String> caseStatuses = GlobalUtility.getFieldPickListValues(Case.Status);
    private static List<String> casePriorities = GlobalUtility.getFieldPickListValues(Case.Priority);
    private static List<String> caseOrigins = GlobalUtility.getFieldPickListValues(Case.Origin);
    private static List<Id> caseRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Case').keySet());
    private static List<Id> orderRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Order').keySet());
    
     static{
    
         Id profID = [select id from profile where name='Medical Aesthetics Sales Admin'].id;

        List<User> lstTestUsers = new List<User>{new User(alias = 'test123', email='test123@hologic.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profID , country='United States',IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester1@hologic.com')};
        
        insert lstTestUsers;     
    
    System.runAs(lstTestUsers[0]){                                             
        ID prospectRecTypeId =  [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1].id;
        ID siteRecTypeId = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1].id;
        customerAccount = TestUtility.newAccount('Test Account - 00001', '', '', null, prospectRecTypeId );
        customerAccount.ShippingStateCode = 'AK';
        customerAccount.ShippingCountryCode = 'US'; 
        customerAccount.ShippingPostalCode = '10010'; 
        customerAccount.ShippingCity = 'citay'; 
        customerAccount.CurrencyIsoCode = 'USD';
        customerAccount.CDQ_Status__c = 'New';
        customerAccount.ShippingStreet = 'SHIPTest1 \n SHIPTest2 \n SHIPTest3 \n SHIPTest4';
        insert customerAccount;
        
        TestUtility.insertCustSetting('CaseTrigger');
        
        Case temp = TestUtility.newCase(
            customerAccount.Id, null, null, null, 
            caseRecordTypeIds[Math.mod(0, caseRecordTypeIds.size())], 
            caseTypes[Math.mod(0, caseTypes.size())],
            caseStatuses[Math.mod(0, caseStatuses.size())],
            casePriorities[Math.mod(1, casePriorities.size())],
            caseOrigins[Math.mod(0, caseOrigins.size())]
        );
        insert temp; 
        
        List<Product2> products = new List<Product2>();
        for(String divisionVal : divisionValues){
          Product2 p = TestUtility.newProduct(String.isNotBlank(divisionVal) ? divisionVal : 'Unknown');
          p.Division__c = divisionVal;
          
          products.add(p);
        }
        insert products;
        
        temp.ProductId = products[0].Id;
        update temp;
        
        testOrder = TestUtility.newOrder(customerAccount.Id, Test.getStandardPricebookId(), temp.Id, orderRecordTypeIds[0], 'Draft', null, Date.today());
        insert testOrder;  
    }
  }
    
    public static testMethod void testController() {
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOrder);
        OrderItemProductSearchWithWarehouse contr = new OrderItemProductSearchWithWarehouse(stdController);
        contr.backToOrder();
        contr.backToOli();
        contr.getTotalInvent();
        contr.setNext();
        contr.setPrevious();
        
    }
}