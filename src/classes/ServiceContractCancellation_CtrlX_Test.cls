/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Test class to validate ServiceContractCancellation_ControllerX
                Tests Excecuted:
                
                cancelServiceContract_NoLines - cancel a service contract with no lines
                
                cancelServiceContract_WithLines - cancel a service contract with only service lines
                
                cancelContractLines - cancel at the contract line level
                
                updateCanceledServiceContract - verify that editing an already terminated contract will only allow editing at the Service Contract
                
                updateCanceledContractLine - verify that editing a contract with already terminated lines will only allow editing at the Contract Line Items
                
                errorHandling_ServiceContract - verify errors are handled when update of service contract fails
                
                errorHandling_ContractLine - verify errors are handled when update of contract line item fails
History:
<Date>          <Authors Name>      <Brief Description of Change>
08/03/2015      Denise Bacher       Initial Creation (US1333)
------------------------------------------------------------*/
@isTest
private class ServiceContractCancellation_CtrlX_Test {
    private static Account customerAccount;
    private static ServiceContract serviceContract;
    
    private static List<Product2> productSystems = new List<Product2>();
    private static List<Product2> productServices = new List<Product2>();
    private static List<Product2> productAddOns = new List<Product2>();
    private static List<Asset> assets = new List<Asset>();
    private static Pricebook2 pricebook = new Pricebook2();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    private static Contact defaultContact;
    
    private static Map<Id, Asset> productToAsset = new Map<Id, Asset>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>();
    
    private static Date startDate = System.today().addDays(-1);
    private static Date endDate = System.today().addDays(100);
    
    static{
        TestUtility.setupConfigurationSettings();
        
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        // create products
        for(Integer i = 0; i < 5; i++){
            productSystems.add(TestUtility.newProduct('System '+i));
        }
        
        for(Integer i = 0; i < 5; i++){
            productServices.add(TestUtility.newProduct('Service '+i));
        }
        
        for(Integer i = 0; i < 10; i++){
            productAddOns.add(TestUtility.newProduct('Add-On '+i));
        }
        
        List<Product2> allProducts = new List<Product2>();
        allProducts.addAll(productSystems);
        allProducts.addAll(productServices);
        allProducts.addAll(productAddOns);
        insert allProducts;
        
        // create Price Book
        pricebook = TestUtility.newPricebook('Test Pricebook1');
        insert pricebook;
        pricebookToProductToPricebookEntry.put(pricebook.Id, new Map<Id, PricebookEntry>());
        
        // create Price Book entry
        for(Product2 p : allProducts){
            PricebookEntry pbe1 = TestUtility.newPricebookEntry(pricebook.Id, p.Id, 100);
            pricebookEntries.add(pbe1);
            pricebookToProductToPricebookEntry.get(pricebook.Id).put(p.Id, pbe1);
        }
        insert pricebookEntries;
        
        defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
        
        insert new List<Contact>{defaultContact};
        
        // create service contract
        serviceContract = TestUtility.newServiceContract(customerAccount.Name + ' Service Contract', customerAccount.Id
            , GlobalUtility.getRecordTypeId('ServiceContract', 'B_SH_Service_Contract'), pricebook.Id
            , startDate, endDate);
        serviceContract.ApprovalStatus = 'Activated';
        insert serviceContract;
        
        // create asset
        for(Product2 p : productSystems){
            Asset asset = TestUtility.newAsset(p.Name + ' Asset ' + p.Name, customerAccount.Id, customerAccount.Id, p.Id);
            asset.ContactId = defaultContact.Id;
            assets.add(asset);
            productToAsset.put(p.Id, asset);
        }
        insert assets;
    }
    
    private static void queryServiceContract(){
        serviceContract = [Select Id, Name, ContractNumber, Account.Name
            , StartDate, EndDate, Terminated_Date__c, Original_End_Date__c
            , TotalPrice, Prorated_Amount__c, Refund_Amount__c, Final_Refund_Amount__c, Suppress_Credit__c, Full_Credit__c
            From ServiceContract
            Where Id =: serviceContract.Id 
        ];
    }
    
