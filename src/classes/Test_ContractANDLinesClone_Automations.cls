@isTest(SeeAllData=true) 
Private class Test_ContractANDLinesClone_Automations{

static testMethod void Test_ContractANDLinesClone_Automations() {

Date Today = System.Today();
integer numberOfTestRecords = 3; 
        
List<Account> accountList1 = TestUtil_Hologic1.getAccounts(numberOfTestRecords, 1);
system.debug('accountList1 size = ' + accountList1.size());
insert accountList1;

List<Contact> conList1 = TestUtil_Hologic1.getContacts(accountList1, 1);
system.debug('conList1 size = ' + conList1.size());
system.debug('conList1 = ' + conList1);
insert conList1;

List<Product2> prodList1 = TestUtil_Hologic1.getProducts(numberOfTestRecords);
system.debug('prodList1 size = ' + prodList1.size());
insert prodList1;

List<User> userList1 = TestUtil_Hologic1.getUsers(numberOfTestRecords);
system.debug('userList1 size = ' + userList1.size());
system.debug('userList1 = ' + userList1);
insert userList1;


ServiceContract sc1 = new ServiceContract();

sc1.Name = 'Service Contract 1'; 
sc1.AccountId = accountList1[0].Id;
sc1.StartDate = Today; 
sc1.EndDate = Today.adddays(365);
sc1.Pricebook2Id = '01s61000003U25D';
sc1.ApprovalStatus = 'Draft';

sc1.Internal_Contact__c = userList1[0].Id; 
sc1.Description = 'Description '; 

insert sc1;

 ApexPages.StandardController stdcon = new ApexPages.standardController(sc1);
    ContractANDLinesCloneController clcc = new ContractANDLinesCloneController(stdcon);
    //System.assertEquals(e.acct, a);

    clcc.m_sc1.StartDate = Today.adddays(1);
    clcc.save();
     

 } 

    
static testMethod void testSaveHeaderAndChild() {

Date Today = System.Today();
 
integer numberOfTestRecords = 3; 
    
List<Account> accountList2 = TestUtil_Hologic1.getAccounts(numberOfTestRecords, 2);
system.debug('accountList2 size = ' + accountList2.size());
insert accountList2;

List<Contact> conList2 = TestUtil_Hologic1.getContacts(accountList2, 2);
system.debug('conList2 size = ' + conList2.size());
system.debug('conList2 = ' + conList2);
insert conList2;

List<Product2> prodList2 = TestUtil_Hologic1.getProducts(numberOfTestRecords);
system.debug('prodList2 size = ' + prodList2.size());
insert prodList2;

List<User> userList2 = TestUtil_Hologic1.getUsers(numberOfTestRecords);
system.debug('userList2 size = ' + userList2.size());
system.debug('userList2 = ' + userList2);
insert userList2;
   
Asset as2 = new Asset(Name = 'ABC123', Product2Id = prodList2[0].Id, AccountId = accountList2[0].Id);
insert as2;


Id pricebookId = Test.getStandardPricebookId();

PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prodList2[0].Id,  
            UnitPrice = 10000, IsActive = true);
        //insert standardPrice;

Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;

 PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prodList2[0].Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
        
ServiceContract sc2 = new ServiceContract();

sc2.Name = 'Service Contract 1';
sc2.AccountId = accountList2[0].Id;
sc2.StartDate = Today; 
sc2.EndDate = Today.adddays(365);
sc2.Pricebook2Id = customPB.Id; 
sc2.ApprovalStatus = 'Draft';


sc2.Internal_Contact__c = userList2[0].Id; 
sc2.Description = 'Description '; 

insert sc2;



ContractLineItem cl1 = new ContractLineItem();

cl1.ServiceContractId = sc2.Id;
cl1.AssetId = as2.Id; 
cl1.PricebookEntryId = customPrice.Id; 
cl1.UnitPrice = 1.00;
cl1.Quantity = 1; 
cl1.SBQQSC__Quantity__c = 1; 
cl1.StartDate = Today.adddays(1); 
cl1.EndDate = Today.adddays(363); 

insert cl1;
 
        ApexPages.Standardcontroller stdcon = new ApexPages.Standardcontroller(sc2);
        ContractANDLinesCloneController clcc = new ContractANDLinesCloneController(stdcon);

     clcc.m_sc1.StartDate = Today.adddays(1);
// Update Child Line
    clcc.ListOfConLineLines[0].selected = TRUE;
    clcc.ListOfConLineLines[0].obj2Line.StartDate = Today.adddays(2);
    clcc.saveHeaderAndChild();
    
 }
}