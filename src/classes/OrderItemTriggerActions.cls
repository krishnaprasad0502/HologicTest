/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the OrderItem object
Test Class:     OrderItemTrigger_Test
                

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/22/2016      Denise Bacher       Initial Creation (US1387)
08/09/2016      Denise Bacher       Added preventDML (US1448)
05/05/2017      Raj Sharan          Updated for Product Replacement based on Replacement Version (US-0002638)
07/11/2017      John Christy        Added if record type of 'Internal' set pricing = 0 (US-0003025)
07/14/2017      Raj Sharan          Update of Logic to correctly determine if Case Asset is Hologic or Customer Owned (US-0003109)  
08/10/2017      Raj Sharan          Update of Logic to calculate Unit Price only based on Entitlement Price  (US-0003109)  
------------------------------------------------------------*/
public with sharing class OrderItemTriggerActions {

  private static Map<Id, WorkOrderLineItem> workOrderLinesInfoMap = new Map<Id, WorkOrderLineItem>();

    /*@TestVisible private static Profile userProfile{
        get{
            if(userProfile == null){
                userProfile = [Select Id, Name From Profile Where Id =: UserInfo.getProfileId()];
            }
            return userProfile;
        }
        set;
    }*/
        
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Set the Entitlement and Unit Price on OrderItem 
                    Runs before insert
    Inputs:         orderItems - The list of OrderItem to modify
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/19/2016      Denise Bacher       Initial Creation (US158)
    08/10/2016      Denise Bacher       Update to set Unit Price to 0 if asset is owned by Hologic (US1436)
    11/21/2016      Mani Sundaresan     Update to the logic to calculate Unit Price and Entitlements (HD-1988)
    07/14/2017      Raj Sharan          Update of Query to include retrievinging the Ownership Field Value from the Case Asset. (US-0003109)  
    ------------------------------------------------------------*/
    public static void setEntitlementAndUnitPrice(List<OrderItem> orderItems){
        Set<Id> workOrderLineIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> rootAssetIds = new Set<Id>();
        Date minDate = System.today();
        Date maxDate = System.today();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<OrderItem> hologicOwnedOrderItems = new List<OrderItem>();
        
        for(OrderItem oi : orderItems){
            System.debug('Oi Case#:'+oi.Order.Case__c);
            orderIds.add(oi.OrderId);
            System.debug('orderIds:'+orderIds);
            if(oi.Work_Order_Line_Item__c != NULL &&  !workOrderLinesInfoMap.containsKey(oi.Work_Order_Line_Item__c)) workOrderLineIds.add(oi.Work_Order_Line_Item__c);
        }
        
        System.debug('woLineItems:'+workOrderLineIds);
        
        if(workOrderLineIds != NULL){
            workOrderLinesInfoMap.putAll(new Map<Id, WorkOrderLineItem>([
                Select Id, Labor_Travel_Type__c
                From WorkOrderLineItem
                Where Id IN: workOrderLineIds
            ]));
        }
 
        //Grabs oracle party sites from custom setting that are internal accounts
        Map<String, InternalAccounts__c> mapInternalAccounts = InternalAccounts__c.getall();
       

        // Update of Query to include retrievinging the Ownership Field Value from the Case Asset. (US-0003109)  
        Map<Id, Order> orderInfoMap = new Map<Id, Order>([
            Select Id, Type, RecordTypeId, CreatedDate, Case__c, Case__r.Asset.Owner_Account__r.Internal__c, Case__r.Asset.RootAssetId, 
            Case__r.CreatedDate
            From Order
            Where Id IN: orderIds
        ]); 
        
        
        // determine which OrderItem need updating
        for(OrderItem oi : orderItems){
            Order parentOrder = orderInfoMap.containsKey(oi.OrderId) ? orderInfoMap.get(oi.OrderId) : null;
           
            // Removed logic to exclude Hologic Owned. (US-0003109)  
            if(Test.isRunningTest()){
                if(parentOrder != null && (parentOrder.RecordTypeId == GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order') && oi.Work_Order_Line_Item__c == NULL))

            // End of Update to address Ownership of Case Asset to determine if Customer Owned. (US-0003109)  
                 
            {
            
                orderItemsToUpdate.add(oi);
                
                if(parentOrder.Case__r.Asset.RootAssetId != null){
                    rootAssetIds.add(parentOrder.Case__r.Asset.RootAssetId);
                }
                
                if(String.isNotBlank(oi.Product2_Id__c)){
                    productIds.add(oi.Product2_Id__c);
                }
                
                Date createdDate = parentOrder.Case__r.CreatedDate != null ? parentOrder.Case__r.CreatedDate.date() : parentOrder.CreatedDate.date();
                minDate = minDate > createdDate ? createdDate : minDate;
                maxDate = maxDate < createdDate ? createdDate : maxDate; 
                
             }
            }

            if(parentOrder != null && (parentOrder.RecordTypeId == GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order') 
               && oi.Work_Order_Line_Item__c == NULL && parentOrder.Case__c != NULL))
            {
                orderItemsToUpdate.add(oi);
                
                if(parentOrder.Case__r.Asset.RootAssetId != null){
                    rootAssetIds.add(parentOrder.Case__r.Asset.RootAssetId);
                }
                
                if(String.isNotBlank(oi.Product2_Id__c)){
                    productIds.add(oi.Product2_Id__c);
                }
                
                Date createdDate = parentOrder.Case__r.CreatedDate != null ? parentOrder.Case__r.CreatedDate.date() : parentOrder.CreatedDate.date();
                minDate = minDate > createdDate ? createdDate : minDate;
                maxDate = maxDate < createdDate ? createdDate : maxDate;    
            }
            // (John Christy) - Condition based on record type related to 'Internal Order' 
            else if(GlobalUtility.getRecordTypeDeveloperName('Order', parentOrder.RecordTypeId).contains('Internal')){
                        hologicOwnedOrderItems.add(oi);
            }
            // (John Christy US-0003025) - end of change
        }
        
        
        // query for the coverage group products from the products on the OrderItems
        Set<Id> coverageGroupIds = new Set<Id>();
        Map<Id, Set<Id>> productIdToCoverageGroupId = new Map<Id, Set<Id>>();
        EntitlementDiscountHelper.queryCoverageGroupProduct(productIds, coverageGroupIds, productIdToCoverageGroupId);
        
        // query for entitlements
        Map<Id, Map<Id, List<Entitlement>>> coverageGroupIdToRootAssetIdToEntitlements = new Map<Id, Map<Id, List<Entitlement>>>(); 
        EntitlementDiscountHelper.queryDiscountEntitlements(coverageGroupIds, rootAssetIds, minDate, maxDate, coverageGroupIdToRootAssetIdToEntitlements);
        
        // go through the order items 
        for(OrderItem oi : orderItemsToUpdate){
            Order parentOrder = orderInfoMap.containsKey(oi.OrderId) ? orderInfoMap.get(oi.OrderId) : null;
            Id rootAssetId = parentOrder != null ? parentOrder.Case__r.Asset.RootAssetId : null;
            Id productId = oi.Product2_Id__c;
            Set<Id> oiCoverageGroups = productIdToCoverageGroupId.containsKey(productId) ? productIdToCoverageGroupId.get(productId) : new Set<Id>();
            List<Entitlement> currentEntitlements = new List<Entitlement>();
            
            // pull all the entitlement that may apply to this order item
            for(Id cgId : oiCoverageGroups){
                if(coverageGroupIdToRootAssetIdToEntitlements.containsKey(cgId) && coverageGroupIdToRootAssetIdToEntitlements.get(cgId).containsKey(rootAssetId)){
                    currentEntitlements.addAll(coverageGroupIdToRootAssetIdToEntitlements.get(cgId).get(rootAssetId));
                }
            }
            
            
            // from the applicable entitlements, determine which offers the best discount
            Entitlement entitlement = EntitlementDiscountHelper.determineDiscountEntitlement(currentEntitlements, oi.List_Price__c, parentOrder.Case__r.CreatedDate != null ? parentOrder.Case__r.CreatedDate.date() : parentOrder.CreatedDate.date());
            oi.Entitlement__c = entitlement.Id;
            if(entitlement.Discount__c > 0){
                oi.UnitPrice = oi.List_Price__c * (1 - (entitlement.Discount__c/100));
                oi.Net_Price__c = oi.UnitPrice;
            } 
            else if(entitlement.Max_Covered_Amount__c > 0){
                oi.UnitPrice = oi.List_Price__c - entitlement.Max_Covered_Amount__c;
                oi.Net_Price__c = oi.UnitPrice;
            }
        }
        
        // go through the hologic owned items and set the unit price to 0
        for(OrderItem oi : hologicOwnedOrderItems){

          if(oi.Work_Order_Line_Item__c == NULL || ( oi.Work_Order_Line_Item__c != NULL  && workOrderLinesInfoMap.get(oi.Work_Order_Line_Item__c).Labor_Travel_Type__c != 'Move')){ 
            oi.UnitPrice = 0;
            oi.Net_Price__c = 0;
         
         }
        }
    }

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Prevent DML on OrderItems belonging to Orders of specific Record Types by all Users except Integration Users
                    Runs before insert, before update, before delete
    Inputs:         orderItems - The list of OrderItem to modify
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/09/2016      Denise Bacher       Initial Creation (US1448)
    05/05/2017      Raj Sharan          Update of Record Type (US-0002899)
    04/11/2018      Ronald Mendoza      Replaced Asset__c with SBQQ__Asset__c reference due to duplicate issue (US-0003947)
    ------------------------------------------------------------*/
    /*public static void preventDML(List<OrderItem> orderItems, Map<Id, OrderItem> oldOrderItems){
        // 05/05/2017      Raj Sharan          Update of Record Type (US-0002899)
        String orderRTSalesOrder = GlobalUtility.getRecordTypeId('Order', 'Sales_Order');
        // End of Change for (US-0002899)
        String orderRTServiceOrderRO = GlobalUtility.getRecordTypeId('Order', 'B_SH_Service_Order_RO');
        String orderRTPartsOrderRO = GlobalUtility.getRecordTypeId('Order', 'B_SH_Parts_Order_RO');
        
        for(OrderItem oi : orderItems){
            OrderItem oldValue = oldOrderItems != null && oldOrderItems.containsKey(oi.Id) ? oldOrderItems.get(oi.Id) : null;
            
            if(userProfile.Name != 'Integration API User'  
                && !(oldValue != null && oldValue.Case__c != oi.Case__c)
                && !(oldValue != null && oldValue.SBQQ__Asset__c != oi.SBQQ__Asset__c)
                && (orderRTSalesOrder.contains(oi.Order_Record_Type_Id__c) 
                    || orderRTServiceOrderRO.contains(oi.Order_Record_Type_Id__c)
                    || orderRTPartsOrderRO.contains(oi.Order_Record_Type_Id__c))
            ){
                //oi.addError('You cannot perform this action due to the parent Order\'s Record Type');
            }
        }
    }*/

    /*------------------------------------------------------------
    Author:         Raj Sharan
    Company:        AppsAssociates 
    Description:    Assess whether the PriceBookEntry should be altered 
    Inputs:         List of OrderItems being updated
                    Map of Old OrderItems 
    Returns:        N/A
    Test Class:     OrderItemTriggerActions_Test 

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/05/2017      Raj Sharan          Updated for Product Replacement based on Replacement Version (US-0002638)
    ------------------------------------------------------------*/
    public static void reviewOrderItems(List<OrderItem> allOrderItems, Map<Id, OrderItem> oldOrderItems){

        List<Id> priceBookEntryListId = new List<Id>();
        List<OrderItem> orderLinesToEvaluate = new List<OrderItem>();
        List<Id> priceBookLists = new List<Id>();

        // Detrmine the Order Lines are of type Shipment.  These may have a product replacement value to evaluate
 
        if(allOrderItems.size() > 0){

          for(OrderItem ol1: allOrderItems){

          // Logic for Line Type of Shipment Only to be evaluated.  
  
            if(ol1.PriceBookEntryId != null && ol1.Line_Type__c == 'Shipment') { 
    
            priceBookEntryListId.add(ol1.PricebookEntryId);
            orderLinesToEvaluate.add(ol1);
            priceBookLists.add(ol1.Order_Price_Book__c); 
          
            }

          }

        }
    
       // Call method to determine if replacement part is required. Only after determining if all lists are greater than zero.
   
       if(orderLinesToEvaluate != NULL && priceBookEntryListId != NULL && priceBookLists != NULL) 
       OrderItemTriggerActions.updatePriceBookEntry(orderLinesToEvaluate, priceBookEntryListId, priceBookLists); 

   }

    /*------------------------------------------------------------
    Author:         Raj Sharan
    Company:        AppsAssociates 
    Description:    Determine if the Product of the PriceBookEntry has a Replacement Part value.
                    If so then update the PriceBookEntry for the OrderLine to the Replacement Product's corresponding PriceBookEntry. 
    Inputs:         List of OrderItems of type Shipment
                    List of Pricebookentry values of Shipment Lines 
                    List of Pricebooks for Shipment
    Returns:        N/A
    Test Class:     OrderItemTriggerActions_Test 

    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/05/2017      Raj Sharan          Updated for Product Replacement based on Replacement Version (US-0002638)
    ------------------------------------------------------------*/
    public static void updatePriceBookEntry(List<OrderItem> newOrderItems, List<Id> priceBookEntryListId, List<Id> priceBookLists){

        List<Id> newProductIdList = new List<Id>();
        List<Product2> productVersionProducts = new List<Product2>();
        List<PricebookEntry> listNewPriceBookEntry = new List<PricebookEntry>();
        Map<Id,Id> replacementMapPriceBookEntry = new Map<Id,Id>();
        Map<Id,Id> oldNewProductVersion = new Map<Id,Id>();
        Id replacementPart;

        // Retrieve Product Information based on PriceBookEntry values passed to the method.  
          if(newOrderItems.size() > 0 && priceBookEntryListId.size() > 0 && priceBookLists.size() > 0){

          productVersionProducts = [Select Id, Name, Replacement_Part__c FROM Product2 
          WHERE Id IN (Select Product2Id FROM PriceBookEntry WHERE Id IN :priceBookEntryListId)];
 
         }

         if(productVersionProducts.size() > 0) {

           for(Product2 pv1:productVersionProducts){

             // If Product has a replacement part add to List.  

             if(pv1.Replacement_Part__c != NULL)  {
 
             // Add to Replacement Part to NewProductList  
             newProductIdList.add(pv1.Replacement_Part__c);

               if(oldNewProductVersion.isEmpty() || !(oldNewProductVersion.containsKey(pv1.Id)))
               oldNewProductVersion.put(pv1.Id,pv1.Replacement_Part__c);

             }

           }

         }

        // Query for Replacement Part Pricebook entry values

         if(newProductIdList.size() > 0) {

          listNewPriceBookEntry = [Select Id, CurrencyIsoCode, IsActive, Name, Pricebook2Id, Product2Id, ProductCode, SystemModstamp, UnitPrice, UseStandardPrice 
          FROM PricebookEntry WHERE Product2Id IN:newProductIdList AND Pricebook2Id IN :priceBookLists];
 
         }

        // Create a Map of the List of Replacement Parts

        if(listNewPriceBookEntry.size() > 0){
 
          for(PriceBookEntry pbe1:listNewPriceBookEntry){
 
            replacementMapPriceBookEntry.put(pbe1.Product2Id, pbe1.Id);
 
          }

        }

       // Logic to loop through lines to detrmine if product should be replaced by later version. If so update PricebookEntry 

       if(newOrderItems.size() > 0 &&  !(oldNewProductVersion.isEmpty()) && !(replacementMapPriceBookEntry.isEmpty()) ){

         for(OrderItem or2:newOrderItems){

           if(oldNewProductVersion.containsKey(or2.Product2_Id__c)){

            // set variable of the Replacment Part 

            replacementPart =  oldNewProductVersion.get(or2.Product2_Id__c);

            // if replacement Part is not null then needs to update new PricebookEntry based on replacement part
            if(replacementPart != NULL) or2.PriceBookEntryId = replacementMapPriceBookEntry.get(replacementPart);

            replacementPart = NULL;

            }

          } 

       }
    }

    /*------------------------------------------------------------
    Author:         Dave Mansell
    Company:        Salesforce.com
    Description:    Check if OrderItem records are being inserted against a BOOKED Order. If so, create WOs and WOLIs
    Inputs:         ois - list of new WorkOrder records
    Returns:        N/A
    
    History:
    <Date>          <Author's Name>     <Brief Description of Change>
    04/02/2018      Dave Mansell        Initial Creation (US-0004043)
    ------------------------------------------------------------*/
    public static void checkToCreateWorkOrders(List<OrderItem> ois){
        WorkOrderCreationHelper.createWorkOrdersAndWOLIs(null, ois);
    }
    
    
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Check if the related Account is Sunshine compliant
    
    
    History:
    <Date>          <Author's Name>     <Brief Description of Change>
    07/12/2018      Mani Sundaresan     Initial Creation (US-0003812)
    ------------------------------------------------------------*/
    public static void setSunshineCompliantOnAccount(List<OrderItem> orderItems, Map<Id, OrderItem> oldOrderItems){
        
        List<Id> accIdList = new List<Id>();
        List<Id> orderIdList = new List<Id>();
        List<Order> updateOrderList = new List<Order>();
        
        for(OrderItem oi : orderItems){
            OrderItem oldValue = oldOrderItems != null && oldOrderItems.containsKey(oi.Id) ? oldOrderItems.get(oi.Id) : null;
            if(oldValue == null || oldValue.PriceBookEntry.Product2Id != oi.PriceBookEntry.Product2Id)
                orderIdList.add(oi.OrderId);
        }
            
        if(orderIdList.size() > 0)
            for(Order ord : [SELECT Id, AccountId, isSunshineCompliant__c, (SELECT Id, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Product_Source_Division__c, PriceBookEntry.Product2.Product_Source_Division__r.Sunshine_Act__c from OrderItems where PriceBookEntry.Product2.Product_Source_Division__r.Sunshine_Act__c = TRUE) from Order where ID IN :orderIdList AND AccountId != :Configuration_Settings__c.getInstance().Default_Internal_Account__c]){
                    if(ord.getSObjects('OrderItems') != null)
                        ord.isSunshineCompliant__c = true;
                        updateOrderList.add(ord);
                }
                
        if(updateOrderList.size() > 0)
            update updateOrderList;
        
           
            
    }

    
}