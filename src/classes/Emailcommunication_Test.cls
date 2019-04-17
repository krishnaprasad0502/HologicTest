/*------------------------------------------------------------
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    Test class to validate EmailCommunicationTrigger
               
                
History:
<Date>          <Authors Name>      <Brief Description of Change>
20/1/2018       KRISHNA PRASAD       Initial Creation(US-0003622)
------------------------------*/
@isTest(seealldata=false)
public class Emailcommunication_Test {

    private static Account custAccount;
    public  static  Integer Pagination=0;
    public static   List<Account> accountInserts = new List<Account>();
    private static List<Case> cases = new List<Case>();
    private static Configuration_Settings__c orgDefaults;
    private static Record_Type_IDs__c rtIds;
    private static Account siteAccount;
    private static Contact defaultContact;
    private static ContractLineItem cli;
    private static List<Product2> products;
    private static List<Asset> assets;
    private static Pricebook2 pricebook;
    private static List<PriceBookEntry> pbeList;
    private static List<ServiceContract> serviceContracts = new List<ServiceContract>();
    private static Session_Time__c sessiontime;

    public static Integer randomInteger(){
    return integer.ValueOf(Math.rint(Math.random() * 100000));
    }

    static{
    orgDefaults = TestUtility.setupConfigurationSettings();

    rtIds = TestUtility.setupRecordTypeIds();
    rtIds.Work_Order_B_SH_Billable_PM__c = GlobalUtility.getRecordTypeId('WorkOrder', 'B_SH_Billable_PM');
    update rtIds;
    system.debug('rtIds.Work_Order_B_SH_Billable_PM__c----'+rtIds.Work_Order_B_SH_Billable_PM__c);

    TestUtility.insertCustSetting('WorkOrderTrigger');   

    TestUtility.insertCustSetting('WorkOrderPM');

    TestUtility.insertCustSetting('DeleteZeroQtyStock');
 
    // 06-19-17 Update of additional Custom Settings 

    TestUtility.insertCustSetting('PMPlans');  
    TestUtility.insertCustSetting('CDAccess');          
    TestUtility.insertCustSetting('CaseTrigger');   
    TestUtility.insertCustSetting('OrderLineProductReplacement');         

    // insert pricebooks
    // insert an account
    custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
    custAccount.BillingCountryCode = 'US';
    custAccount.BillingStateCode = 'NY';        
    insert custAccount;

    }


    static TestMethod void testEmailCommunication()
    {

    Trigger_Switch__c ts = new Trigger_Switch__c();
    ts.Name = 'EmailCommunicationTrigger';
    ts.Active__c = true;
    insert ts;
    for(Integer i=0;i<=10;i++)
    {
    cases.add(TestUtility.newCase(custAccount.id, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
    //cases.add(TestUtility.newCase(a.AccountId, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Service'), 'Applications', 'New', 'Low', 'Phone'));
    }

    insert cases;
    List<string> emaillistid=new List<string>();
    Email_Communication__c emaillist= TestUtility.newEmailcommunication(cases[0].id,'kasmoor@example.com','kasmoor',system.today(),'Approved','b&shsupporttest@hologic.com','rotation switch problemss');

    insert emaillist;
    Attachment attachment = TestUtility.newattachement(emaillist.id,'Test Attachment for Parent');
    attachment.Body = Blob.valueOf('Unit Test Attachment Body');
    insert(attachment);
    List<task> t = new List<task>{TestUtility.newTask('Donni',cases[0].id)};
    t[0].Status='Completed';
    t[0].Priority='Normal';
    t[0].Email_Communication_Id__c  = emaillist.id;
    insert t;
    
    EmailMessage emess = TestUtility.newemailmessage(cases[0].id, 'dsacks@control4.com.dev', 'testingit@gmail.com',
    'Testing Apex trigger', 'this his the message of the email',emaillist.id);
    
    Insert emess;
    System.debug('attachments:::::::'+attachment);
    List<Email_Communication__c> emaillistupadte=new List<Email_Communication__c>();
    emaillist.case__c=cases[1].id;
    emaillist.AttacmentIds__c=string.valueof(attachment.id);
    update(emaillist);
    emaillistid.add(string.valueof(emaillist.id));
    
    Emailcommunication.searchkeyword(null,'','','',Pagination,'');
    Emailcommunication.searchkeyword(string.valueof(system.now()),string.valueof(system.now()),'Assigned','test',Pagination,'test');
    Emailcommunication.deleteRecords(emaillistid);
    Emailcommunication.extractPicklistValues();
    }
   
}