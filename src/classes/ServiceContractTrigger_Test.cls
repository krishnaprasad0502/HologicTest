@isTest
private class ServiceContractTrigger_Test {
    
    
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
    private static Configuration_Settings__c orgDefaults;
    
    static testMethod void Validateservicebilling(){
                cs = TestUtility.setupConfigurationSettings();
                Account acc= new Account(Name = 'testAcc');
                insert acc;
                
                TestUtility.insertCustSetting('ServiceContractTrigger');
                System.assertEquals('testAcc', acc.Name);
        
                Account customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
                insert customerAccount;
        
                defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
                applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
                connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
                insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
                
               for(Integer i = 0; i < 50; i++){
                   products.add(TestUtility.newProduct('Product '+i));
               }
                insert products;
        
                
                // create asset
                for(Product2 p : products){
                    Asset asset = TestUtility.newAsset(customerAccount.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
                    asset.contactid=defaultContact.id;
                    assets.add(asset);
                    productToAsset.put(p.Id, asset);
                }
                insert assets; 
                pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
                pricebooks.add(TestUtility.newPricebook('Test Pricebook2'));
                insert pricebooks;
                
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
                
                setupCoverageGroupAndTemplates();

                ServiceContract purchaseOrder = TestUtility.newServiceContract(customerAccount.Name + ' Purchase Order', customerAccount.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebooks[0].Id, System.today().addDays(-1), System.today().addMonths(12));
                //purchaseOrder.ApprovalStatus = 'Activated';
                purchaseOrder.Term=12;
                serviceContracts.add(purchaseOrder);
                GlobalUtility.runAfter = true;
                insert serviceContracts;
                
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContracts[0].Id, pricebookEntries[0].Id, 1, 1, assets[0].Id);
                cli.SBQQSC__Account__c = serviceContracts[0].AccountId;
                cli.StartDate = serviceContracts[0].StartDate;
                cli.EndDate = serviceContracts[0].EndDate;
                insert cli;
                
                Test.startTest();
                GlobalUtility.runAfter = true;
                purchaseOrder.ApprovalStatus='Activated';
                update purchaseOrder;
                
                
                Test.stopTest();
        
    }
    

    private static Coverage_Group__c coverageGroup;
    private static List<Coverage_Template__c> coverageTemplates;
    
    private static void setupCoverageGroupAndTemplates(){
        
        
        // create Business Hours
        
        BusinessHours businessHours;
        try{
            businessHours = [Select Id, Name From BusinessHours Limit 1];
        }
        catch(Exception e){}
        System.assertNotEquals(null, businessHours, 'SETUP ERROR: test cannot proceed, no Business Hours were found.');
        
        // create Coverage Group
        coverageGroup = TestUtility.newCoverageGroup('Test Coverage Group');
        insert coverageGroup;
        
        // create Coverage Template
        coverageTemplates = new List<Coverage_Template__c>();
        for(Integer i = 0; i < products.size(); i++){
            Product2 p = products[i];
            //coverageTemplates.add(TestUtility.newCoverageTemplate(p.Name + ' SLA', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_SLA'), p.Id, null, null, String.valueOf(Math.mod(i, 5) + 1), caseEntitlementProcess.Name, workOrderEntitlementProcess.Name, i+'-'+p.Id));
            coverageTemplates.add(TestUtility.newCoverageTemplate('Medical Aesthetics PM', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_PM'), p.Id, 5, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
            coverageTemplates.add(TestUtility.newCoverageTemplate('Svc Discount', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Discount'), p.Id, 10, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
            coverageTemplates.add(TestUtility.newCoverageTemplate('Medical Aesthetics Other', coverageGroup.Id, GlobalUtility.getRecordTypeId('Coverage_Template__c', 'B_SH_Other'), p.Id, 5, null, String.valueOf(Math.mod(i, 5) + 1), null, null, null));
        }
        insert coverageTemplates;

        for(Entitlement e:[Select Discount__c from Entitlement]){
            system.debug(e);
        }

    }
    
    static testMethod void updatePayment(){
    
        orgDefaults = TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('OpportunityTrigger');
        TestUtility.insertCustSetting('ServiceContractTrigger');
        //Creating Test Data
        Account acc = TestUtility.newAccount('Test Account','12345');
        insert acc;
        System.assertEquals('Test Account', acc.Name);
        
        for(Integer i = 0; i < 50; i++){
                   products.add(TestUtility.newProduct('Product '+i));
        }
                insert products;
                defaultContact = TestUtility.newContact('Default', 'Contact', acc.Id);
                
                // create asset
                for(Product2 p : products){
                    Asset asset = TestUtility.newAsset(acc.Name + ' Asset ' + p.Name, acc.Id, acc.Id, p.Id);
                    asset.contactid=defaultContact.id;
                    assets.add(asset);
                    productToAsset.put(p.Id, asset);
                }
                insert assets; 
                pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
                pricebooks.add(TestUtility.newPricebook('Test Pricebook2'));
                insert pricebooks;
                
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
        
        //insert opportunity
        List<Opportunity> lstoppts = new List<Opportunity>();
        Opportunity oppfrst = TestUtility.newOpportunity('Test Opportunity', acc.Id, System.Today(), 'Target', 'Omitted');
        lstoppts.add(oppfrst);
        Opportunity oppscnd = TestUtility.newOpportunity('Test Opportunity1', acc.Id, System.Today(), 'Target', 'Omitted');
        lstoppts.add(oppscnd);
        insert lstoppts;
        System.assertEquals(2, lstoppts.size());
        
        
        //insert quote
        SBQQ__Quote__c testQuote = TestUtility.newQuote(acc.Id, oppfrst.Id);
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        System.assertEquals(true, testQuote.SBQQ__Primary__c);  
        
        //insert payment
        Payment__c pay = new Payment__c(RecordTypeId = GlobalUtility.getRecordTypeId('Payment__c', 'ServiceContract_Payment'),  Quote__c = testQuote.Id);
        insert pay;
        
        ServiceContract purchaseOrder = TestUtility.newServiceContract(acc.Name + ' Purchase Order', acc.Id, GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Purchase_Order'), pricebooks[0].Id, System.today().addDays(-1), System.today().addMonths(12));
        purchaseOrder.SBQQSC__Quote__c = testQuote.Id;
        insert purchaseOrder;
        
          
    }

    
    
}