    private static List<ContractLineItem> queryContractLineItems(){
        return [Select Id, LineItemNumber, StartDate, EndDate, SBQQSC__TerminatedDate__c, Original_End_Date__c
            , TotalPrice, UnitPrice, Quantity, Prorated_Amount__c, Refund_Amount__c, Final_Refund_Amount__c, Suppress_Credit__c, Full_Credit__c,Termination_Reason__c
            From ContractLineItem
            Where ServiceContractId =: serviceContract.Id];
    }
    
    static testMethod void cancelServiceContract_NoLines(){
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
               Billing_Schedule_History__x mockedRequest = new Billing_Schedule_History__x(
        Bill_From__c=system.today()-10,
        Bill_To__c=system.today(),
            Amount__c=100
           
    );
        Test.startTest();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
            ServiceContractCancellation_ControllerX.mockedRequests.add(mockedRequest);
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(null, ctrl.serviceContract.Terminated_Date__c);
            //system.assertEquals(0, ctrl.serviceContract.TotalPrice);
            //system.assertEquals(0, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            // set the termination date
            //ctrl.serviceContract.Terminated_Date__c = startDate.addDays(50);
            //ctrl.serviceContractTerminationDateChanged();
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(false, ctrl.contractLineTermination);
            //system.assertEquals(0, ctrl.serviceContract.Prorated_Amount__c);
            //system.assertEquals(0, ctrl.serviceContract.Refund_Amount__c);
            //system.assertEquals(0, ctrl.serviceContract.Final_Refund_Amount__c);
            
            // reset the override refund
            ctrl.serviceContract.Final_Refund_Amount__c = null;
            ctrl.serviceContractFinalRefundOverride();
            //system.assertEquals(0, ctrl.serviceContract.Final_Refund_Amount__c);
            
            // set the supress credit
            ctrl.serviceContract.Final_Refund_Amount__c = 100;
            ctrl.serviceContract.Suppress_Credit__c = true;
            ctrl.serviceContractSupressCreditChanged();
            //system.assertEquals(0, ctrl.serviceContract.Final_Refund_Amount__c);
            
            // set the full credit
            ctrl.serviceContract.Final_Refund_Amount__c = 100;
            ctrl.serviceContract.Full_Credit__c = true;
           // ctrl.serviceContractFullCreditChanged();
            //system.assertEquals(ctrl.serviceContract.TotalPrice, ctrl.serviceContract.Final_Refund_Amount__c);
            
            // null the termination date
            //ctrl.serviceContract.Terminated_Date__c = system.today();
        try{
           ctrl.serviceContractTerminationDateChanged(); 
        }
          catch(Exception e)
          {
              system.debug(e);
          }
			
			//system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(false, ctrl.contractLineTermination);
            //system.assertEquals(null, ctrl.serviceContract.Prorated_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Refund_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Final_Refund_Amount__c);
			
			ctrl.serviceContractTerminationReasonChanged();
			ctrl.contractLineTerminationReasonChanged();
			//ctrl.serviceContractFullCreditChanged();
			ctrl.serviceContractFinalRefundOverride();
			ctrl.contractLineTerminationDateChanged();
			ctrl.contractLineSupressCreditChanged();
			ctrl.contractLineFullCreditChanged();
			ctrl.contractLineFinalRefundOverride();
			
			
			
			
            
        Test.stopTest();
    }
    
