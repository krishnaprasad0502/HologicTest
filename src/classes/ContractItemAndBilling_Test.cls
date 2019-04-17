/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Test class to validate ContractItemAndBilling class
                Tests Excecuted:
                
                
<Date>          <Authors Name>      <Brief Description of Change>
07/27/2017      Kasmoor Reddy           Initial Creation (US1443)
02/18/2018      Kasmoor Reddy           Made some updates related to as part of US-3871.
------------------------------------------------------------*/
@isTest
public class ContractItemAndBilling_Test {
    //Variable Declarations
    private static List<ServiceContract> serviceContracts = new List<ServiceContract>();
    private static List<Product2> products = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    private static Map<Id, Asset> productToAsset = new Map<Id, Asset>();
    private static Service_Billing_Schedule__c billschedule;
    private static Configuration_Settings__c cs;
    private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
    private static List<Service_Billing_Schedule__c> billschedulelist=new List<Service_Billing_Schedule__c>();

  
    
    static testMethod void Validateservicebilling(){
                
                cs = TestUtility.setupConfigurationSettings();
                //Insert Account 
                Account acc= new Account(Name = 'testAcc');
                insert acc;
               
                System.assertEquals('testAcc', acc.Name);
        
                Account customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
                insert customerAccount;
                system.assertequals(customerAccount.name,'Customer Account');
                //Insert Contact
                defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
                applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
                connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
                insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
                //Insert Products
               for(Integer i = 0; i < 50; i++){
                   products.add(TestUtility.newProduct('Product '+i));
               }
                insert products;
                System.assertNotEquals(products,null,'success');
                // create asset
                for(Product2 p : products){
                    Asset asset = TestUtility.newAsset(customerAccount.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
                    asset.contactid=defaultContact.id;
                    assets.add(asset);
                    productToAsset.put(p.Id, asset);
                }
                insert assets; 
                System.assertNotEquals(assets,null,'success');
                //Insert Price Books
                pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
                pricebooks.add(TestUtility.newPricebook('Test Pricebook2'));
                insert pricebooks;
                System.assertNotEquals(pricebooks,null,'success');
                for(Pricebook2 pb : pricebooks){
                    pricebookToProductToPricebookEntry.put(pb.Id, new Map<Id, PricebookEntry>());
                }
                
                // create Price Book entry
                for(Product2 p : products){
                    PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebooks[0].Id, p.Id, 500);
                    PricebookEntry pbe2 = TestUtility.newPricebookEntry(pricebooks[1].Id, p.Id, 100);
                    
                    pricebookEntries.add(pbe1);
                    pricebookEntries.add(pbe2);
                    pricebookToProductToPricebookEntry.get(pricebooks[0].Id).put(p.Id, pbe1);
                    pricebookToProductToPricebookEntry.get(pricebooks[1].Id).put(p.Id, pbe2);
                }
                System.assertNotEquals(pricebookEntries,null,'success');
                insert pricebookEntries;
                 system.debug('pricebookEntries:::'+pricebookEntries);
                //Insert ServiceContract
                ServiceContract purchaseOrder = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebooks[0].Id, System.today().addDays(-1), System.today().addMonths(12));
                purchaseOrder.ApprovalStatus = 'Activated';
                purchaseOrder.Contract_Group__c = 'AUS';
                serviceContracts.add(purchaseOrder);
                System.assertNotEquals(serviceContracts,null,'success');
                insert serviceContracts;
                //Insert ContractLineItem
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContracts[0].Id, pricebookEntries[0].Id, 1, 1, assets[0].Id);
                cli.SBQQSC__Account__c = serviceContracts[0].AccountId;
                cli.StartDate = serviceContracts[0].StartDate;
                cli.EndDate = serviceContracts[0].EndDate;
                insert cli;
                //Insert billschedule
                billschedule = TestUtility.newservicebilling('Test INT17',cli.id,100);
                insert billschedule;
                system.assertEquals('Test INT17', billschedule.name);
                //Start Test
                Test.startTest();
                //Visual Force Page refered by ServiceContractItemAndBilling Class
                PageReference pageRef = Page.ContractItemAndBilling;
                Test.setCurrentPage(pageRef);
                //Setting the Standard Controller
                ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(cli);
                //Passing an Id as the current Page reference 
                ApexPages.currentPage().getParameters().put('Id',cli.id);
                ApexPages.currentPage().getParameters().put('cntrctlnitem.Id',cli.id );
                //Creating Object to ContractItemAndBilling class
                ContractItemAndBilling itembilling = new ContractItemAndBilling(sc);
                //Creating an Object to the Inner Class (Wrapper Class)
                ContractItemAndBilling.ServiceBillingWrapper oo = new ContractItemAndBilling.ServiceBillingWrapper(billschedule,1);
                //Calling methods using ServiceContractItemAndBilling object
                oo.key = 1;
                itembilling.saveBillingschedules();
                itembilling.RemoveItemKey = 1;
                itembilling.Removebilling();
                itembilling.backTocontractlineitem();
                itembilling.addLine();
                //Stop Test
                Test.stopTest();
        
    }
    
    

    static testMethod void Validateservicecontractbilling(){
                cs = TestUtility.setupConfigurationSettings();
                Account acc= new Account(Name = 'testAcc');
                insert acc;
                
                System.assertEquals('testAcc', acc.Name);
        
                Account customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
                insert customerAccount;
                System.assertEquals('Customer Account', customerAccount.Name);
                defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
                applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
                connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
                insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
                
               for(Integer i = 0; i < 50; i++){
                   products.add(TestUtility.newProduct('Product '+i));
               }
                insert products;
                System.assertNotEquals(products,null,'success');
                // create asset
                for(Product2 p : products){
                    Asset asset = TestUtility.newAsset(customerAccount.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
                    asset.contactid=defaultContact.id;
                    assets.add(asset);
                    productToAsset.put(p.Id, asset);
                }
                insert assets; 
                System.assertNotEquals(assets,null,'success');
                pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
                pricebooks.add(TestUtility.newPricebook('Test Pricebook2'));
                insert pricebooks;
                System.assertNotEquals(pricebooks,null,'success');
                for(Pricebook2 pb : pricebooks){
                    pricebookToProductToPricebookEntry.put(pb.Id, new Map<Id, PricebookEntry>());
                }
                
                // create Price Book entry
                for(Product2 p : products){
                    PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebooks[0].Id, p.Id, 500);
                    PricebookEntry pbe2 = TestUtility.newPricebookEntry(pricebooks[1].Id, p.Id, 100);
                    
                    pricebookEntries.add(pbe1);
                    pricebookEntries.add(pbe2);
                    pricebookToProductToPricebookEntry.get(pricebooks[0].Id).put(p.Id, pbe1);
                    pricebookToProductToPricebookEntry.get(pricebooks[1].Id).put(p.Id, pbe2);
                }
                
                insert pricebookEntries;
                system.debug('pricebookEntries:::'+pricebookEntries);
                System.assertNotEquals(pricebookEntries,null,'success');
                ServiceContract purchaseOrder = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebooks[0].Id, System.today().addDays(-1), System.today().addMonths(12));
                purchaseOrder.ApprovalStatus = 'Activated';
                purchaseOrder.Contract_Group__c = 'AUS';
                serviceContracts.add(purchaseOrder);
                insert serviceContracts;
                System.assertNotEquals(serviceContracts,null,'success');
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContracts[0].Id, pricebookEntries[0].Id, 1, 1, assets[0].Id);
                cli.SBQQSC__Account__c = serviceContracts[0].AccountId;
                cli.StartDate = serviceContracts[0].StartDate;
                cli.EndDate = serviceContracts[0].EndDate;
                insert cli;
                billschedule = TestUtility.newservicebilling('Test INT17',cli.id,100);
                billschedulelist.add(billschedule);
                insert billschedule;
                System.assertNotEquals(billschedulelist,null,'success');
                //Start Test
                Test.startTest();
                //Visual Force Page refered by ContractItemAndBilling Class
                PageReference pageReff = Page.ContractItemAndBilling;
                Test.setCurrentPage(pageReff);
                //Setting the Standard Controller
                ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(purchaseOrder);
                //Passing an Id as the current Page reference 
                ApexPages.currentPage().getParameters().put('Id',purchaseOrder.id);
                ApexPages.currentPage().getParameters().put('cntrctlnitem.Id',purchaseOrder.id);
                //Creating Object to ContractItemAndBilling class
                Contractitemandbilling itembilling = new Contractitemandbilling(sc);
                //Creating an Object to the Inner Class (Wrapper Class)
                Contractitemandbilling.ServicecontractBillingWrapper oo = new Contractitemandbilling.ServicecontractBillingWrapper(cli,purchaseOrder,1,100.0,billschedule,1);
                oo.key = 1;
                //Fetching the select option values
                List<SelectOption> options=itembilling.getOptions();
                //Calling methods usingContractItemAndBilling object
                //itembilling.saveBillingschedules();
                itembilling.RemoveItemKey = 1;
                itembilling.saveServiceContract();
                itembilling.backToServiceContract();
                //Setting a value to a List Variable 
                itembilling.ServiceBillingList=billschedulelist;
                itembilling.saveSCBillingschedules();
                //Calling a Wrapper Class
                Contractitemandbilling.ServicecontractBillingWrapper wrapper = new Contractitemandbilling.ServicecontractBillingWrapper(cli,purchaseOrder,1,100.0,billschedule,0);
                //Stop Test
                Test.stopTest();
        
    }
    
}