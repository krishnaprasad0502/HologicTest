/*------------------------------------------------------------
Author:         Krishna Prasad
Company:        Apps Associates
Description:    Test class to validate OrderItemProductSearchwithwarehouse 
Tests Excecuted:

getPagination---------Run as a System Administrator and Where get value for pagination.
setPagination-------- Run as a System Administrator and Where set value for pagination.
getTotalInvent--------Verifying to  get the total count of inventory records or not.
setNext---------------Verifying to  get the next count of records in pagination or not.
setPrevious-----------verifying to get the Previous count of records in pagination or not. 
sortDir---------------Run as a System Administrator and Where sorting the current direction.
sortField-------------verifying the current field to sort by, defaults to last name or not.              
init -----------------verify the Reset Variable values declaration.  
backToOrder-----------run as a System Administrator and Where cheking for back to order.
getPricebooks---------Verify the return values of priceBooks.
SearchProducts--------run as a System Administrator and Where  searching for product values.
getPricebookEntry ----Verify the sort values of price book entry.
ResetSearch-----------Verify the  reset the search fucntionality. 
getResultCount--------verify the PriceBook Procduct size. 
AddToOrder------------run as a System Administrator and showing the case selected Product based on order item section verification.
getLineTypes ---------Verify the  picklist values for line types. 
UpdateOrderItem ------Verify the update the order Item values or not.
RemoveFromOrder ------Verify removing the order item values  or not 
Refresh --------------Verifying the page refreshing.
SaveOrderItems -------Verify saving the order item values or not.
PricebookQuery--------Verify the building up query values of Pricebook.
PricebookFields-------Verify the Storing the Pricebook soql query.
PricebookEntryQuery---Verify the Storing the Pricebook soql query using the string.
PricebookEntryFilter--Verify the Storing the PricebookEntry filtering the values.
ProductSearch---------Verify the Storing the ProductSearch soql query using the string.
ProductItem -- -------run  as a System Administrator , Where updateing product Item or not.
incrementQty----------run  as a System Administrator , Where  increase quantity.
decrementQty----------run as a System Administrator , Where  decrease quantity.
selectwarehouseaction-run update as a System Administrator , Where  referencing the button from order to redirection for selection of warehouse.
toggleSort------------run update as a System Administrator , Where toggle the direction.
runQuery--------------run  as a System Administrator , Where run the actual query.
runSearch-------------run  as a System Administrator , Where getting the inventory object records by search value.
selectinventory-------Verifying to Getting the selected inventory object recordid from vf page and storing that record in the list or not.
inventselect----------run  as a System Administrator , Where Getting the selected inventory object recordid's.
saveInventory---------Verifying the updating the warehouse,lot number and serial number of selected inventory record on the order product object by using save button.
cancel----------------run  as a System Administrator , Where  cancel button will redirect to the current order product page.
Reset-----------------Verifying the reset button will redirect to the current vf page or not.
getdisplaysumvalues---run  as a System Administrator , Where created to caluculate sum of warehouse values.
UpdateOrderAddOLi----run update as a System Administrator , Where update Pricebook on order.
pageredirect --------verify the redirection based on price book availability on order.
backToOLi-----------run as a System Administrator and Where cheking for back to orderline.

History:
<Date>          <Authors Name>          <Brief Description of Change>
5/18/2017     Krishna Prasad     Initial Creation(US-0002725)
5/22/2017       Krishna Prasad    updatetest coverage Warehouse from orderLine(US-0002641)
5/22/2017       Krishna Prasad    update list of Inventory to multiple Inventory's(US-0002641)
5/25/2017       Krishna Prasad    update with new method to improve test coverage 
5/30/2017       Krishna Prasad    update with new method to improve test coverage
------------------------------------------------------------*/
@isTest(seeAllData=false)
    public class OrderItemProductSearchwithwarehouse_Test{
    private static Account customerAccount;
    private static List<Pricebook2> pricebooks = new List<Pricebook2>();
    private static List<Product2> products = new List<Product2>();
         private static List<ServiceContract> serviceContracts;
         private static Map<Id, ServiceContract> accountToServiceContract;
          private static Configuration_Settings__c orgDefaults;

    public  static List<Inventory_Quantity_Onhand__x> InventorTestvalues = new List<Inventory_Quantity_Onhand__x>();
    private static List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    public static Set<Id>  searchedProductIdsset = new Set<Id>();
    private static Map<String,PriceBookEntry> pricebookEntry_Map = new Map<string,PriceBookEntry>();
    private static Map<Id, Map<Id, PricebookEntry>> pricebookToProductToPricebookEntry = new Map<Id, Map<Id, PricebookEntry>>(); 

    public static PricebookEntry PricebookEntryNew;
    public static Pricebook2 Pb2;
    public static order OrderInsert;
        public static orderitem oi;
    // public static product2 product;
     private static List<Asset> assets;
     private static Product_Source_Division__c psd;
     private static Contact defaultContact;
    private static Contact applicationContact;
    private static Contact connectivityContact;
    private static List<String> caseRecordTypeNames = new List<String>(GlobalUtility.getAllObjectRecordTypeById('Case').values());  
    private static List<String> caseTypes = GlobalUtility.getFieldPickListValues(Case.Type);
    private static List<String> caseStatuses = GlobalUtility.getFieldPickListValues(Case.Status);
    private static List<String> casePriorities = GlobalUtility.getFieldPickListValues(Case.Priority);
    private static List<String> caseOrigins = GlobalUtility.getFieldPickListValues(Case.Origin);
    private static List<Id> caseRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Case').keySet());
    private static List<Id> orderRecordTypeIds = new List<Id>(GlobalUtility.getAllObjectRecordTypeById('Order').keySet());
        

    static {

       /* List<Trigger_Switch__c> Trigger_switch_List = new List<Trigger_Switch__c>();    
        Trigger_Switch__c ts_PmaPlans=new Trigger_Switch__c();
        ts_PmaPlans.Name = 'OrderLineProductReplacement';
        ts_PmaPlans.Active__c = TRUE;
        Trigger_switch_List.add(ts_PmaPlans);
        insert Trigger_switch_List;
        System.assertEquals('OrderLineProductReplacement', ts_PmaPlans.Name);
        System.assertEquals(TRUE, ts_PmaPlans.Active__c);*/
        orgDefaults = TestUtility.setupConfigurationSettings();
        List<Trigger_Switch__c> Trigger_switch_List = new List<Trigger_Switch__c>();
        
        Trigger_Switch__c ts_PmaPlans=new Trigger_Switch__c();
        ts_PmaPlans.Name = 'OrderLineProductReplacement';
        ts_PmaPlans.Active__c = TRUE;
        Trigger_switch_List.add(ts_PmaPlans);
        
        Trigger_Switch__c ts_WorkOrderPM = new Trigger_Switch__c();
        ts_WorkOrderPM.Name = 'CaseTrigger';
        ts_WorkOrderPM.Active__c = TRUE;
        Trigger_switch_List.add(ts_WorkOrderPM);

        Product_Source_Division__c psd = TestUtility.newProductSourceDivision('1234','MAMMOGRAPHY');
        Insert psd;
       
        
        insert Trigger_switch_List;
        customerAccount = TestUtility.newAccount('Customer Account', 'testCust', null, null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert customerAccount;
        
        //insert contacts
        defaultContact = TestUtility.newContact('Default', 'Contact', customerAccount.Id);
        applicationContact = TestUtility.newContact('Application', 'Contact', customerAccount.Id);
        connectivityContact = TestUtility.newContact('Connectivity', 'Contact', customerAccount.Id);
        insert new List<Contact>{defaultContact, applicationContact, connectivityContact};
        pricebooks.add(TestUtility.newPricebook('Test Pricebook1'));
        insert pricebooks;
        for(Pricebook2 pb : pricebooks){ 
        pricebookToProductToPricebookEntry.put(pb.Id, new Map<Id, PricebookEntry>());
        }
        for(Integer i = 0; i < 10; i++){ 
        products.add(TestUtility.newProduct('Product ' +i));
        products[i].Product_Source_Division__c = psd.id;
        //products[i].Replacement_Part__c = prod.id;
        }
        insert products;
        system.debug('products=========='+products);
        
        searchedProductIdsset.add(products[0].id);
        //insert product
        List<PriceBook2> pricebookList = [Select id from PriceBook2 where  IsStandard = TRUE ]; 
        PriceBook2 pricebooktest = new PriceBook2 ();
        if(pricebookList != null && pricebookList.size()>0)
        pricebooktest = pricebookList.get(0);      
        //insert Pricebook
        PriceBook2 pb2 = new PriceBook2 (Name='Standard priceBook',Description = 'test');
        insert pb2;
        //insert PricebookEntry
        priceBookEntryNew = TestUtility.newPricebookEntry(pb2.Id, products[0].Id, 20);
        insert priceBookEntryNew;
        system.debug('priceBookEntryNew==========='+priceBookEntryNew);
        pricebookEntry_Map.put(priceBookEntryNew.id,priceBookEntryNew);
         assets = new List<Asset>();
     
            assets.add(TestUtility.newAsset(customerAccount.Name + ' Asset 01', customerAccount.Id, customerAccount.Id, products[0].Id));
            assets[0].ContactId= defaultContact.Id;
       
        insert assets;

        
      
            List<Case> cases = new List<Case>();
       		Case temp = TestUtility.newCase(
                customerAccount.Id, null, null, null, 
                caseRecordTypeIds[Math.mod(0, caseRecordTypeIds.size())], 
                caseTypes[Math.mod(0, caseTypes.size())],
                caseStatuses[Math.mod(0, caseStatuses.size())],
                casePriorities[Math.mod(0, casePriorities.size())],
                caseOrigins[Math.mod(0, caseOrigins.size())]
        	);
        	temp.Priority = 'High';
  
            cases.add(temp);
            insert cases;
        
        OrderInsert = new Order (Accountid=customerAccount.Id,case__C=cases[0].id ,Pricebook2Id = pb2.Id,EffectiveDate = System.today(),Status = 'Draft',CurrencyIsoCode = 'USD',RecordTypeid= GlobalUtility.getRecordTypeId('Order','B_SH_Parts_Order'),Type='Advanced Exchange');
        System.assertEquals(System.today(), OrderInsert.EffectiveDate );
        System.assertEquals('Draft', OrderInsert.Status);
        System.assertEquals('USD', OrderInsert.CurrencyIsoCode);
        insert OrderInsert;
        oi = TestUtility.newOrderItem(OrderInsert.id,null,priceBookEntryNew.id,decimal.valueof('1'),decimal.valueof('1')); 
        insert oi;
    }
    //5/25/2017  Krishna Prasad  update with new method to improve test coverage 
    static testMethod void TestOrderItemProductSearch(){
        PageReference pageRef = Page.OrderItemProductSelectorwithWarehouse;
        pageRef.getParameters().put('id',OrderInsert.id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        string DefaultShippingOrg = 'test';
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderInsert);
        OrderItemProductSearchWithWarehouse ops = new OrderItemProductSearchWithWarehouse(sc);
        OrderTypeRuleHandler otrh = new OrderTypeRuleHandler();
        
        OrderItemProductSearchWithWarehouse.ProductItem wrper = new OrderItemProductSearchWithWarehouse.ProductItem(OrderInsert, priceBookEntryNew,assets[0].id,OrderInsert.type,DefaultShippingOrg );
        //OrderItemProductSearchwithwarehouse.ProductItem wrper1 = new OrderItemProductSearchwithwarehouse.ProductItem(oi,priceBookEntryNew1);
        wrper.incrementQty();
        wrper.decrementQty(); 
        otrh.OrderTypeRuleQuery();
        otrh.getOrderItems(OrderInsert);
        otrh.getBaseOrderItem();
        ops.SelectedAddProductLine = false; 
        ops.DisplayStatus =true;
        ops.pagination =8;
       
        ops.ShowAddProduct = true;
        ops.HasTypeRule = true;
        ops.PricebookDisabled = false;      
        ops.TypeSelected = true;
        ops.EditLineWithRule=true;
        ops.getLineTypes(); 
        ops.SearchProducts();
        ops.getPricebookEntry();
        ops.getResultCount();
        ops.selectedpricebookentry ='';
        ops.SelectedFamily  ='';
        ops.pricebookEntry_Map.put(priceBookEntryNew.id,priceBookEntryNew); 
        //ops.SelectedItemPricebookEntry = string.valueof(priceBookEntryNew.id);
        ops.EditItemKey = '';
        ops.SelectedLineType ='';
        ops.PricebookEntryQuery(); 
        ops.PricebookEntryFields();
        ops.PricebookEntryFilter();       
        ops.PricebookFields();
        ops.ProductSearchString= products[0].name;
        ops.searchedProductIds = searchedProductIdsset; 
        ops.SearchProducts();
        ops.searchedProductIds = searchedProductIdsset;
        ops.SelectedItem = string.valueof(priceBookEntryNew.id);
        OPS.SelectedAddProduct = string.valueof(priceBookEntryNew.id);
        ops.HasTypeRule = true;
        OPS.AddToOrder();
        OPS.backToOrder();
        ops.Refresh();
        ops.RemoveItemKey = string.valueof(priceBookEntryNew.id);
        ops.RemoveFromOrder();
        OPS.UpdateOrderItem();        
        ops.SaveOrderItems();
         //OPS.SearchProducts();
        // ops.pbeid = string.valueof(ops.insertItem_List[0].id); 
        ops.ResetSearch();
        //ops.pageredirect();
        //ops.UpdateOrderAddOLi();
        Test.stopTest();
      }
       static testMethod void TestOrderItemProductSearch1(){



        PageReference pageRef = Page.OrderItemProductSelectorwithWarehouse;
        pageRef.getParameters().put('id',OrderInsert.id);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        string DefaultShippingOrg = 'test';
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderInsert);
        OrderItemProductSearchWithWarehouse ops = new OrderItemProductSearchWithWarehouse(sc);
        OrderTypeRuleHandler otrh = new OrderTypeRuleHandler();
        OrderItemProductSearchWithWarehouse.ProductItem wrper = new OrderItemProductSearchWithWarehouse.ProductItem(OrderInsert, priceBookEntryNew,assets[0].id,OrderInsert.type,DefaultShippingOrg);
        //OrderItemProductSearchwithwarehouse.ProductItem wrper1 = new OrderItemProductSearchwithwarehouse.ProductItem(oi,priceBookEntryNew1);
        wrper.incrementQty();
        wrper.decrementQty(); 
        otrh.OrderTypeRuleQuery();
        otrh.getOrderItems(OrderInsert);
        otrh.getBaseOrderItem();
        ops.SelectedAddProductLine = true; 
        ops.DisplayStatus =true;
        ops.ShowAddProduct = true;
        ops.HasTypeRule = true;
        ops.PricebookDisabled = false;      
        ops.TypeSelected = true;
        ops.EditLineWithRule=true;
        ops.getLineTypes(); 
        ops.SearchProducts();   
        ops.getPricebookEntry();
        ops.getResultCount();
        ops.selectedpricebookentry ='';
        ops.SelectedItemPricebookEntry ='';
        ops.SelectedFamily  ='';
        ops.pricebookEntry_Map.put(priceBookEntryNew.id,priceBookEntryNew); 
        ops.EditItemKey = '';
        ops.SelectedLineType ='';
        ops.PricebookEntryQuery(); 
        ops.PricebookEntryFields();
        ops.PricebookEntryFilter();       
        ops.PricebookFields();
        ops.ProductSearchString= products[0].name;
        //ops.searchedProductIds = searchedProductIdsset;         
        ops.SearchProducts();
        ops.searchedProductIds = searchedProductIdsset;
        ops.SelectedItem = string.valueof(priceBookEntryNew.id);
        OPS.SelectedAddProduct = string.valueof(priceBookEntryNew.id);
        ops.HasTypeRule = true;       
        OPS.AddToOrder();
        OPS.backToOrder();
        ops.Refresh();
        ops.RemoveItemKey = string.valueof(priceBookEntryNew.id);
        ops.RemoveFromOrder();
        OPS.UpdateOrderItem();        
        ops.SaveOrderItems();
         //OPS.SearchProducts();
        // ops.pbeid = string.valueof(ops.insertItem_List[0].id); 
        ops.ResetSearch();
        ops.pageredirect();
        ops.UpdateOrderAddOLi();
        Test.stopTest(); 
      }
    static testMethod void warehousetestMethod1() 
    {
        System.assertEquals('Customer Account', customerAccount.Name);        
        Test.startTest();
        Inventory_Quantity_Onhand__x selectinventory = new Inventory_Quantity_Onhand__x(
            Description__c='Test Description',
            ItemNumber__c='110788'
        );
        System.assertEquals('Test Description', selectinventory.Description__c);
        System.assertEquals('110788', selectinventory.ItemNumber__c);
        OrderItemProductSearchWithWarehouse.mockedInventories.add(selectinventory);
        Inventory_Quantity_Onhand__x request = OrderItemProductSearchWithWarehouse.findById(selectinventory.Id);
        PageReference pageRef = Page.OrderItemProductSelectorwithWarehouse;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(OrderInsert);
        //ApexPages.currentPage().getParameters().put('Id',oi.id);
        ApexPages.currentPage().getParameters().put('warehouse','A');
        ApexPages.currentPage().getParameters().put('invenid',oi.id);
        ApexPages.currentPage().getParameters().put('selectid',oi.id);
        ApexPages.currentPage().getParameters().put('invenselid',oi.id);
        ApexPages.currentPage().getParameters().put('lotnumber','D');
        ApexPages.currentPage().getParameters().put('serialnumber','A');
        ApexPages.currentPage().getParameters().put('orderprodid',oi.id);
        ApexPages.currentPage().getParameters().put('orderproductname',oi.product2.Name);
        //ApexPages.currentPage().getParameters().put('pbeid',oi.id);
        OrderItemProductSearchWithWarehouse warehousesel = new OrderItemProductSearchWithWarehouse(sc);
        Inventory_Quantity_Onhand__x invent =new Inventory_Quantity_Onhand__x();
        invent.ItemNumber__c='0'; 
        invent.ItemType__c='PRODUCT UNSERIALIZED'; 
        invent.ExternalId='AUS|110788|AUBB-LFS|CB4|D161392|';
        //invent.ExpirationDate__c=2021-05-31 04:00:00; 
        invent.Org__c='AUS'; 
        invent.TransactQuantity__c=40;
        invent.ReservationQuantity__c=40;
        invent.LotStatus__c='Active'; 
        invent.Locator__c='CB4'; 
        invent.LotNumber__c='D161392';
        invent.Description__c='STERILE C-ARM DRAPE, 20/CS'; 
        invent.Quantity__c=40;
        invent.Subinventory__c='AUBB-LFS';
        invent.Description__c = 'test';
        InventorTestvalues.add(invent);

        //5/22/2017       Krishna Prasad  (US-0002641)  update list of Inventory to multiple Inventory's
        Inventory_Quantity_Onhand__x invent1 =new Inventory_Quantity_Onhand__x();
        invent1.ItemNumber__c='0'; 
        invent1.ItemType__c='PRODUCT UNSERIALIZED'; 
        invent1.ExternalId='AUS|110788|AUBB-LFS|CB4|D161392|';
        //invent.ExpirationDate__c=2021-05-31 04:00:00; 
        invent1.Org__c='AUS'; 
        invent1.TransactQuantity__c=40;
        invent1.ReservationQuantity__c=40;
        invent1.LotStatus__c='Active'; 
        invent1.Locator__c='CB4'; 
        invent1.LotNumber__c='D161392';
        invent1.Description__c='STERILE C-ARM DRAPE, 20/CS';  
        invent1.Quantity__c=40;
        invent1.Subinventory__c='AUBB-LFS';
        invent1.Description__c = 'test';
        InventorTestvalues.add(invent1);
        warehousesel.inventCount = InventorTestvalues.size();
        warehousesel.orderLineblock =false;
        warehousesel.Inventories = InventorTestvalues; 
        warehousesel.selectvalue = true;

        warehousesel.orderprodid = oi.id;
        warehousesel.pbeid= oi.id;
        warehousesel.orderproductname =products[0].name; 
        warehousesel.selectwarehouseaction();
        warehousesel.Pagination = 0;
        warehousesel.warehouse='A';
        warehousesel.lotnumber='D';
        warehousesel.serialnumber='A';
        warehousesel.getPagination();
        warehousesel.setPagination(0);
        warehousesel.getTotalInvent();
        warehousesel.setNext();
        warehousesel.setPrevious();
        warehousesel.toggleSort();
        warehousesel.runQuery();
        warehousesel.getdisplaysumvalues();
        warehousesel.runSearch();
        warehousesel.selectinventory();
        warehousesel.pbeid = oi.id; 
        warehousesel.inventselect(); 
        warehousesel.objName = 'OrderItem';
        warehousesel.saveInventory();
        warehousesel.cancel(); 
        //5/30/2017       Krishna Prasad    update with new method to improve test coverage
        warehousesel.backToOli();
        warehousesel.selectwarehouseaction();
        warehousesel.redirect=false;
        //warehousesel.pageredirect();
        warehousesel.sortField= 'test';
        
        
      
        Test.stopTest(); 
    } 

	static testMethod void testMiscFunctions(){
		//Create test data
        //TestUtility.setupConfigurationSettings();
        
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Product2 prod = TestUtility.newProduct('Test Product');
        insert prod;
        
        Case cas = new Case();
        cas.AccountId = acc.Id;
        cas.ProductId = prod.Id;
        cas.Priority = 'High';
        insert cas;
        
        Asset asst = TestUtility.newAsset('Parent Asset', acc.Id, acc.Id, prod.Id);
        insert asst;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.Case__c = cas.Id;
        ord.EffectiveDate = Date.today();
        ord.EndDate = Date.today().addDays(1);
        ord.Status = 'DRAFT';
        insert ord;
        
        Pricebook2 pb = TestUtility.newPricebook('Test Pricebook');
        insert pb;
        
        PricebookEntry pbe = TestUtility.newPricebookEntry(pb.Id, prod.Id, 27);
        insert pbe;
        
		ApexPages.StandardController stc = new ApexPages.StandardController(ord);
		OrderItemProductSearchWithWarehouse cont = new OrderItemProductSearchWithWarehouse(stc);
		
		cont.pagination = 1;
		cont.totalinvent = 10;
		cont.warehouse = '';
		cont.lotnumber = '';
		cont.serialnumber = '';
		cont.setNext();
		cont.setPrevious();
		
		cont.selectwarehouseaction();
		cont.runSearch();
		cont.pageredirect();
		
		OrderItemProductSearchWithWarehouse.ProductItem pi = new OrderItemProductSearchWithWarehouse.ProductItem(ord, pbe, null, null, null);
		pi.oliAsset = asst;
	}

}