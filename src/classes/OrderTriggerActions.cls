/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Order Trigger functions
Test Class:     OrderTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
08/09/2016      Marc Goldstein      Initial Creation (INT21)
11/08/2016      Denise Bacher       Added updateRelatedCase (US-0001169)
26/06/2017      krishna prasad      Update functionality with default price book US-0003028 defect(#304)
26/06/2017      krishna prasad      Update functionality with default price book US-0003028 defect(#304)
07/14/2017      Raj Sharan          Update of Logic to update Address for Internal Orders (US-0003025)  
03/26/2018      Dave Mansell        Added createWorkOrders method (US-0004043)
10/19/2018      Dave Mansell        Refactored code
04/15/2019      Gopichand Katta     Service Orders generated from Service Quotes - fix UnitPrice mapping(US-0007203)
------------------------------------------------------------*/
public with sharing class OrderTriggerActions {
    
    public static void checkToUpdateRelatedCases(List<Order> orders, Map<Id, Order> oldMap){
        Set<Id> recTypeIds = new Set<Id>();
        recTypeIds.add(GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'));
        recTypeIds.add(GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO'));
        
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            if(old.Status == 'Draft' && ord.Status != 'Draft' && ord.Case__c != null && recTypeIds.contains(ord.RecordTypeId)){
                validOrders.add(ord);
            }
        }
        
        if(validOrders.size() > 0){
            updateRelatedCases(validOrders);
        }
    }
    
    public static void updateRelatedCases(List<Order> orders){
        Set<Id> recTypeIds = new Set<Id>();
        recTypeIds.add(GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order'));
        recTypeIds.add(GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO'));
        
        Map<Id, List<Order>> validOrdersByCaseId = new Map<Id, List<Order>>();
        for(Order ord : orders){
            if(ord.Status != 'Draft' && ord.Case__c != null && recTypeIds.contains(ord.RecordTypeId)){
                List<Order> orderList = validOrdersByCaseId.get(ord.Case__c);
                if(orderList == null){
                    orderList = new List<Order>();
                }
                orderList.add(ord);
                validOrdersByCaseId.put(ord.Case__c, orderList);
            }
        }
        
        if(validOrdersByCaseId.isEmpty()){
            return;
        }
        
        List<Case> casesToUpdate = [
            SELECT Id
                  ,(SELECT Id
                      FROM Complaint_Intakes__r //case summaries
                   )
              FROM Case
             WHERE Id IN :validOrdersByCaseId.keySet()
        ];
        List<Case_Summary__c> summariesToUpdate = new List<Case_Summary__c>();
        
        for(Case cas : casesToUpdate){
            cas.SYS_Has_Service_Orders_Not_Draft__c = true;
            for(Case_Summary__c summary : cas.Complaint_Intakes__r){
                summary.Has_Service_Orders__c = true;
                summariesToUpdate.add(summary);
            }
        }
        update summariesToUpdate;
    }
    
    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Automation of creating Order Line Items from Service Order Quick Action from a Quote (SBQQ__Quote__c)
    Inputs:         N/A
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/23/2018      Ryan Lambert        Initial Creation (US-0004449)
    ------------------------------------------------------------*/
    public static void createQuoteServiceOrderLineItems(List<Order> orders){
        //Gather quote IDs
        Set<Id> quoteIDs = new Set<Id>();
        
        List<Order> ordersFullFields = [SELECT Id, SBQQ__Quote__c, CreatedBy.Profile.Name FROM Order WHERE Id IN :orders];
        
        for(Order ord : ordersFullFields){
            // Check for integration user - if found, skip adding quotes so that line items are not added and code jumps out.
            if (ord.CreatedBy.Profile.Name != 'Integration API User') {
                quoteIDs.add(ord.SBQQ__Quote__c);
            }
        }
        
        if(quoteIds.isEmpty()){
            return;
        }                  
                  
        //Query quote lines and map them by their parent Quote ID
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLineListsByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Set<Id> quoteLineProductIDs = new Set<Id>();
        Set<Id> quoteLinePricebookIDs = new Set<Id>();
        for(SBQQ__QuoteLine__c quoteLine : [
            SELECT Id
                  ,SBQQ__Quote__c
                  ,Account__c
                  ,Sales_Rep__c
                  ,Bill_To_Account__c
                  ,Ship_To_Account__c
                  ,BillTo_Site__c
                  ,ShipTo_Site__c
                  ,SBQQ__Product__c
                  ,SBQQ__Quantity__c
                  ,PriceBookId__c
                  ,SBQQ__CustomerPrice__c            
                FROM SBQQ__QuoteLine__c 
             WHERE SBQQ__Quote__c IN :quoteIDs 
               AND SBQQ__Product__c IN (
                        SELECT ID
                          FROM PRODUCT2
                         WHERE Quote_Product_Type__c = 'DISPOSABLE'
                           AND Service_Subscription__c = NULL
                   )
        ]){
            quoteLineProductIDs.add(quoteLine.SBQQ__Product__c);
            quoteLinePricebookIDs.add(quoteLine.PriceBookId__c);
            
            List<SBQQ__QuoteLine__c> quoteLineList = quoteLineListsByQuoteId.get(quoteLine.SBQQ__Quote__c);
            if(quoteLineList == null){
                quoteLineList = new List<SBQQ__QuoteLine__c>();
            }
            quoteLineList.add(quoteLine);
            quoteLineListsByQuoteId.put(quoteLine.SBQQ__Quote__c, quoteLineList);
        }
        
        //Bail if there are no valid records
        if(quoteLineListsByQuoteId.isEmpty()){
            return;
        }
        
        //Query for PBEs and map them by key: Product2Id|Pricebook2Id
        //You'll get some unneeded data in here, but that's okay, it just won't be used
        Map<String, PricebookEntry> pbesByKey = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
            SELECT Id
                  ,Name
                  ,UnitPrice 
                  ,Product2Id
                  ,Pricebook2Id
              FROM PricebookEntry 
             WHERE Product2Id IN :quoteLineProductIDs
               AND Pricebook2Id IN :quoteLinePricebookIDs
        ]){
            // Must trim Pricebook2Id to 15 chars (rather than 18 char) since SBQQ__QuoteLine__c.PriceBookId__c is only 15 chars
            // Map Key must match 100%
            String pbTrim = (String)pbe.Pricebook2Id;            
            String key = pbe.Product2Id + '|' + pbTrim.left(15);
            pbesByKey.put(key, pbe);
        }
        
        //Create OrderItems
        List<OrderItem> ois = new List<OrderItem>();        
        for(Order ord : orders) {
            for(SBQQ__QuoteLine__c quoteLine : quoteLineListsByQuoteId.get(ord.SBQQ__Quote__c)){
                OrderItem oi = new OrderItem();
                oi.OrderId = ord.id;
                oi.Product2Id = quoteLine.SBQQ__Product__c;
                oi.Line_Type__c = 'Shipment';
                oi.Quantity = quoteLine.SBQQ__Quantity__c;
                
                String key = quoteLine.SBQQ__Product__c + '|' + quoteLine.PriceBookId__c;
                PricebookEntry pbe = pbesByKey.get(key);
                if(pbe == null){
                    // This should never happen !
                    ord.addError('Couldn\'t find pricebookentry for product ' + quoteLine.SBQQ__Product__c + ' and pricebook ' + quoteLine.PriceBookId__c);
                } else {
                    oi.PricebookEntryId = pbe.Id;
                    //oi.UnitPrice = pbe.UnitPrice; 
                    //update field oi.UnitPrice from quote line field  SBQQ__CustomerPrice__c(US-0007203-GK)
                      oi.UnitPrice =quoteLine.SBQQ__CustomerPrice__c;
                      ois.add(oi);             
                }
                System.debug('Order:'+oi.OrderId);
                System.debug('Product:'+oi.Product2Id);
                System.debug('Pricebook:'+oi.PricebookEntryId);
            }
        }        
        insert ois;        
    }
    
    /*------------------------------------------------------------
    Author:         Dave Mansell
    Company:        Salesforce.com
    Description:    Updates Assets upon insert or update of Order in certain statuses
    Inputs:         List of Order records, map of old Order records
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/30/2018      Dave Mansell        Initial Creation (US-0004653)
    ------------------------------------------------------------*/
    public static void updateRelatedAssets(List<Order> orders, Map<Id, Order> oldMap){
        //After update
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            if(
                (old.Status != 'ENTERED' && ord.Status == 'ENTERED') ||
                (old.Status != 'ENTERED' && old.Status != 'BOOKED' && ord.Status == 'BOOKED')
            ){
                validOrders.add(ord);
            }
        }
        if(validOrders.size() > 0){
            List<Asset> parentAssets = [
                SELECT Id
                  FROM Asset
                 WHERE Id IN (
                    SELECT Returned_Asset__c
                      FROM OrderItem
                     WHERE OrderId IN :validOrders
                       AND Returned_Asset__c != null
                       AND Line_Type__c = 'RMA'
                       AND Order.RecordType.DeveloperName = 'B_SH_Service_Order'
                       AND Product2.Product_Source_Division__r.Name = '700'
                       AND (Order.Status = 'ENTERED' OR Order.Status = 'BOOKED')
                 )
            ];
            
            for(Asset asst : parentAssets){
                asst.Status = 'PENDING RETURN';
            }
            
            update parentAssets;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Dave Mansell & Rob Strickler
    Company:        Salesforce.com
    Description:    Automation of creating Work Orders for 'BOOKED' Orders
    Inputs:         Orders - status updated to 'BOOKED', record type updated to 'Sales Order RO'
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/21/2018      Rob Strickler       Initial Creation (US-0004043)
    03/26/2018      Dave Mansell        Initial Creation (US-0004043)
    ------------------------------------------------------------*/
    public static void createWorkOrders(List<Order> orders, Map<Id, Order> oldMap){
        Id salesOrderRTId       = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        Id serviceOrderRORTId   = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO');
        
        //Check for proper status, record type, and Install_Case_Required__c values
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            
            Boolean isValidSalesOrder = (
                ord.RecordTypeId == salesOrderRTId
                && (ord.Status == 'BOOKED' && old.Status != 'BOOKED')
            );
            Boolean isValidAdvancedExchangeOrder = (
                ord.RecordTypeId == serviceOrderRORTId
                && (ord.Status == 'BOOKED' && old.Status != 'BOOKED')
                && ord.Type == 'Advanced Exchange'
            );
            if(isValidSalesOrder == true || isValidAdvancedExchangeOrder == true){
                validOrders.add(ord);
            }
        }
        if(!validOrders.isEmpty()){
            WorkOrderCreationHelper.createWorkOrdersAndWOLIs(validOrders, null);
        }
    }
    
    public static void checkToSetSunshineCompliantOnAccount(List<Order> orders, Map<Id, Order> oldMap){
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            if(ord.AccountId != null && ord.isSunshineCompliant__c != old.isSunshineCompliant__c){
                validOrders.add(ord);
            }
        }
        
        if(validOrders.size() > 0){
            setSunshineCompliantOnAccount(validOrders);
        }
    }
    
    public static void setSunshineCompliantOnAccount(List<Order> orders){
        Map<Id, Account> accsById = new Map<Id, Account>();
        for(Order ord : orders){
            if(ord.AccountId != null && ord.AccountId != Configuration_Settings__c.getInstance().Default_Internal_Account__c){
                accsById.put(ord.AccountId, null);
            }
        }
        
        if(accsById.size() > 0){
            accsById = new Map<Id, Account>([
                SELECT Id
                      ,(SELECT Id
                          FROM Orders
                         WHERE isSunshineCompliant__c = true
                       )
                  FROM Account
                 WHERE Id IN :accsById.keySet()
            ]);
            
            for(Account acc : accsById.values()){
                if(acc.Orders.size() > 0){
                    acc.isSunshineCompliant__c = true;
                } else {
                    acc.isSunshineCompliant__c = false;
                }
            }
            
            update accsById.values();
        }
    }
    
}
    
/*
    private static final Id PART_RECORD_TYPE = GlobalUtility.getRecordTypeId('Order', 'B_SH_Parts_Order');
    private static final Id SERVICE_RECORD_TYPE = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order');
    private static final Id SERVICE_RO_RECORD_TYPE = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO');
    private static final Id SALES_ORDER_RECORD_TYPE = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
    private static Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
    // Update of Logic to update Address for Internal Orders (US-0003025)  
    private static final Id INTERNAL_RECORD_TYPE = GlobalUtility.getRecordTypeId('Order', 'Internal_Order');
    // End of Update of Logic to update Address for Internal Orders (US-0003025)  

  //Static variable to prevent recursion in before update
    static Boolean setAddressAndUserFieldsFlag = FALSE;
    static Boolean updateRelatedCaseFlag = FALSE;
    
    /*------------------------------------------------------------
    Author:         Dave Mansell
    Company:        Salesforce.com
    Description:    Updates Assets upon insert or update of Order in certain statuses
    Inputs:         List of Order records, map of old Order records
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/30/2018      Dave Mansell        Initial Creation (US-0004653)
    ------------------------------------------------------------*
    public static void updateRelatedAssets(List<Order> orders, Map<Id, Order> oldMap){
        //After update
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            if(
                (old.Status != 'ENTERED' && ord.Status == 'ENTERED') ||
                (old.Status != 'ENTERED' && old.Status != 'BOOKED' && ord.Status == 'BOOKED')
            ){
                validOrders.add(ord);
            }
        }
        if(validOrders.size() > 0){
            List<Asset> parentAssets = [
                SELECT Id
                  FROM Asset
                 WHERE Id IN (
                    SELECT Returned_Asset__c
                      FROM OrderItem
                     WHERE OrderId IN :validOrders
                       AND Returned_Asset__c != null
                       AND Line_Type__c = 'RMA'
                       AND Order.RecordType.DeveloperName = 'B_SH_Service_Order'
                       AND Product2.Product_Source_Division__r.Name = '700'
                       AND (Order.Status = 'ENTERED' OR Order.Status = 'BOOKED')
                 )
            ];
            
            for(Asset asst : parentAssets){
                asst.Status = 'PENDING RETURN';
            }
            
            update parentAssets;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Dave Mansell & Rob Strickler
    Company:        Salesforce.com
    Description:    Automation of creating Work Orders for 'BOOKED' Orders
    Inputs:         Orders - status updated to 'BOOKED', record type updated to 'Sales Order RO'
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/21/2018      Rob Strickler       Initial Creation (US-0004043)
    03/26/2018      Dave Mansell        Initial Creation (US-0004043)
    ------------------------------------------------------------*
    public static void createWorkOrders(List<Order> orders, Map<Id, Order> oldMap){
        Id salesOrderRTId       = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        Id serviceOrderRORTId   = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO');
        
        //Check for proper status, record type, and Install_Case_Required__c values
        List<Order> validOrders = new List<Order>();
        for(Order ord : orders){
            Order old = oldMap.get(ord.Id);
            
            Boolean isValidSalesOrder = (
                ord.RecordTypeId == salesOrderRTId
                && (ord.Status == 'BOOKED' && old.Status != 'BOOKED')
            );
            Boolean isValidAdvancedExchangeOrder = (
                ord.RecordTypeId == serviceOrderRORTId
                && (ord.Status == 'BOOKED' && old.Status != 'BOOKED')
                && ord.Type == 'Advanced Exchange'
            );
            if(isValidSalesOrder == true || isValidAdvancedExchangeOrder == true){
                validOrders.add(ord);
            }
        }
        if(!validOrders.isEmpty()){
            WorkOrderCreationHelper.createWorkOrdersAndWOLIs(validOrders, null);
        }
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Update the related Case.SYS_Has_Service_Orders_Not_Draft__c to true if the RT is Service and the Status is no longer Draft
                    Runs after insert, after update
    Inputs:         Orders - The list of Orders to modify
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    11/08/2016      Denise Bacher       Initial Creation (US-0001169)
    ------------------------------------------------------------*
    public static void updateRelatedCase(List<Order> orders, Map<Id, Order> oldOrders){

        Set<Id> caseIds = new Set<Id>(); // case IDs that need to be udpated
        Map<Id, List<Order>> caseToOrders = new Map<Id, List<Order>>();
        List<Case> casesToUpdate = new List<Case>();

       // if(!updateRelatedCaseFlag){
        
        for(Order o : orders){
            Order oldOrder = oldOrders != null && oldOrders.containsKey(o.Id) ? oldOrders.get(o.Id) : null;
            String orderStatus = String.isNotBlank(o.Status) ? o.Status : '';
            String oldOrderStatus = oldOrder != null && String.isNotBlank(oldOrder.Status) ? oldOrder.Status : '';
            
            // current status is not 'DRAFT', old status is 'DRAFT' and Record type is Service or Service Read Only
            if(!orderStatus.equalsIgnoreCase('DRAFT')
                && (oldOrder == null || (orderStatus != oldOrderStatus && oldOrderStatus.equalsIgnoreCase('DRAFT')) )
                && (o.RecordTypeId == SERVICE_RECORD_TYPE || o.RecordTypeId == SERVICE_RO_RECORD_TYPE)
            ){
                if(o.Case__c != null){
                    caseIds.add(o.Case__c);
                    
                    if(!caseToOrders.containsKey(o.Case__c)){
                        caseToOrders.put(o.Case__c, new List<Order>());
                    }
                    caseToOrders.get(o.Case__c).add(o);
                }
            }
        }
        
        // for the orders found, set the related Case.SYS_Has_Service_Orders_Not_Draft__c to true
        for(Id cId : caseIds){
            casesToUpdate.add(new Case(Id = cId, SYS_Has_Service_Orders_Not_Draft__c = true));
        }
        
        if(casesToUpdate.size() > 0){
            // Update the cases
            System.debug('Update cases: '+Json.serialize(casesToUpdate));
            Database.SaveResult[] srList = Database.update(casesToUpdate, false);
            for(Integer i = 0; i < srList.size(); i++){
                Database.SaveResult sr = srList[i];
                Case currCase = casesToUpdate[i];
                
                // if there are any errors updating the case, pass the error up to the correct orders
                if(!sr.isSuccess()){
                    // compile errors
                    String errors = 'Unable to update related Case. ';
                    for(Database.Error err : sr.getErrors()){
                        errors += err.getMessage() + ' ';
                    }
                    
                    for(Order o : caseToOrders.get(currCase.Id)){
                        o.addError(errors);
                    }
                }
            }
        }

      updateRelatedCaseFlag = TRUE;
      
      //Update case summaries to add note
      if(caseIds.size() > 0){
            List<Case_Summary__c> summaries = [
                SELECT Id
                  FROM Case_Summary__c
                 WHERE Case__c IN :casesToUpdate
                   AND Has_Emails__c = false
            ];
            for(Case_Summary__c summary : summaries){
                summary.Has_Service_Orders__c = true;
            }
            update summaries;
        }

     // }
    }
    
    /*------------------------------------------------------------
    Author:         Ryan Lambert
    Company:        Salesforce.com
    Description:    Automation of creating Order Line Items from Service Order Quick Action from a Quote (SBQQ__Quote__c)
    Inputs:         N/A
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/23/2018      Ryan Lambert        Initial Creation (US-0004449)
    ------------------------------------------------------------*
    public static void createQuoteServiceOrderLineItems(List<Order> orders){
        //Gather quote IDs
        Set<Id> quoteIDs = new Set<Id>();
        
        List<Order> ordersFullFields = [SELECT Id, SBQQ__Quote__c, CreatedBy.Profile.Name FROM Order WHERE Id IN :orders];
        
        for(Order ord : ordersFullFields){
            // Check for integration user - if found, skip adding quotes so that line items are not added and code jumps out.
            if (ord.CreatedBy.Profile.Name != 'Integration API User') {
                quoteIDs.add(ord.SBQQ__Quote__c);
            }
        }
        
        if(quoteIds.isEmpty()){
            return;
        }                  
                  
        //Query quote lines and map them by their parent Quote ID
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLineListsByQuoteId = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Set<Id> quoteLineProductIDs = new Set<Id>();
        Set<Id> quoteLinePricebookIDs = new Set<Id>();
        for(SBQQ__QuoteLine__c quoteLine : [
            SELECT Id
                  ,SBQQ__Quote__c
                  ,Account__c
                  ,Sales_Rep__c
                  ,Bill_To_Account__c
                  ,Ship_To_Account__c
                  ,BillTo_Site__c
                  ,ShipTo_Site__c
                  ,SBQQ__Product__c
                  ,SBQQ__Quantity__c
                  ,PriceBookId__c            
              FROM SBQQ__QuoteLine__c 
             WHERE SBQQ__Quote__c IN :quoteIDs 
               AND SBQQ__Product__c IN (
                        SELECT ID
                          FROM PRODUCT2
                         WHERE Quote_Product_Type__c = 'DISPOSABLE'
                           AND Service_Subscription__c = NULL
                   )
        ]){
            quoteLineProductIDs.add(quoteLine.SBQQ__Product__c);
            quoteLinePricebookIDs.add(quoteLine.PriceBookId__c);
            
            List<SBQQ__QuoteLine__c> quoteLineList = quoteLineListsByQuoteId.get(quoteLine.SBQQ__Quote__c);
            if(quoteLineList == null){
                quoteLineList = new List<SBQQ__QuoteLine__c>();
            }
            quoteLineList.add(quoteLine);
            quoteLineListsByQuoteId.put(quoteLine.SBQQ__Quote__c, quoteLineList);
        }
        
        //Bail if there are no valid records
        if(quoteLineListsByQuoteId.isEmpty()){
            return;
        }
        
        //Query for PBEs and map them by key: Product2Id|Pricebook2Id
        //You'll get some unneeded data in here, but that's okay, it just won't be used
        Map<String, PricebookEntry> pbesByKey = new Map<String, PricebookEntry>();
        for(PricebookEntry pbe : [
            SELECT Id
                  ,Name
                  ,UnitPrice 
                  ,Product2Id
                  ,Pricebook2Id
              FROM PricebookEntry 
             WHERE Product2Id IN :quoteLineProductIDs
               AND Pricebook2Id IN :quoteLinePricebookIDs
        ]){
            // Must trim Pricebook2Id to 15 chars (rather than 18 char) since SBQQ__QuoteLine__c.PriceBookId__c is only 15 chars
            // Map Key must match 100%
            String pbTrim = (String)pbe.Pricebook2Id;            
            String key = pbe.Product2Id + '|' + pbTrim.left(15);
            pbesByKey.put(key, pbe);
        }
        
        //Create OrderItems
        List<OrderItem> ois = new List<OrderItem>();        
        for(Order ord : orders) {
            for(SBQQ__QuoteLine__c quoteLine : quoteLineListsByQuoteId.get(ord.SBQQ__Quote__c)){
                OrderItem oi = new OrderItem();
                oi.OrderId = ord.id;
                oi.Product2Id = quoteLine.SBQQ__Product__c;
                oi.Line_Type__c = 'Shipment';
                oi.Quantity = quoteLine.SBQQ__Quantity__c;
                
                String key = quoteLine.SBQQ__Product__c + '|' + quoteLine.PriceBookId__c;
                PricebookEntry pbe = pbesByKey.get(key);
                if(pbe == null){
                    // This should never happen !
                    ord.addError('Couldn\'t find pricebookentry for product ' + quoteLine.SBQQ__Product__c + ' and pricebook ' + quoteLine.PriceBookId__c);
                } else {
                    oi.PricebookEntryId = pbe.Id;
                    oi.UnitPrice = pbe.UnitPrice;                   
                    ois.add(oi);             
                }
                System.debug('Order:'+oi.OrderId);
                System.debug('Product:'+oi.Product2Id);
                System.debug('Pricebook:'+oi.PricebookEntryId);
            }
        }        
        insert ois;        
    }
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Check if the related Account is Sunshine compliant
        
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/12/2018      Mani Sundaresan     Initial Creation (US-0003812)
    ------------------------------------------------------------*
    public static void setSunshineCompliantOnAccount(List<Order> orderList, Map<Id, Order> oldOrders){
    
        List<Id> accIdList = new List<Id>();
        List<Account> accList = new List<Account>();
        
        for(Order ord : orderList){
            Order oldValue = oldOrders != null && oldOrders.containsKey(ord.Id) ? oldOrders.get(ord.Id) : null;
            if(ord.isSunshineCompliant__c != oldValue.isSunshineCompliant__c)
                accIdList.add(ord.AccountId);
        }
        
        System.debug('accIdList:'+accIdList);
        
        if(accIdList.size() > 0)
            accList = [SELECT Id, isSunshineCompliant__c, (SELECT Id, isSunshineCompliant__c from Orders where isSunshineCompliant__c = true) from Account where Id IN :accIdList];
            
        if(accList.size() > 0)
            for(Account acc : accList){
                if(acc.getSObjects('Orders') != null)
                    acc.isSunshineCompliant__c = true;
                else
                    acc.isSunshineCompliant__c = false;
            }
        
        if(accList.size() > 0)
            update accList;
        
    }
}*/