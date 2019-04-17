/*------------------------------------------------------------
Author:      Krishna Prasad
Company:     Apps Associates
Description: OrderItemProductSearchwithwarehouse 
Test Class:  OrderItemProductSearchwithwarehouse_Test
History:
<Date>        <Authors Name>              <Brief Description of Change>
5/8/2017       Krishna Prasad              Initial Creation(US-0002725)
5/22/2017      Krishna Prasad             assign  pricebook id to variable (US-0002725)
5/22/2017      Krishna Prasad             update Warehouse from orderLine(US-0002641)
5/30/2017      Krishna Prasad             Created method for back to the Order line(enhancement for back to Oli button)
5/30/2017      Krishna Prasad             Get product name for default search(enhancement for product search by default)
5/30/2017      Krishna Prasad             Assign orderitem id from orderline item page if pbeid is null (enhancement for back to Oli button) 
06/06/2017     Krishna prasad             updated on enhancement to display updated Oli (US-0002725)
03/07/2017     Krishna prasad             return Asset field to updated Oli (US-0002725) defect #429
01/03/2018     Mani Sundaresan            Update to populate returned asset on Order Product if Line Type is RMA (US-3762)
------------------------------------------------------------*/

public with sharing class OrderItemProductSearchWithWarehouse{

        public boolean hidewarehousepageblock {set;get;}
        //wrapper class variable
        public List<wrapperClassController> displaysumvalues {set;get;}
        public List<oli> OrItems { get; set; }
        public List<Inventory_Quantity_Onhand__x> selectinventory;
        public List<Inventory_Quantity_Onhand__x> inventselect;
        Public String orderproductname; 
        public boolean block{get;set;}
        public boolean orderLineblock{get;set;}
       // public  String clearpagination {get;set;}
        public boolean selectvalue{get;set;}
        Public Id orderprodid;
        
        Public string objName;
        
        Public List<Inventory_Quantity_Onhand__x> Inventories{get;set;}
        Public List<Inventory_Quantity_Onhand__x> Inventoriesselection{get;set;}
        public Map<id,Inventory_Quantity_Onhand__x> Inventoriesmap {set;get;}
        private String soql {get;set;}
        public string warehouse {get;set;}
        public string LotNumber {get;set;}
        public string SerialNumber {get;set;}
        // offset variable used for pagination
        public Integer pagination = 0;
        //varible to hold the total contact returned
        public Integer inventCount{get;set;}
        public Map<id,wrapperClassController> wrapperClassmap {set;get;}
/*------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  Method to get value for pagination
                         
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
        public Integer getPagination(){
              return pagination;
          }  
/*-------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  Method to set value for pagination
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/    
        
        public void setPagination(Integer pagination){
              this.pagination = pagination;
        }
          
          // variable containing total contact
        public Integer totalinvent {get; set;}
        
/*------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  Method to get the total count of inventory records
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
        public void getTotalInvent(){
        
              totalinvent = [SELECT Count() from Inventory_Quantity_Onhand__x where ItemNumber__c =: orderproductname]; 
             
        }
/*------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: Method to get the next count of records in pagination.
                     
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/
        public void setNext(){
              if(pagination < totalinvent)
                  pagination += 25;
              else
                  pagination = totalinvent;
              
              runQuery();
        }
/*-------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: Method to get the Previous count of records in pagination. 
                         
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/
         
        public void setPrevious(){
              if(pagination != 0)
                  pagination -= 25;
              else
                  pagination = 0; 
                
                  runQuery();
        }
/*-------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: The current sort direction. defaults to asc
                         
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/
        public String sortDir {
            get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
            set;
        }
/*------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: The current field to sort by. defaults to last name
                         
    Inputs:      N/A 
    Returns: 
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/
           
        public String sortField {
            get  { if (sortField == null) {sortField = 'Org__c'; } return sortField;  }
            set;
        }
            //Global declaration's Start
            private final String STRING_COMMA = ',';
            private final String STRING_SPACE = ' ';
            private final String STRING_BLANK = '';
            public Order parentOrder { get; set; }
            private OrderTypeRuleHandler orderRuleHandler;
            static Boolean C;
            //Mapping the PriceBookEntry values 
            public Map<String,PriceBookEntry> pricebookEntry_Map {get; set;}
           //The collection of Product to display
            public List<ProductItem> OrderItems { get; set; }
            
            public Boolean DisplayStatus { get; set; }
            public Boolean TypeSelected { get; set; }
            public Boolean PricebookDisabled { get; set; }
            public Boolean HasTypeRule { get; set; }
            public Boolean ShowAddProduct { get; set; }
            public Boolean EditLineWithRule { get; set; }
           //variable containing the Selected LineType
            public String SelectedLineType { get; set; }
            public String RemoveItemKey { get; set; }
            public String EditItemKey { get; set; }
            public Boolean SelectedAddProductLine { get; set; }
            public String pbeid{ get; set; }
            public String ProductSearchString { get; set; }
            public String ServiceOrderWarehouse { get; set; }
           //variable containing the Selected Pricebook
            public String SelectedPricebook   { get; set; }
           //variable containing the selected pricebookentry
            public String selectedpricebookentry { get; set;}
            public String SelectedAddProduct  { get; set; }
            public String SelectedRemProduct  { get; set; }
            public String SelectedFamily { get; set; }
            //variable containing the Selected ItemPricebookEntry
            public String SelectedItemPricebookEntry { get; set; }
            public String SelectedItem { get; set; }
            //the collection of PricebookOptions  to display
            public List<SelectOption> PricebookOptions { get; set; }
             //the collection of PricebookProducts to display
            public List<PriceBookEntry> PricebookProducts { get; set; }
             //the collection of PriceBookOptions to display
            public List<SelectOption> PBOptions { get; set; }
            //variable containing searchKey value
            private String searchKey;
            //the collection of searchedProductIds
            public Set<Id> searchedProductIds   = new Set<Id>(); 
            private Map<String,String> lineType_Map;
            public boolean redirect;
            public id  caseAsset;
            public   List<OrderItem> insertItem_List = new List<OrderItem>();
            public  Order ory;
            //public Order orpb ;
            //Global declaration's End
/*---------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  The extension constructor initializes the private member variable by using the getRecord method from the standard controller.
    Inputs:      string 
    Returns:    boolean
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Krishna Prasad     Initial Creation(US-0002725)
    5/22/2017   Krishna Prasad     Assign object name to string from  stdController(US-0002641) 
    5/22/2017   Krishna Prasad     (US-0002641) added price book to getPricebooks
    5/30/2017   Krishna Prasad     Get product name for default search(enhancement for product search by default)
    5/30/2017   Krishna Prasad     Assign orderitem id from orderline item page if pbeid is null (enhancement for back to Oli button)
    07/06/2017  Krishna prasad     updated on enhancement to display updated Oli  (US-0002725)
    07/06/2017  Krishna prasad     updated on enhancement to default asset on "RMA"  (US-0002725)

--------------------------------------------------------------*/
public OrderItemProductSearchwithwarehouse(ApexPages.StandardController stdController) {
    
                hidewarehousepageblock=false;
                selectinventory =  new List<Inventory_Quantity_Onhand__x>();
                wrapperClassmap= new Map<id,wrapperClassController>();
                Inventoriesmap= new Map<id,Inventory_Quantity_Onhand__x>();
                inventselect =  new List<Inventory_Quantity_Onhand__x>();
                selectvalue = false;
                Inventories = new List<Inventory_Quantity_Onhand__x>();
                Inventoriesselection = new List<Inventory_Quantity_Onhand__x>(); 
                displaysumvalues=new List<wrapperClassController>();
                OrItems = new list<oli>();
                  
        
        //5/22/2017   Krishna Prasad (US-0002641)   Assign object name to string from  stdController
        objName=  stdController.getRecord().getSObjectType().getDescribe().getName();
        
        if(objName !='OrderItem'){ //validating if the object is OrderItem
            this.parentOrder = (Order) stdController.getRecord();
            
            //07/06/2017  Krishna prasad     updated on field in query to default asset on "RMA"  (US-0002725)
            ory = [SELECT Pricebook2Id, id,Case__r.Productid,Case__r.Asset.name,Case__r.Assetid,Type FROM Order WHERE id = :parentOrder.id];           
            //5/22/2017   Krishna Prasad (US-0002641) added price book to getPricebooks
           
            caseAsset = ory.Case__r.Assetid;
            getPricebooks(ory.Pricebook2Id);
            if(ory.Case__r.Productid != null){
                //5/30/2017   Krishna Prasad    Get product name for default search
                product2 prodetails = [SELECT name FROM product2 WHERE id = :ory.Case__r.Productid];
                if(prodetails.name !=null){
                        ProductSearchString = prodetails.name ;
                        
                }
                if(ProductSearchString != null){
                        pricebookEntry_Map = new Map<string,PriceBookEntry>();
                        PBOptions = new List<SelectOption>();
                        init();  
                        SearchProducts();
                        getResultCount();
                        DisplayStatus = true;
                    
                }          
            }else{
                       DisplayStatus = FALSE;
                       pricebookEntry_Map = new Map<string,PriceBookEntry>(); 
                        ProductSearchString = STRING_BLANK ;
            }
            
            orderRuleHandler = new OrderTypeRuleHandler();
             //pricebookEntry_Map = new Map<string,PriceBookEntry>();
            init();     
           
            // validating if the order is related to a pricebook
            if(ory.Pricebook2Id != null){ 
             redirect=true;
            }   else{
            redirect=false;
            } //end
              
            OrderItems = new List<ProductItem>();
            
            
            TypeSelected = FALSE;
            selectvalue = false;
            SelectedAddProductLine = false;
            //  5/30/2017   Krishna Prasad   Assign orderitem id from orderline item page if pbeid is null 
              if(pbeid == null){
               pbeid  = ApexPages.currentPage().getParameters().get('id');
              }
        }
        
    }
/*--------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description: Variable initializion and declaration 
    Inputs:      string 
    Returns:    N/A
      
    History:
    <Date>         <Authors Name>       <Brief Description of Change>
    5/8/2017     Krishna Prasad       Initial Creation(US-0002725)
--------------------------------------------------------------*/
    private void init() {
       
        //PricebookProducts = new List<PriceBookEntry>();
        searchedProductIds = new Set<Id>();
        //pricebookEntry_Map = new Map<string,PriceBookEntry>();
        lineType_Map = new Map<String,String>();
        //PBOptions = new List<SelectOption>();
        PricebookDisabled = FALSE;
        EditLineWithRule = FALSE;
        //ProductSearchString = STRING_BLANK;
        //SelectedPricebook = STRING_BLANK;
        SelectedAddProduct = STRING_BLANK;
        SelectedRemProduct = STRING_BLANK;
        searchKey = STRING_BLANK;
        
    }
    
/*---------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  Page reference method for to back the Order 
                         
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/8/2017     Krishna Prasad     Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
    public PageReference backToOrder() {
        
        PageReference pageRef = new PageReference('/' + parentOrder.Id);
        pageRef.setRedirect(TRUE);
        return pageRef;     
    }/*---------------------------------------------------------------
    Author:      Krishna Prasad
    Company:     Apps Associates
    Description:  Page reference method for to back the Order line
                         
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>     <Brief Description of Change>
    5/30/2017     Krishna Prasad    Created method for back to the Order line
--------------------------------------------------------------*/ 
    public PageReference backToOli() {
        
        PageReference pageRef = new PageReference('/' + pbeid);
        pageRef.setRedirect(TRUE);
        return pageRef;     
    }
/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  This method will return the list of priceBooks  
                         
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
 5/22/2017  Krishna Prasad (US-0002725) assign  pricebook id to variable 
--------------------------------------------------------------*/ 
    
    public void getPricebooks(id opId ) {
      //5/22/2017  Krishna Prasad (US-0002725) assign  pricebook id to variable 
        SelectedPricebook = opId;
        // validating if the collection of Pricebookoptions is null or empty
        if(PricebookOptions == NULL || PricebookOptions.isEmpty()) {
            PricebookOptions = new List<SelectOption>();
            PricebookOptions.add(new SelectOption('temp','temp'));
            for(Pricebook2 pBook : Database.query(PricebookQuery())) {
                //Validatig if the pricebook is a standard pricebook
                if(pBook.IsStandard) {
                    PricebookOptions.set(0, new SelectOption(pBook.Id,pBook.Name));
                } else {
                    PricebookOptions.add(new SelectOption(pBook.Id,pBook.Name));   
                }                
            }
        }
    } 
/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Page reference method for to search the products 
                 
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
    public PageReference SearchProducts() {
        //pricebookEntry_Map = new Map<string,PriceBookEntry>();
        PricebookProducts = new List<PriceBookEntry>();
        PBOptions = new List<SelectOption>();
        //validating if the variable containing the Selected ItemPricebookEntry is not blank, then verifying if the value exists in the map and adding the values to the list
        if(String.isNotBlank(SelectedItemPricebookEntry)) {
        if(pricebookEntry_Map.containsKey(SelectedItemPricebookEntry)){
            PBOptions.add(new SelectOption(pricebookEntry_Map.get(SelectedItemPricebookEntry).Id,
                                            pricebookEntry_Map.get(SelectedItemPricebookEntry).Product2.Name));
          }                                  
        }
        //validating if the variable ProductSearchString is not blank, iterating the records and adding the id's to the set
        if(String.isNotBlank(ProductSearchString)) {
            for(List<SObject> searchReturn : Search.query(ProductSearch())) {
                if(searchReturn.getSObjectType() == Schema.Product2.sObjectType) {
                    for(Product2 pdct : (List<Product2>) searchReturn) {
                        searchedProductIds.add(pdct.Id);
                    }
                }
            }
        }
        //validating if the set is not null, iterating the records and adding the values to the list
        if(searchedProductIds != NULL && !searchedProductIds.isEmpty()) {
            for(PriceBookEntry pbe : Database.query(PricebookEntryQuery())) {
                system.debug('pbe:::'+pbe);
                PricebookProducts.add(pbe);
                pricebookEntry_Map.put(pbe.id,pbe);
                PBOptions.add(new SelectOption(pbe.id,pbe.Product2.Name));
            }            
        }
        return NULL;
    }
    //it returns the price book picklist options
    public List<SelectOption> getPricebookEntry() {
        PBOptions.sort();
        return PBOptions;
    }
    //It reset the search fucntionality on the current page 
    public PageReference ResetSearch() {
        init();
        return NULL;
    }
     //It will return PriceBook Procduct size
    public Integer getResultCount() {

        return PricebookProducts.size();
    }
/*------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Page reference method used to showcase selected Product on order item section 
    Inputs:      N/A 
    Returns:     N/A  

    <Date>      <Authors Name>    <Brief Description of Change>
    4/7/2017     Greg               Initial Creation(US-0002725)
    5/5/2017    Krishna Prasad      Added logic to handle displaying product without defaulting any line type as part of US-0002725
    06/06/2017  Krishna Prasad      updated warper list with case asset and order type
--------------------------------------------------------------*/ 
    public PageReference AddToOrder() {
        
        //Add To Order START
        if(String.isNotBlank(SelectedAddProduct)) {
            PricebookDisabled = TRUE;
            SelectedItemPricebookEntry = SelectedAddProduct;
            //validate product contains in order price book.            
            if(pricebookEntry_Map.containsKey(SelectedAddProduct)) {
                //27/06/2017  Krishna Prasad     query to find Service_Order_Warehouse__c for selected product 
                 product2 prodetailsWareHouse = [SELECT name,Service_Order_Warehouse__c FROM product2 WHERE id = :pricebookEntry_Map.get(SelectedAddProduct).Product2Id];
                 ServiceOrderWarehouse = prodetailsWareHouse.Service_Order_Warehouse__c; 
                if(HasTypeRule && !SelectedAddProductLine) {   
                    
                    for(OrderItem item : orderRuleHandler.getOrderItems(parentOrder)) {
                        //06/06/2017  Krishna Prasad      updated warper list with case asset and order type
                        ProductItem pItem = new ProductItem(item, pricebookEntry_Map.get(SelectedAddProduct),caseAsset,ory.Type,ServiceOrderWarehouse);

                        pItem.hasRule = TRUE;
                        pItem.hasRuleEdit = TRUE;
                        ShowAddProduct = FALSE;
                        OrderItems.add(pItem);
                    }
                } else {
                    //06/06/2017  Krishna Prasad      updated warper list with case asset and order type
                    OrderItems.add(new ProductItem(parentOrder,pricebookEntry_Map.get(SelectedAddProduct),caseAsset,ory.Type,ServiceOrderWarehouse));
                }
            }
        }
        //AddToOrder END'
        SelectedAddProductLine = false;
        return NULL;
    }
    


/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  It will return the picklist values line types
                         
    Inputs:      N/A 
    Returns:    PageReference
     
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
--------------------------------------------------------------*/
    
    public List<SelectOption> getLineTypes() {
        List<SelectOption> lineType_List = new List<SelectOption>();
        for(String lineType : lineType_Map.values()) {
            lineType_List.add(new SelectOption(lineType,lineType));
        }
        lineType_List.sort();
        return lineType_List;
    }
/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Page reference method for update the order Item values 
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
    public PageReference UpdateOrderItem() {
       
        //Validating if the string variables are not blank and iterating the records in the list
        if(String.isNotBlank(SelectedItemPricebookEntry) && String.isNotBlank(SelectedItem)) {
            
            Boolean showAdd = TRUE;
            for(ProductItem pItem : OrderItems) {
                system.debug('pItem::'+pItem.key);
                system.debug('SelectedItem::'+SelectedItem);
                if(SelectedItem == pItem.key) {
                   
                    
                    pItem.pBe = pricebookEntry_Map.get(SelectedItemPricebookEntry);
                    pItem.oItem.PriceBookEntryId = pricebookEntry_Map.get(SelectedItemPricebookEntry).Id;
                    pItem.hasRuleEdit = FALSE;                   
                } else if(pItem.hasRuleEdit) {
                    showAdd = FALSE;
                }
                ShowAddProduct = showAdd;
            }
        }
        
        return NULL;
    }
/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Page reference method for removing the order values  
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017      Greg               Initial Creation(US-0002725)
--------------------------------------------------------------*/ 
    public PageReference RemoveFromOrder() {
 
        // validating if the string variable is not blank
        if(String.isNotBlank(RemoveItemKey)) {
            
            //Iterating the orderitems
            for(Integer i = 0; i < OrderItems.size(); i++) {
               
                //if the key matches then the orderitem is removed from the list
                if(OrderItems.get(i).key == RemoveItemKey) {
                    OrderItems.remove(i);
                }
            }
        }
        
        return NULL;
    }
   
     //It will refresh the page
    public PageReference Refresh() {
        HasTypeRule = orderRuleHandler.OrderTypeHasRule(parentOrder.Type);

        return NULL;
    }
/*------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Page reference method for saving the order item values.
    Inputs:      N/A 
    Returns:    PageReference
  
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
    07/06/2017  Krishna Prasad      updated with error handling
    04/11/2018  Ronald Mendoza      Replaced Asset__c with SBQQ__Asset__c reference due to duplicate issue (US-0003947)
 -------------------------------------------------------------*/ 
    public PageReference SaveOrderItems() {
       
        //validating if the orderitems list has records
        if(OrderItems != NULL && !OrderItems.isEmpty()) {
            selectvalue = true;
         
            //if orderitems has records, each record is iterated and added to the list
            for(ProductItem item : OrderItems) {
                
                //Update to populate returned asset on Order Product if Line Type is RMA (US-3762) - Mani Sundaresan
                if(item.oItem.Line_Type__c =='RMA' && item.oItem.Returned_Asset__c == null)
                    //Replaced Asset__c with SBQQ__Asset__c reference due to duplicate issue (US-0003947)
                    //item.oItem.Returned_Asset__c = item.oItem.Asset__c;
                    item.oItem.Returned_Asset__c = item.oItem.SBQQ__Asset__c;
                
                if(item.oItem.Line_Type__c =='RMA' && ory.Type == 'Standard Order'){
	              	item.oItem.UnitPrice = 0;
	              	item.oItem.Quantity *= -1;
	            }
                
                insertItem_List.add(item.oItem);
            }
            //validating if the list has records and then inserting the records
            if(!insertItem_List.isEmpty()) {
                //07/06/2017  Krishna Prasad      updated with error handling
                try{
                    insert insertItem_List;                  
                    orderLineblock = true;
                }
                catch(Exception ex){
                    insertItem_List.clear();                   
                    ApexPages.addMessages(ex);
                }
               
            }
        }
        return null;
    }

/*--------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description:  Storing the soql query in the string 
                     
    Inputs:      N/A 
    Returns:    PageReference
  
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
--------------------------------------------------------------*/
    @TestVisible
    private String PricebookQuery() {
        List<String> priceBookQuery = new List<String>();
            priceBookQuery.add('SELECT');
            priceBookQuery.add(PricebookFields());
            priceBookQuery.add('FROM');
            priceBookQuery.add('Pricebook2');
            priceBookQuery.add('ORDER BY');
            priceBookQuery.add('Name');
        return String.join(priceBookQuery,STRING_SPACE);
    }
    // Storing the PricebookField soql query in the string 
    @TestVisible
    private String PricebookFields() {
        List<String> pbFields = new List<String>();
            pbFields.add('Id');
            pbFields.add('Name');
            pbFields.add('isActive');
            pbFields.add('IsStandard');
        return String.join(pbFields,STRING_COMMA);
    }
    //Storing the soql query in the string 
    @TestVisible
    private String PricebookEntryQuery() {
        List<String> priceBookQuery = new List<String>();
            priceBookQuery.add('SELECT');
            priceBookQuery.add(PricebookEntryFields());
            priceBookQuery.add('FROM');
            priceBookQuery.add('PricebookEntry');
            priceBookQuery.add(PricebookEntryFilter());
        return String.join(priceBookQuery,STRING_SPACE);
    }
    //Storing the PricebookEntry soql query in the string
    @TestVisible
    private String PricebookEntryFields() {
        List<String> pbeFields = new List<String>();
            pbeFields.add('Id');
            pbeFields.add('Name');
            pbeFields.add('Pricebook2Id');
            pbeFields.add('Pricebook2.Name');
            pbeFields.add('Pricebook2.isActive');
            pbeFields.add('Pricebook2.IsStandard');
            pbeFields.add('Product2Id');
            pbeFields.add('Product2.Name');
            pbeFields.add('Product2.Family');
            pbeFields.add('Product2.Description');
            pbeFields.add('Product2.IsActive');
            pbeFields.add('Product2.ProductCode');
            pbeFields.add('Product2.QuantityUnitOfMeasure');
            pbeFields.add('ProductCode');
            pbeFields.add('UnitPrice');
        return String.join(pbeFields,STRING_COMMA);
    }
     //Storing the PricebookEntry soql query in the string 
    @TestVisible
    private String PricebookEntryFilter() {
        List<String> pbeFilter = new List<String>();
            pbeFilter.add('WHERE');
            pbeFilter.add('Pricebook2.isActive');
            pbeFilter.add('=');
            pbeFilter.add('TRUE');
            pbeFilter.add('AND');
            pbeFilter.add('Product2.IsActive');
            pbeFilter.add('=');
            pbeFilter.add('TRUE');
        //validating if the set collection of searchedProductIds has id's
        if(searchedProductIds != NULL && !searchedProductIds.isEmpty()) {           
            pbeFilter.add('AND');
            pbeFilter.add('Product2Id');
            pbeFilter.add('IN:');
            pbeFilter.add('searchedProductIds');
        }
        //validating if the variable is not blank
        if(String.isNotBlank(SelectedPricebook)) {
            pbeFilter.add('AND');
            pbeFilter.add('Pricebook2Id');
            pbeFilter.add('=:');
            pbeFilter.add('SelectedPricebook');
        }
        return String.join(pbeFilter,STRING_SPACE);
    }
     //Storing the ProductSearch soql query in the string 
    @TestVisible
    private String ProductSearch() {
        List<String> productSearch = new List<String>();
        searchKey = '*' + ProductSearchString + '*';
            productSearch.add('FIND:');
            productSearch.add('searchKey');
            productSearch.add('IN ALL FIELDS');
            productSearch.add('RETURNING');
            productSearch.add('Product2(Id)');
        return String.join(productSearch,' ');
    }
/*------------------------------------------------------------
    Author:      Greg
    Company:    Apps Associates
    Description: Wrapper  class  for updateing product Item  
                     
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    5/8/2017    Greg     Initial Creation(US-0002725)
    5/302017   Krishna Prasad (US-0002641)   Upadated Asset And ShippingInstructions
    06/06/2017  Krishna Prasad      update funtionalty with defaulting asset
    03/07/2017  Krishna prasad     Return Asset field to be updated Oli (US-0002725) defect #429
--------------------------------------------------------------*/

            
    public class ProductItem {
        public String key { get; set; }
        public Boolean hasRuleEdit { get; set; }
        public Boolean hasRule { get; set; }
        public OrderItem oItem { get; set; }
        public PriceBookEntry pBe { get; set; }

        
        // 5/302017   Krishna Prasad (US-0002641)   intilized Asset And ShippingInstructions
        public Asset oliAsset { get; set; }
        
        

        public ProductItem(Order ord, PriceBookEntry entry,id caseAsset,string type,string ServiceOrderWarehouse) {
        
            System.debug('Method 1');
           
            this.oItem = new OrderItem();
            this.pBe = new PricebookEntry();
            this.pBe = entry;
            this.oItem.Product2Id = entry.Product2Id;
            this.oItem.OrderId = ord.Id;
            this.oItem.PricebookEntryId = entry.Id;
            this.oItem.Quantity = 1;
           
            this.oItem.UnitPrice = entry.UnitPrice;
            this.oItem.ServiceDate = ord.EffectiveDate;
            
            System.debug('OI Line Type:'+oItem.Line_Type__c);
            System.debug('type:'+type);
            //this.oItem.Asset__c = null;
            //06/06/2017  Krishna Prasad     update funtionalty with defaulting asset by line type 'RMA' and order type 'Advanced Exchange'
            //03/07/2017  Krishna prasad     Return Asset field to be updated Oli (US-0002725) defect #429
            if(oItem.Line_Type__c =='RMA' && (type =='Advanced Exchange' || type == 'Standard Order')){
               //this.oItem.Asset__c = caseAsset;
               this.oItem.SBQQ__Asset__c = caseAsset;
              this.oItem.Returned_Asset__c = caseAsset;
              
            }else{
                //this.oItem.Asset__c = null;
                this.oItem.SBQQ__Asset__c = null;
                 if(oItem.Line_Type__c =='Shipment' && type =='Advanced Exchange'){
                 this.oItem.Returned_Asset__c = caseAsset;
                 }           
            }
            if(oItem.Line_Type__c !='RMA'){

                this.oItem.Warehouse__c = ServiceOrderWarehouse; 
            }

        
                this.oItem.Shipping_Instructions__c ='';
            //validating if the end date is not null
            if(ord.EndDate != NULL) {
                this.oItem.EndDate = ord.EndDate;
            } 
            hasRule = FALSE;
            hasRuleEdit = FALSE;
            key = oItem.OrderId + '_' + oItem.PricebookEntryId;
            
        }
        public ProductItem(OrderItem item, PriceBookEntry entry,id caseAsset,string type,string ServiceOrderWarehouse) {
            
            System.debug('Method 2');
            this.oItem = new OrderItem();
            this.pBe = new PricebookEntry();
            this.oItem = item;
            this.pBe = entry;
            this.oItem.Product2Id = entry.Product2Id;
            
            //this.oItem.Asset__c = null;
            //06/06/2017  Krishna Prasad     update funtionalty with defaulting asset by line type 'RMA' and order type 'Advanced Exchange'
            //03/07/2017  Krishna prasad     Return Asset field to be updated Oli (US-0002725) defect #429
            if(oItem.Line_Type__c == 'RMA'&& (type =='Advanced Exchange'|| type == 'Standard Order')){
               //this.oItem.Asset__c = caseAsset;
               this.oItem.SBQQ__Asset__c = caseAsset;
                this.oItem.Returned_Asset__c = caseAsset;
            }else{
               //this.oItem.Asset__c = null;
               this.oItem.SBQQ__Asset__c = null;
              if(oItem.Line_Type__c =='Shipment' && type =='Advanced Exchange'){
                 this.oItem.Returned_Asset__c = caseAsset;
                 }  
                            
            }
             if(oItem.Line_Type__c !='RMA'){

                this.oItem.Warehouse__c = ServiceOrderWarehouse; 
            }
             this.oItem.Shipping_Instructions__c ='';
            this.oItem.PricebookEntryId = entry.Id;
            //validating if the unit price on pricebookentry, orderitem is not null and then assigning the unit price to orderitem
            if(pBe.UnitPrice != NULL && oItem.UnitPrice == NULL) {
                oItem.UnitPrice = pBe.UnitPrice;
            }
            hasRule = FALSE;
            hasRuleEdit = FALSE;
            //key = oItem.OrderId + '_' + oItem.PricebookEntryId;
            key = oItem.OrderId + '_' + oItem.PricebookEntryId + '_' + oItem.Line_Type__c;  
            
        }
        //method to increase quantity
        public void incrementQty() {
            oItem.Quantity++;
        }
        //method to decrease quantity
        public void decrementQty() {
            oItem.Quantity--;
        }
    }
  /*------------------------------------------------------------
  Author:     Krishna Prasad
  Company:    Apps Associates
  Description: referencing the button from order to redirection for selection of warehouse.  
                     
  Inputs:      N/A 
  Returns:    PageReference
  
  History:
  <Date>      <Authors Name>    <Brief Description of Change>
  4/7/2017    Krishna Prasad    Initial Creation(US-0002725)
  5/22/2017   Krishna Prasad   Assign orderitem id from orderline item page (US-0002641) 
  ------------------------------------------------------------*/    
    
          public void selectwarehouseaction() {
               displaysumvalues.clear();               
                hidewarehousepageblock =true;
              //Fetching the Order Item records    
              
              //if the current page is returning an id, extracting the list of orderitems related to the pbeid
               if(pbeid == null){
              pbeid  = ApexPages.currentPage().getParameters().get('id');
              }
              if(pbeid != null){
                    
                    List<OrderItem> orderItems = [SELECT Id,product2.Name FROM OrderItem where Id=:pbeid];
                     
                    orderproductname = orderItems[0].product2.Name;
                    
                    orderprodid = orderItems[0].Id;
              }
                
                Inventoriesselection = [Select Id,ItemNumber__c,ItemType__c,ExternalId,ExpirationDate__c,SerialStatus__c,Org__c,TransactQuantity__c,ReservationQuantity__c,LotStatus__c,Locator__c,LotNumber__c,Description__c,Quantity__c,SerialNumber__c,Subinventory__c from Inventory_Quantity_Onhand__x where ItemNumber__c =: orderproductname];
                soql = 'Select Id,ItemNumber__c,ItemType__c,MasterLot__c,ExternalId,ExpirationDate__c,SerialStatus__c,Org__c,TransactQuantity__c,ReservationQuantity__c,LotStatus__c,Locator__c,LotNumber__c,Description__c,Quantity__c,SerialNumber__c,Subinventory__c from Inventory_Quantity_Onhand__x where ItemNumber__c =: orderproductname';
                runQuery();
                
                //validating if the list has records and then asigning values to the map
                if(Inventories.size()>0)
                {
                   for(Inventory_Quantity_Onhand__x inv:Inventoriesselection)
                   { 
                     Inventoriesmap.put(inv.id,inv);
                   }
                }
                getdisplaysumvalues();
                getTotalInvent();
                
                
             }
             
     public void toggleSort() {
    // simply toggle the direction
    sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
    // run the query again
    runQuery();
   
  }
 /*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  Method to run the actual query.
    Inputs:       
    Returns:      
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/
  public void runQuery() {

    try {
      //validating of it is not a test run
      if (!Test.isRunningTest()){  
      Inventories = Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 25 OFFSET ' +pagination);
      inventCount = Inventories.size();
      
      }
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
       
    }

  }

/*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  Getting the inventory object records by search value
                  from vf page and runs the search with parameters passed
                  via javascript.
    Inputs:       
    Returns:      
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/
  public PageReference runSearch() {
    
    //validatinng if there is a search criteria being passed in the VF page or not
    if(warehouse != '' || lotnumber != '' || serialnumber != ''){
       block = true;
    }else{
       block = false;
    }
    pagination = 0;
   // if(clearpagination == 'true')
        //pagination = 0;
    soql = 'Select Id,ItemNumber__c,ItemType__c,MasterLot__c,ExternalId,ExpirationDate__c,SerialStatus__c,Org__c,TransactQuantity__c,ReservationQuantity__c,LotStatus__c,Locator__c,LotNumber__c,Description__c,Quantity__c,SerialNumber__c,Subinventory__c from Inventory_Quantity_Onhand__x where ItemNumber__c =: orderproductname';
     
      // Validating if warehouse value on the search page is not null
      if (!warehouse.equals(''))
       //block = true;
      soql += ' and Org__c LIKE \''+String.escapeSingleQuotes(warehouse)+'%\'';
      // Validating if lotnumber value on the search page is not null
      if (!LotNumber.equals(''))
      soql += ' and LotNumber__c LIKE \''+String.escapeSingleQuotes(lotnumber)+'%\'';
      // Validating if serialnumber value on the search page is not null
      if (!SerialNumber.equals(''))
      soql += ' and SerialNumber__c LIKE \''+String.escapeSingleQuotes(serialnumber)+'%\'';
    // run the query again
    runQuery();
     
    return null;
  }

/*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  Getting the selected inventory object recordid
                  from vf page and storing that record in the list.
    Inputs:       passing selected inventory record id.
    Returns:      
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/    
Public Pagereference selectinventory()
{
    selectinventory.clear();
    string selinventoryid = System.currentPagereference().getParameters().get('invenid');
   
        //validating if the variable has a value
        if(selinventoryid != null){
                 selectvalue = true;
                 if(Inventoriesmap.containskey(selinventoryid))
                 {
                 selectinventory.add(Inventoriesmap.get(selinventoryid));
                 }
                 
            }
            return null;     
}

/*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  Getting the selected inventory object recordid
                  from vf page and storing that record in the list.
    Inputs:       passing selected inventory record id.
    Returns:      
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/  
     public pagereference inventselect()
    {
        inventselect.clear();
        //selectvalue = false;
        String invenselid = System.currentPagereference().getParameters().get('selectid');
        system.debug('invenselid===='+invenselid);
        
        //validating if the variable has a value
        if(invenselid != null){
                 
                 selectvalue = true;
               
                 
                 if(wrapperClassmap.containskey(invenselid))
                 {
                    inventselect.add(Inventoriesmap.get(invenselid));
                 }
                 system.debug('inventselect===='+inventselect);
                 
            }
           return null;
    }        
/*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  We are updating the warehouse,lot number and serial
                  number of selected inventory record on the order product
                  object by using save button.
    Inputs:       passing selected inventory record id.
    Returns:      
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy        Initial Creation(US-0002725)
    05/22/2017      Krishna Prasad       Implemented exception handling block for update operation(US-0002641)
    06/06/2017      Krishna prasad       Added fields in query(US-0002725)
------------------------------------------------------------*/       
Public Pagereference saveInventory(){
               

            hidewarehousepageblock =false;
            // 06/06/2017      Krishna prasad       Added fields in query(US-0002725)
            //OrderItem orderItm = [SELECT Id,product2.Name,Warehouse__c ,Line_Type__c,Shipping_Instructions__c,Asset__r.name,Asset__c FROM OrderItem where Id =: orderprodid];
            OrderItem orderItm = [SELECT Id,product2.Name,Warehouse__c ,Line_Type__c,Shipping_Instructions__c,SBQQ__Asset__r.name,SBQQ__Asset__c FROM OrderItem where Id =: orderprodid];
            //Validating if the list has values
         
            if(selectinventory.size()>0 ){ 
                
                Id inventid = selectinventory[0].ID;
                //query to fetch inventory form native search
                Inventory_Quantity_Onhand__x inventory = [Select Id,ItemNumber__c,MasterLot__c,Org__c,ExternalId,ItemType__c,Locator__c,LotNumber__c,Description__c,Quantity__c,SerialNumber__c,Subinventory__c from Inventory_Quantity_Onhand__x where Id=:inventid];
                orderItm.Warehouse__c = inventory.Org__c;
                orderItm.Lot_Number__c = inventory.LotNumber__c;
                orderItm.Serial_Number__c = inventory.SerialNumber__c;
                orderItm.Subinventory__c = inventory.Subinventory__c;
            }
            //Validating if the list has values
            system.debug('inventselect===='+inventselect);
            if(inventselect.size()>0){ 
                system.debug('inventselect===='+inventselect);
                //query to fetch inventory form optinal search
                Id selectid = inventselect[0].ID;           
                Inventory_Quantity_Onhand__x inventorysel = [Select Id,ItemNumber__c,MasterLot__c,Org__c,ExternalId,ItemType__c,Locator__c,LotNumber__c,Description__c,Quantity__c,SerialNumber__c,Subinventory__c from Inventory_Quantity_Onhand__x where Id=:selectid];
                orderItm.Warehouse__c = inventorysel.Org__c;
                orderItm.Lot_Number__c = '';
                orderItm.Serial_Number__c = '';
            }
            system.debug('orderItm===='+orderItm);
            //Validating if the query has returned records
            //5/22/2017 Krishna Prasad (US-0002641) implemented exception handling block for update operation
            if(orderItm != null){
            try{
                update orderItm;
                system.debug('orderItm===='+orderItm);
                //06/06/2017      Krishna prasad     Added Order Line itmes to list of wrapper for dispaly  (US-0002725)
                integer count =0;
                for(oli ol:OrItems){

                    if(ol.olItem.id == orderItm.id ) {
                        if(OrItems.size()>0){
                            OrItems.remove(count);
                              break;
                        }
                    }
                  
                    count++;
                }
                oli  addoli = new oli(orderItm);
                OrItems.add(addoli);

            }  catch (Exception e) 
                {
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Order product not Updated ! '+e.getMessage()));
                }
            }
            
            
             if(objName =='OrderItem'){
               PageReference orderPage = new PageReference('/' + orderprodid);
               orderPage.setRedirect(true);
               return orderPage;
             }
    return null;
}
/*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  cancel button will redirect to the current order
                  product page layout.
    Inputs:       
    Returns:      
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/
Public Pagereference cancel(){
    PageReference orderPage = new PageReference('/' + orderprodid);
    orderPage.setRedirect(true);
    return null;
}

//This private list is now only available when running tests in test class.
@TestVisible private static List<Inventory_Quantity_Onhand__x> mockedInventories = new List<Inventory_Quantity_Onhand__x>();    
public static Inventory_Quantity_Onhand__x findById(Id invenid) {
        List<Inventory_Quantity_Onhand__x> inventtest = (!mockedInventories.isEmpty()) ? mockedInventories : [
            SELECT  Id, Description__c, ItemNumber__c
            FROM Inventory_Quantity_Onhand__x
            WHERE Id =: invenid
        ];

        return (inventtest.size() > 0) ? inventtest[0] : null;
    }    
 /*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  This method is created to caluculate sum of warehouse 
                  values.
    Inputs:       
    Returns:      
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/   
    public void getdisplaysumvalues()
    {
        //va;idating if it is not a test run 
      if (!Test.isRunningTest()){
      Inventories = Database.query(soql);
     
      }    
     //validating if the list has values 
    if(Inventories.size()>0)
    {
       Map<String, List<Inventory_Quantity_Onhand__x>> orgwisemap=new Map<String, List<Inventory_Quantity_Onhand__x>>();
    
            for(Inventory_Quantity_Onhand__x IQO:Inventories)
            {
               if(orgwisemap.containskey(IQO.Org__c))
               {
                 List<Inventory_Quantity_Onhand__x> getexistinlist=orgwisemap.get(IQO.Org__c);
                 getexistinlist.add(IQO);
                 orgwisemap.put(IQO.Org__c,getexistinlist);
                 
               }else
               {
                 List<Inventory_Quantity_Onhand__x> newlist=new List<Inventory_Quantity_Onhand__x>();
                 newlist.add(IQO);
                 orgwisemap.put(IQO.Org__c,newlist);
               }
    
            }
    
            List<Inventory_Quantity_Onhand__x> displaylist=new List<Inventory_Quantity_Onhand__x>();
    
            for(string s:orgwisemap.keyset())
            {
              List<Inventory_Quantity_Onhand__x> getexistinlist=orgwisemap.get(s);
              decimal Quantity=0;
              decimal ReservationQuantity=0;
              decimal TransactQuantity=0;
              string itemnumber;
              String itemdescription;
              string org;
              string warehouseid;
              for(Inventory_Quantity_Onhand__x calculatesum:getexistinlist)
              {
                Quantity=Quantity+calculatesum.Quantity__c;
                ReservationQuantity=ReservationQuantity+calculatesum.ReservationQuantity__c;
                TransactQuantity=TransactQuantity+calculatesum.TransactQuantity__c;
                itemnumber=calculatesum.ItemNumber__c;
                itemdescription=calculatesum.Description__c;
                org=calculatesum.Org__c;
                warehouseid=calculatesum.Id;
              }
              wrapperClassController addtolist=new wrapperClassController(itemnumber,itemdescription,Quantity,ReservationQuantity,TransactQuantity,org,warehouseid);
              displaysumvalues.add(addtolist);
              wrapperClassmap.put(addtolist.warehouseid,addtolist);
            }
     }
    }
     /*------------------------------------------------------------
    Author:       Krishna prasad
    Company:      AppsAssociates 
    Description:  Displays order line items.
    Inputs:       
    Returns:      
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    06/06/2017     Krishna prasad       created on enhancement request (US-0002725)
------------------------------------------------------------*/
 

 public class oli {
            
            public OrderItem olItem { get; set; }
            public id olItemid { get; set; }
             public oli(OrderItem oritem) {
                this.olItem = oritem;
                this.olItemid = oritem.id;
        }
    }
    /*------------------------------------------------------------
    Author:       Kasmoor Reddy
    Company:      AppsAssociates 
    Description:  new wrraper class for to get the count quantity on warehouse values.
    Inputs:       
    Returns:      
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/08/2017      Kasmoor Reddy         Initial Creation(US-0002725)
------------------------------------------------------------*/   

    public class wrapperClassController {

        public string itemnumber  {get;set;}
        public string description {set;get;}
        public decimal SumofQuantity  {get;set;}
        public decimal SumofReservedQuantity  {get;set;}
        public decimal SumofTransactQuantity  {get;set;}
        public string org {set;get;}
        public string warehouseid {get;set;}
        //public boolean selected {get;set;}
        
        public wrapperClassController(string itemnumber,string description,decimal SumofQuantity,decimal SumofReservedQuantity,decimal SumofTransactQuantity,string org,string warehouseid)
        {
          this.itemnumber=itemnumber;
          this.description=description;
          this.SumofQuantity=SumofQuantity;
          this.SumofReservedQuantity=SumofReservedQuantity;
          this.SumofTransactQuantity=SumofTransactQuantity;
          this.org=org;
          this.warehouseid=warehouseid;
          //this.selected=false;
        }
        
      }
      
/*------------------------------------------------------------
    Author:     Krishna Prasad
    Company:    Apps Associates
    Description:Page reference method for to update the and adding the order line item  
                                 
    Inputs:      N/A 
    Returns:    PageReference
              
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    4/7/2017    Krishna Prasad    Initial Creation(US-0002725)
---------------------------------------------------------------*/    
            public PageReference UpdateOrderAddOLi() {
                parentOrder.Pricebook2Id = SelectedPricebook ;
                update parentOrder;
                PageReference pageRef = new PageReference('/apex/OrderItemProductSelectorwithwarehouse?id=' +parentOrder.Id);
                pageRef.setRedirect(TRUE);
                return pageRef;     
            }
            
/*------------------------------------------------------------
    Author:     Krishna Prasad
    Company:    Apps Associates
    Description: Page reference method for page redirection  
                     
    Inputs:      N/A 
    Returns:    PageReference
      
    History:
    <Date>      <Authors Name>    <Brief Description of Change>
    4/7/2017    Krishna Prasad     Initial Creation(US-0002725)
------------------------------------------------------------*/
   public PageReference  pageredirect(){
        
        //page redirection
        if(redirect){
         PageReference pageRef = new PageReference('/apex/OrderItemProductSelectorwithwarehouse?id='+parentOrder.Id);
                pageRef.setRedirect(TRUE);
                return pageRef; 
        }else{
        PageReference pageRef = new PageReference('/apex/OrderPriceBookUpdatewithwarehouse?id='+parentOrder.Id);
                pageRef.setRedirect(TRUE);
                 return pageRef; 
        }

    }
             
        }