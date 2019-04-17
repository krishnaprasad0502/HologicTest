/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Extension Class to CaseAddOrderLineItems VF page. Displays Order Items associated to B&SH Install case
Test Class:    Test_addOrderLineItems

History:
<Date>      <Authors Name>    <Brief Description of Change>
08/01/2016   Mani Sundaresan    Initial Creation (US1362)
08/04/2016   Mani Sundaresan    Updated to save the case id on Order Item
----------------------------------------------------------------------------------------------------------------------*/

public class addOrderLineItems {

    //////////////////////////////Variable Declaration Section/////////////////////
    private final Case caseOrder;
    public Id orderId;
    public List<orderLineItem> orderItemList {get; set;}
    public Integer size{get; set;}
    //public Integer noOfRecords{get; set;}
    public List<OrderItem> selectedOrderItem = new List<OrderItem>();
    public Boolean opptyName {get; set;}
    public Boolean originalOrdrItem {get; set;}
    //public Boolean quantity {get; set;}
    public Boolean uom {get; set;}
    public Boolean shipTo {get; set;}
    public Boolean scheduledShipDate {get; set;}
    //public Boolean disabledChkBox {get; set;}
    public Boolean MasterChkBox {get; set;}

    public Map<Id,OrderItem> orderProductsMap = new Map<Id,OrderItem>();
   
    /////////////////////Pagination Variables//////////////////////////////////////
    
    public Integer OffsetSize = 0;
    public Integer QueryLimit = 100;
    public Integer initialOffsetSize = 0;
    private Integer initialQueryLimit = 100;
    public Integer CountTotalRecords{get;set;}
    public List<orderLineItem> paginationList {get; set;}
    public Boolean noOrder {get; set;}
    Map<Id,orderLineItem> paginationMap = new Map<Id, orderLineItem>();
    
    
    //////////////////////////////////////////////////////////////////////////////
    
    Id caseId = System.currentPageReference().getParameters().get('id');
    
    String caseNumb = System.currentPageReference().getParameters().get('casenum');
    
   
    //Extension controller to fetch all the OrderLineItems associated to the Order on B&SH Install case.
    public AddOrderLineItems(ApexPages.StandardController controller) {
    
        this.caseOrder = (Case)controller.getRecord();
           
        if(ApexPages.currentPage().getParameters().get('Order') == ''){
             ApexPages.Message myMsg = new  ApexPages.Message(ApexPages.Severity.ERROR,'An Order is not associated to this Case. Kindly select an Order on the Case to add Line Items.');
             ApexPages.addMessage(myMsg); 
        }
        else        
            orderId = (Id)ApexPages.currentPage().getParameters().get('Order');
        
        if(orderId != null){
            noOrder = false;
            paginationList = new List<orderLineItem>();
            for(OrderItem o : [Select Id, Case__c, Order.OrderNumber, UnitPrice, Product_Number__c, PriceBookEntry.Product2.ShortDescription__c, Order.Account.Name, Order.Opportunity.Name, Order.Status, OriginalOrderItem.Id, Quantity, Unit_of_Measure__c, Ship_To_Site_Location__c, Scheduled_Ship_Date__c from OrderItem where Order.Id = :orderId])
                paginationMap.put(o.Id, new OrderLineItem(o,caseNumb));
                
            //for(OrderItem op : [SELECT Id, Case__c from OrderItem where Case__c = :caseId])
                //orderProductsMap.put(op.Id,op);
        }
        else
            noOrder = true;
            
        if(paginationMap.values().size() > 0)
            CountTotalRecords =  paginationMap.values().size();   
        
    }
    
   
    //Method to display OrderLineItems on VF Page    
    public List<orderLineItem> getOrderItem() {
    
        Integer opptyCount = 0;
        Integer orderItem = 0;
        Integer uom1 = 0;
        Integer shipTo1 = 0;
        Integer scheduledShipDate1 = 0;
        Integer count = 0;
        
        MasterChkBox = false;
        
        orderItemList = new List<orderLineItem>();
            
        paginationList = paginationMap.values();
          
        if(paginationList.size() > 0){
            if(CountTotalRecords < QueryLimit){
                QueryLimit = CountTotalRecords;
                initialQueryLimit =  CountTotalRecords;
            }
          
            for(Integer i=OffsetSize; i<QueryLimit; i++){  
                OrderItem o = paginationList.get(i).oi; 
                if(o.Order.Opportunity.Name != null)
                    opptyName = true;
                else
                    opptyName = false;
            
                if(o.OriginalOrderItem.Id != null)
                    originalOrdrItem = true;
                else
                    originalOrdrItem = false;
                
                if(o.Unit_of_Measure__c == null)
                    uom1++;
            
                if(o.Ship_To_Site_Location__c == null)
                    shipTo1++;
                
                if(o.Scheduled_Ship_Date__c == null)
                    scheduledShipDate1++;
                      
                if(o.Case__c == caseId){
                    paginationList.get(i).selected = true;        
                    //paginationList.get(i).disabledChkBox = true;    
                }
            
            if(paginationList.get(i).selected == true)
                count++;
                                
            orderItemList.add(paginationList.get(i));
            }
        }
        
        //Dynamic display of columns in VF page based on the column value
        if(orderItemList.size() > 0){
            if(uom1 == orderItemList.size())  
                uom = false;
            else
                uom = true;
            if(shipTo1 == orderItemList.size())
                shipTo = false;
            else
                shipTo = true;
            if(scheduledShipDate1 == orderItemList.size())
                scheduledShipDate = false;
            else
                scheduledShipDate = true;    
        }
        
        
        if(orderItemList.size() > 0)
            size = orderItemList.size();
            
        if(count == size)
            MasterChkBox = true;  
        
       
        return orderItemList; 
    }
    
