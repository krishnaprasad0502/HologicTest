/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        Apps Associates
Description:    Test class to validate caseRecordType_controller  
                Test Executed:
                validateassetid() : Set asset id and verify that asset id is not null and it covers redirecting to asset detail page and 
                validateaccountid() : Verify that the account id is not null and it covers redirecting to accoount detail page.

History:
<Date>          <Authors Name>          <Brief Description of Change>
04/26/2017      Amarendra Nagireddy      Initial Creation(US-0002746) to accommodate the test coverage related to US-0002765
05/08/2017      Amarendra Nagireddy      Updated the logic for test coverage as part of US-0002765
------------------------------------------------------------*/
@isTest(seealldata=false)
public class CaseRecordTypeController_Test {
 private static Account customerAccount;
    private static Product_Source_Division__c psd;
    private static Product2 prod;
    private static Account siteAccount;
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Map<Id, Id> assetToProduct = new Map<Id, Id>();
    private static List<Case> cases = new List<Case>();
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    
    private static User integrationUser;
    private static User sysAdminUser;
    
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id,PricebookEntry>>();
    
    static {
        TestUtility.setupConfigurationSettings();
        
        // 05-08-2017-(Amarendra Nagireddy)-Added trigger switch to run case and product related triggers while inserting the test records (US-0002505)
        TestUtility.insertCustSetting('OrderLineProductReplacement'); 
        TestUtility.insertCustSetting('CaseTrigger');         
        
        integrationUser = TestUtility.newUser([Select Id From Profile Where Name = 'Integration API User' Limit 1].Id,'tstother');
        sysAdminUser = TestUtility.newUser([Select Id From Profile Where Name = 'System Administrator' Limit 1].Id,'tstadmin');
        insert new List<User>{integrationUser, sysAdminUser};
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        siteAccount = TestUtility.newAccount('Site Account', 'testSite', 'ABC Street', customerAccount.Id,GlobalUtility.getRecordTypeId('Account', 'Site'));
        insert siteAccount;
        
        //create Contact
        defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        //07/14/2017-(Kasmoor Reddy)- created a new product source division record from new method in TestUtility class as part of US-00003025.
        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;
        system.debug('psd===='+psd);
        Product_Source_Division__c psd1 = TestUtility.newProductSourceDivision('12345','MOLECULAR');
        Insert psd1;
        
        Product2 prod = TestUtility.newProduct('Prodrec');
        insert prod;
        for(Integer i = 0; i < 1; i++){
            products.add(TestUtility.newProduct('Product '+i));
            products[i].Product_Source_Division__c = psd.id;
            products[i].Replacement_Part__c = prod.id;
        }
        insert products;
        system.debug('products:::'+products);
        
        for(Product2 p : products){
            Asset a1=TestUtility.newAsset(siteAccount.Name + ' Asset ' + p.Name, siteAccount.Id, customerAccount.Id,p.Id);
            a1.ContactId= defaultContact.Id;
            assets.add(a1);
            
        }
        insert assets;
    }
    //5/22/2017(Amarendra Nagireddy)-Added test start,stop method
static testMethod void validateassetid(){
      Test.startTest();
      Test.setCurrentPageReference(new PageReference('Page.caserecordtypeselect')); 
      System.currentPageReference().getParameters().put('aId', assets[0].id);
      System.currentPageReference().getParameters().put('objname', 'Asset');
      CaseRecordTypeController caseRecordType=new CaseRecordTypeController();
      string assid=ApexPages.currentPage().getParameters().get('aId');
      caseRecordType.continueredirect();
      caseRecordType.cancel();
      system.assertEquals(assets[0].id, assid);
      Test.StopTest();
    }
    


}