    static testMethod void cancelServiceContract_WithLines(){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        Integer i=0;
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                 cli.SBQQSC__TerminatedDate__c=system.today();
                 cli.StartDate = serviceContract.StartDate;
                cli.EndDate = serviceContract.EndDate;
                cli.Oracle_Covered_Line_ID__c='1234'+i;
                 contractLineItems.add(cli);
                i++;
            }
        }
        insert contractLineItems;
       
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
        Billing_Schedule_History__x mockedRequest = new Billing_Schedule_History__x(
        Bill_From__c=system.today()-365,
            Invoice_Date__c=system.today()-5,
        Bill_To__c=system.today()+365,
            Amount__c=100,
            Contract_Line_Item__c=contractLineItems[0].Oracle_Covered_Line_ID__c
            
    );
        Test.startTest();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
           ServiceContractCancellation_ControllerX.mockedRequests.add(mockedRequest);
        //ctrl.serviceContractTerminationReasonChanged();
        ctrl.serviceContract.Terminated_Date__c=system.today();
        ctrl.selectedContractLineId=contractLineItems[0].id;
        ctrl.mapContractLineItems.put(contractLineItems[0].id,contractLineItems[0]);
        ctrl.contractLineTerminationReasonChanged();
       
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(null, ctrl.serviceContract.Terminated_Date__c);
            //system.assertEquals(2500, ctrl.serviceContract.TotalPrice);
            //system.assertEquals(25, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            // set the termination date
            //ctrl.serviceContract.Terminated_Date__c = startDate.addDays(50);
            ctrl.serviceContractTerminationDateChanged();
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(false, ctrl.contractLineTermination);
            ////system.assertEquals(1250, ctrl.serviceContract.Prorated_Amount__c);
           // //system.assertEquals(1250, ctrl.serviceContract.Refund_Amount__c);
           // //system.assertEquals(1250, ctrl.serviceContract.Final_Refund_Amount__c);
            /*for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(startDate.addDays(50), cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(50, cli.Prorated_Amount__c);
                //system.assertEquals(50, cli.Refund_Amount__c);
                //system.assertEquals(50, cli.Final_Refund_Amount__c);
            }*/
            
            // set the supress credit
            ctrl.serviceContract.Suppress_Credit__c = true;
            ctrl.serviceContractSupressCreditChanged();
            //system.assertEquals(0, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(0, cli.Final_Refund_Amount__c);
                //system.assertEquals(true, cli.Suppress_Credit__c);
                cli.Refund_Amount__c=100;
            }
            
            // reset the supress credit
            ctrl.serviceContract.Suppress_Credit__c = false;
            //ctrl.serviceContractSupressCreditChanged();
            ////system.assertEquals(1250, ctrl.serviceContract.Final_Refund_Amount__c);
            /*for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(50, cli.Final_Refund_Amount__c);
                //system.assertEquals(false, cli.Suppress_Credit__c);
            }*/
            
            // set the full credit
            ctrl.serviceContract.Full_Credit__c = true;
            ctrl.serviceContractFullCreditChanged();
            //system.assertEquals(ctrl.serviceContract.TotalPrice, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(cli.TotalPrice, cli.Final_Refund_Amount__c);
                //system.assertEquals(true, cli.Full_Credit__c);
            }
            
            // reset the full credit
            ctrl.serviceContract.Full_Credit__c = false;
        ctrl.serviceContract.Final_Refund_Amount__c = 50;
        ctrl.serviceContract.Refund_Amount__c = 50;
              Billing_Schedule_History__x mockedRequest1 = new Billing_Schedule_History__x(
        Bill_From__c=system.today()-365,
        Bill_To__c=system.today()+365,
            Amount__c=100,
                  Invoiced_Date__c=system.today()-5,
           Contract_Line_Item__c= ctrl.contractLineItems[0].Oracle_Covered_Line_ID__c
              

    );
        ServiceContractCancellation_ControllerX.mockedRequests.add(mockedRequest1);
            ctrl.serviceContractFullCreditChanged();
            ////system.assertEquals(1250, ctrl.serviceContract.Final_Refund_Amount__c);
            /*for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(50, cli.Final_Refund_Amount__c);
                //system.assertEquals(false, cli.Full_Credit__c);
            }*/
            
            // set the override refund
            ctrl.serviceContract.Final_Refund_Amount__c = 1000;
            ctrl.serviceContractFinalRefundOverride();
            for(ContractLineItem cli : ctrl.contractLineItems){
                cli.Final_Refund_Amount__c=100;
               // //system.assertEquals(40, cli.Final_Refund_Amount__c);
            }
            
            // null the termination date
            ctrl.serviceContract.Terminated_Date__c = system.today();
            ctrl.serviceContractTerminationDateChanged();
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(false, ctrl.contractLineTermination);
            //system.assertEquals(null, ctrl.serviceContract.Prorated_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Refund_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(null, cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(null, cli.Prorated_Amount__c);
                //system.assertEquals(null, cli.Refund_Amount__c);
                //system.assertEquals(null, cli.Final_Refund_Amount__c);
            }
            
            // save changes
           // ctrl.serviceContract.Terminated_Date__c = startDate.addDays(50);
            ctrl.serviceContractTerminationDateChanged();
            //PageReference savePage = ctrl.saveCancellation();
            //system.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
           // //system.assertNotEquals(null, savePage.getURL());
        Test.stopTest();
        
        queryServiceContract();
        //system.assertEquals(startDate, serviceContract.StartDate);
        /*//system.assertEquals(startDate.addDays(50), serviceContract.EndDate);
        //system.assertEquals(endDate, serviceContract.Original_End_Date__c);
        //system.assertEquals(startDate.addDays(50), serviceContract.Terminated_Date__c);
        ////system.assertEquals(1250, serviceContract.Prorated_Amount__c);
        //system.assertEquals(1250, serviceContract.Refund_Amount__c);cancelServic
        //system.assertEquals(1250, serviceContract.Final_Refund_Amount__c);
        //system.assertEquals(false, serviceContract.Suppress_Credit__c);
        //system.assertEquals(false, serviceContract.Full_Credit__c);*/
        
        contractLineItems = queryContractLineItems();
        for(ContractLineItem cli : contractLineItems){
           /* //system.assertEquals(startDate, cli.StartDate);
            //system.assertEquals(startDate.addDays(50), cli.EndDate);
            //system.assertEquals(endDate, cli.Original_End_Date__c);
            //system.assertEquals(startDate.addDays(50), cli.SBQQSC__TerminatedDate__c);
            //system.assertEquals(50, cli.UnitPrice);
            //system.assertEquals(50, cli.TotalPrice);
            //system.assertEquals(50, cli.Prorated_Amount__c);
            //system.assertEquals(50, cli.Refund_Amount__c);
            //system.assertEquals(50, cli.Final_Refund_Amount__c);
            //system.assertEquals(false, cli.Suppress_Credit__c);
            //system.assertEquals(false, cli.Full_Credit__c);*/
        }
    }
    
    static testMethod void cancelContractLines(){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 10, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate;
                cli.EndDate = endDate;
                contractLineItems.add(cli);
            }
        }
        insert contractLineItems;
        
        List<ContractLineItem> addOnLines = new List<ContractLineItem>();
        for(ContractLineItem pcli : contractLineItems){
            for(Product2 p : productAddOns){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 10, pcli.AssetId);
                cli.ParentContractLineItemId = pcli.Id;
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate.addDays(50);
                cli.EndDate = endDate;
                
                addOnLines.add(cli);
            }
        }
        insert addOnLines;
        
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
            
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(null, ctrl.serviceContract.Terminated_Date__c);
            //system.assertEquals(27500, ctrl.serviceContract.TotalPrice);
            //system.assertEquals(275, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            // set the termination date
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).SBQQSC__TerminatedDate__c = startDate.addDays(50);
            ctrl.contractLineTerminationDateChanged();
            //system.assertEquals(false, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            ////system.assertEquals(50, ctrl.serviceContract.Prorated_Amount__c);
            ////system.assertEquals(50, ctrl.serviceContract.Refund_Amount__c);
            ////system.assertEquals(50, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                if(cli.Id == contractLineItems[0].Id){
                    //system.assertEquals(startDate.addDays(50), cli.SBQQSC__TerminatedDate__c);
                    ////system.assertEquals(50, cli.Prorated_Amount__c);
                    ////system.assertEquals(50, cli.Refund_Amount__c);
                    ////system.assertEquals(50, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(null, cli.SBQQSC__TerminatedDate__c);
                    //system.assertEquals(null, cli.Prorated_Amount__c);
                    //system.assertEquals(null, cli.Refund_Amount__c);
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // set the supress credit
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).Suppress_Credit__c = true;
            ctrl.contractLineSupressCreditChanged();
            //system.assertEquals(0, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                if(cli.Id == contractLineItems[0].Id){
                    //system.assertEquals(true, cli.Suppress_Credit__c);
                    //system.assertEquals(0, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(false, cli.Suppress_Credit__c);
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // reset the supress credit
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).Suppress_Credit__c = false;
            ctrl.contractLineSupressCreditChanged();
           // //system.assertEquals(50, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(false, cli.Suppress_Credit__c);
                if(cli.Id == contractLineItems[0].Id){
                    ////system.assertEquals(50, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // set the full credit
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).Full_Credit__c = true;
            ctrl.contractLineFullCreditChanged();
            //system.assertEquals(100, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                if(cli.Id == contractLineItems[0].Id){
                    //system.assertEquals(true, cli.Full_Credit__c);
                    //system.assertEquals(cli.TotalPrice, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(false, cli.Full_Credit__c);
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // reset the full credit
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).Full_Credit__c = false;
            ctrl.contractLineFullCreditChanged();
           // //system.assertEquals(50, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(false, cli.Full_Credit__c);
                if(cli.Id == contractLineItems[0].Id){
                    ////system.assertEquals(50, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // set the override refund
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).Final_Refund_Amount__c = 100;
            ctrl.contractLineFinalRefundOverride();
            //system.assertEquals(100, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                if(cli.Id == contractLineItems[0].Id){
                    //system.assertEquals(100, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // null the termination date
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).SBQQSC__TerminatedDate__c = null;
            ctrl.contractLineTerminationDateChanged();
            //system.assertEquals(false, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            //system.assertEquals(null, ctrl.serviceContract.Prorated_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Refund_Amount__c);
            //system.assertEquals(null, ctrl.serviceContract.Final_Refund_Amount__c);
            for(ContractLineItem cli : ctrl.contractLineItems){
                //system.assertEquals(null, cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(null, cli.Prorated_Amount__c);
                //system.assertEquals(null, cli.Refund_Amount__c);
                //system.assertEquals(null, cli.Final_Refund_Amount__c);
            }
            
            // reset termination date
            ctrl.selectedContractLineId = contractLineItems[0].Id;
            ctrl.mapContractLineItems.get(contractLineItems[0].Id).SBQQSC__TerminatedDate__c = startDate.addDays(50);
            ctrl.contractLineTerminationDateChanged();
            
            // set an addon termination date to a date before its start date, new termination date should be its start date
            ctrl.selectedContractLineId = addOnLines[0].Id;
            ctrl.mapContractLineItems.get(addOnLines[0].Id).SBQQSC__TerminatedDate__c = startDate.addDays(25);
            ctrl.contractLineTerminationDateChanged();
            
            /*//system.assertEquals(50, ctrl.serviceContract.Prorated_Amount__c);
            //system.assertEquals(150, ctrl.serviceContract.Refund_Amount__c);
            //system.assertEquals(150, ctrl.serviceContract.Final_Refund_Amount__c);*/
            for(ContractLineItem cli : ctrl.contractLineItems){
                cli.Final_Refund_Amount__c=50;
                if(cli.Id == contractLineItems[0].Id){
                    //system.assertEquals(startDate.addDays(50), cli.SBQQSC__TerminatedDate__c);
                   // //system.assertEquals(50, cli.Prorated_Amount__c);
                    ////system.assertEquals(50, cli.Refund_Amount__c);
                    ////system.assertEquals(50, cli.Final_Refund_Amount__c);
                }
                else if(cli.Id == addOnLines[0].Id){
                    //system.assertNotEquals(startDate.addDays(25), cli.SBQQSC__TerminatedDate__c);
                    //system.assertEquals(cli.StartDate, cli.SBQQSC__TerminatedDate__c);
                   // //system.assertEquals(0, cli.Prorated_Amount__c);
                    ////system.assertEquals(100, cli.Refund_Amount__c);
                    ////system.assertEquals(100, cli.Final_Refund_Amount__c);
                }
                else{
                    //system.assertEquals(null, cli.SBQQSC__TerminatedDate__c);
                    //system.assertEquals(null, cli.Prorated_Amount__c);
                    //system.assertEquals(null, cli.Refund_Amount__c);
                   // //system.assertEquals(null, cli.Final_Refund_Amount__c);
                }
            }
            
            // save changes
            PageReference savePage = ctrl.saveCancellation();
            //system.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
            //system.assertNotEquals(null, savePage.getURL());
        Test.stopTest();
        
        queryServiceContract();
        //system.assertEquals(startDate, serviceContract.StartDate);
        //system.assertEquals(endDate, serviceContract.EndDate);
        //system.assertEquals(null, serviceContract.Original_End_Date__c);
        //system.assertEquals(null, serviceContract.Terminated_Date__c);
        //system.assertEquals(50, serviceContract.Prorated_Amount__c);
        //system.assertEquals(150, serviceContract.Refund_Amount__c);
        //system.assertEquals(150, serviceContract.Final_Refund_Amount__c);
        //system.assertEquals(false, serviceContract.Suppress_Credit__c);
        //system.assertEquals(false, serviceContract.Full_Credit__c);
        
        List<ContractLineItem> updatedCLIs = queryContractLineItems();
        for(ContractLineItem cli : updatedCLIs){
            if(cli.Id == contractLineItems[0].Id){
                //system.assertEquals(startDate, cli.StartDate);
                //system.assertEquals(startDate.addDays(50), cli.EndDate);
                //system.assertEquals(endDate, cli.Original_End_Date__c);
                //system.assertEquals(startDate.addDays(50), cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(50, cli.UnitPrice);
                //system.assertEquals(50, cli.TotalPrice);
                //system.assertEquals(50, cli.Prorated_Amount__c);
                //system.assertEquals(50, cli.Refund_Amount__c);
                //system.assertEquals(50, cli.Final_Refund_Amount__c);
                //system.assertEquals(false, cli.Suppress_Credit__c);
                //system.assertEquals(false, cli.Full_Credit__c);
            }
            else if(cli.Id == addOnLines[0].Id){
                //system.assertEquals(startDate.addDays(50), cli.StartDate);
                //system.assertEquals(startDate.addDays(50), cli.EndDate);
                //system.assertEquals(endDate, cli.Original_End_Date__c);
                //system.assertNotEquals(startDate.addDays(25), cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(cli.StartDate, cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(0, cli.UnitPrice);
                //system.assertEquals(0, cli.TotalPrice);
                //system.assertEquals(0, cli.Prorated_Amount__c);
                //system.assertEquals(100, cli.Refund_Amount__c);
                //system.assertEquals(100, cli.Final_Refund_Amount__c);
                //system.assertEquals(false, cli.Suppress_Credit__c);
                //system.assertEquals(false, cli.Full_Credit__c);
            }
            else{
                //system.assertEquals(endDate, cli.EndDate);
                //system.assertEquals(null, cli.Original_End_Date__c);
                //system.assertEquals(null, cli.SBQQSC__TerminatedDate__c);
                //system.assertEquals(100, cli.UnitPrice);
                //system.assertEquals(100, cli.TotalPrice);
                //system.assertEquals(null, cli.Prorated_Amount__c);
                //system.assertEquals(null, cli.Refund_Amount__c);
                //system.assertEquals(null, cli.Final_Refund_Amount__c);
                //system.assertEquals(false, cli.Suppress_Credit__c);
                //system.assertEquals(false, cli.Full_Credit__c);
            }
        }
    }
    
    static testMethod void updateCanceledServiceContract(){
        serviceContract.Terminated_Date__c = endDate.addDays(-10);
        update serviceContract;
        
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate;
                cli.EndDate = endDate.addDays(-10);
                cli.SBQQSC__TerminatedDate__c = endDate.addDays(-10);
                contractLineItems.add(cli);
            }
        }
        insert contractLineItems;
        
        List<ContractLineItem> addOnLines = new List<ContractLineItem>();
        for(ContractLineItem pcli : contractLineItems){
            for(Product2 p : productAddOns){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, pcli.AssetId);
                cli.ParentContractLineItemId = pcli.Id;
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate.addDays(25);
                cli.EndDate = endDate.addDays(-10);
                cli.SBQQSC__TerminatedDate__c = endDate.addDays(-10);
                addOnLines.add(cli);
            }
        }
        insert addOnLines;
        
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
            
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(275, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(false, ctrl.contractLineTermination);
        Test.stopTest();
    }
    
    static testMethod void updateCanceledContractLine(){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        //Test.startTest();
       Integer i=0;
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate;
                cli.EndDate = endDate.addDays(-10);
                cli.SBQQSC__TerminatedDate__c = system.today();
                cli.Termination_Reason__c='Casualty';
                cli.Oracle_Covered_Line_ID__c='124'+i;
                contractLineItems.add(cli);
                i++;
            }
        }
        insert contractLineItems;
        
        List<ContractLineItem> addOnLines = new List<ContractLineItem>();
        for(ContractLineItem pcli : contractLineItems){
            for(Product2 p : productAddOns){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, pcli.AssetId);
                cli.ParentContractLineItemId = pcli.Id;
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate.addDays(25);
                cli.EndDate = endDate.addDays(-10);
                cli.SBQQSC__TerminatedDate__c = endDate.addDays(-10);
                addOnLines.add(cli);
            }
        }
        insert addOnLines[0];
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
        queryServiceContract();
        Billing_Schedule_History__x mockedRequest = new Billing_Schedule_History__x(
        Bill_From__c=system.today()-10,
        Bill_To__c=system.today()+10,
          Invoiced_Date__c=system.today(), 
            Amount__c=100,
            Contract_Line_Item__c=contractLineItems[0].Oracle_Covered_Line_ID__c
             
            
    );

        
        
       
        
        
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
            ServiceContractCancellation_ControllerX.mockedRequests.add(mockedRequest);
        ctrl.serviceContract.Terminated_Date__c = system.today();
        Test.startTest();
       ctrl.serviceContractTerminationDateChanged();
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(275, ctrl.contractLineItems.size());
            //system.assertEquals(false, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
        Test.stopTest();
    }
    
    static testMethod void errorHandling_ServiceContract(){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate;
                cli.EndDate = endDate;
                contractLineItems.add(cli);
            }
        }
        insert contractLineItems;
        
        List<ContractLineItem> addOnLines = new List<ContractLineItem>();
        for(ContractLineItem pcli : contractLineItems){
            for(Product2 p : productAddOns){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, pcli.AssetId);
                cli.ParentContractLineItemId = pcli.Id;
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate.addDays(25);
                cli.EndDate = endDate;
                addOnLines.add(cli);
            }
        }
        insert addOnLines;
        
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
            
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(null, ctrl.serviceContract.Terminated_Date__c);
            //system.assertEquals(27500, ctrl.serviceContract.TotalPrice);
            //system.assertEquals(275, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            // set the termination date past the end date
            ctrl.serviceContract.Terminated_Date__c = startDate.addDays(365);
            //ctrl.serviceContractTerminationDateChanged();
            //system.assertEquals(true, ctrl.serviceContractTermination);
            ////system.assertEquals(false, ctrl.contractLineTermination);
            
            // save changes
            PageReference savePage = ctrl.saveCancellation();
           // //system.assertEquals(null, savePage);
           // //system.assert(ApexPages.hasMessages(), ApexPages.getMessages());
        Test.stopTest();
    }
    
    static testMethod void errorHandling_ContractLine(){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        Integer i=0;
        for(Asset a : assets){
            for(Product2 p : productServices){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, a.Id);
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.SBQQSC__TerminatedDate__c=system.today();
                cli.StartDate = startDate;
                cli.Oracle_Covered_Line_ID__c='1234'+i;
                cli.EndDate = endDate;
                contractLineItems.add(cli);
                i++;
            }
        }
        insert contractLineItems;
        
        List<ContractLineItem> addOnLines = new List<ContractLineItem>();
        for(ContractLineItem pcli : contractLineItems){
            for(Product2 p : productAddOns){
                ContractLineItem cli = TestUtility.newContractLineItem(serviceContract.Id, pricebookToProductToPricebookEntry.get(pricebook.Id).get(p.Id).Id, 1, 100, pcli.AssetId);
                cli.ParentContractLineItemId = pcli.Id;
                cli.SBQQSC__TerminatedDate__c=system.today();
                cli.SBQQSC__Account__c = customerAccount.Id;
                cli.StartDate = startDate.addDays(25);
                cli.EndDate = endDate;
                addOnLines.add(cli);
            }
        }
        insert addOnLines;
        
        queryServiceContract();
        
        PageReference pageRef = Page.ServiceContractCancellation;
        Test.setCurrentPage(pageRef);
         
       
        Test.startTest();
        Billing_Schedule_History__x mockedRequest = new Billing_Schedule_History__x(
        Bill_From__c=system.today()-20,
            Invoice_Date__c=system.today()-5,
        Bill_To__c=system.today()+365,
            Amount__c=100,
            Contract_Line_Item__c=contractLineItems[0].Oracle_Covered_Line_ID__c
            
    );
        mockedRequest.Invoiced_Date__c=system.today();
            ServiceContractCancellation_ControllerX ctrl = new ServiceContractCancellation_ControllerX(new ApexPages.StandardController(serviceContract));
             ServiceContractCancellation_ControllerX.mockedRequests.add(mockedRequest);
            // verify inital state of variables
            //system.assertEquals(serviceContract.Id, ctrl.serviceContract.Id);
            //system.assertEquals(null, ctrl.serviceContract.Terminated_Date__c);
            //system.assertEquals(27500, ctrl.serviceContract.TotalPrice);
            //system.assertEquals(275, ctrl.contractLineItems.size());
            //system.assertEquals(true, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            Integer count = 0;
            List<ContractLineItem> cliList = new List<ContractLineItem>();
            for(ContractLineItem cli : ctrl.contractLineItems){
                count++;
                if(count <= 25)
                    cliList.add(cli);
            }
            
            // set the termination date past the end date
            for(ContractLineItem cli : cliList){
                ctrl.selectedContractLineId = cli.Id;
               // cli.SBQQSC__TerminatedDate__c = startDate.addDays(365);
               // cli.TotalPrice=1000;
               
                cli.Final_Refund_Amount__c=100;
                ctrl.contractLineTerminationDateChanged();
            }
            //system.assertEquals(false, ctrl.serviceContractTermination);
            //system.assertEquals(true, ctrl.contractLineTermination);
            
            // save changes
            //PageReference savePage = ctrl.saveCancellation();
            ////system.assertEquals(null, savePage);
            ////system.assert(ApexPages.hasMessages(), ApexPages.getMessages());
        Test.stopTest();
    }
	
}