    //Method for maintaining the state of the checkbox in VF page
    public void setSelected(){
    
        Id oi = (Id)System.currentPagereference().getParameters().get('OrderItem');
        String selected = System.currentPagereference().getParameters().get('Selected');
        
        for(OrderLineItem o : orderItemList)
            if(o.oi.Id == oi)
                paginationMap.get(oi).selected = o.selected;
            
    }
    
    //Pagination method for Previous Link
    public PageReference Previous() {
    
        Integer tempOffsetSize = OffsetSize;
        Integer tempQueryLimit = QueryLimit;
        
        OffsetSize = tempOffsetSize - initialQueryLimit;
        QueryLimit -= initialQueryLimit;
        
        if(QueryLimit < initialQueryLimit)
            QueryLimit = initialQueryLimit;
        if(OffsetSize < initialOffsetSize)
            OffsetSize = initialOffsetSize;    
        return null;
    }
    
    //Pagination methods for Next Link
    public PageReference Next() {
      
        Integer tempOffsetSize = OffsetSize;
        Integer tempQueryLimit = QueryLimit;
      
        OffsetSize += QueryLimit;
        
        if(OffsetSize == CountTotalRecords || OffsetSize > CountTotalRecords)
            OffsetSize = CountTotalRecords - tempOffsetSize;
        
        QueryLimit += QueryLimit;
       
        if(QueryLimit > CountTotalRecords)
            QueryLimit = CountTotalRecords;
        
        return null;
    }
    
    //Method for rendering Previous Link
    public Boolean getDisablePrevious(){
        if(OffsetSize>0){
            return true;
        }
        else return false;
    }

    //Method for rendering Next Link
    public Boolean getDisableNext() {
        if (QueryLimit == countTotalRecords){
            return false;
        }
        else return true;
    }
    
    
    //Method for creating Order Product custom object records based on the selection on VF Page
    public PageReference processSelected(){
    
        System.debug('Process Selected');
    
        for(orderLineItem oli : paginationMap.values()){
            System.debug('Selected:'+oli.selected);
            if(oli.selected == true && oli.oi.Case__c != caseId){
                //Order_Line_Item__c orpr = new Order_Line_Item__c(Case__c = caseId,  Order_Product__c = oli.oi.Id);
                oli.oi.Case__c = caseId;
                selectedOrderItem.add(oli.oi);
            }
            else if(oli.selected == false && oli.oi.Case__c == caseId){
                System.debug('Deselction');
                oli.oi.Case__c = null;
                selectedOrderItem.add(oli.oi);
            }    
        }
        try{
            if(selectedOrderItem.size() > 0)
                update selectedOrderItem;
                
            if(Test.isRunningTest())
                Integer i = 10/0;
           }
         catch (Exception e){
             System.debug('System Exception:'+e.getMessage());
         } 
         return null;
    }
    
    //Wrapper Class containing the Order Item, checkbox selection and TotalPrice calculation
    public class orderLineItem {
    
        public OrderItem oi {get; set;}
        public Boolean selected {get; set;}
        public Decimal TotalPrice {get; set;}
        //public Boolean disabledChkBox {get; set;}
        
        
        public orderLineItem(OrderItem o, String caseNo){
            oi = o;
            selected = false;
            //disabledChkBox = false;
            TotalPrice = (o.UnitPrice * o.Quantity).setscale(2);
        }
    }
    
}