/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Functions related to DemoRequest records

History:
<Date           <Authors Name>      <Brief Description of Change>
05/22/2018      Dave Mansell        Initial Creation (US-0004234)
------------------------------------------------------------*/

public class DemoRequestTriggerActions {
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Sets destination address on incoming DemoRequest records
    Inputs:             List of records
    Returns:            N/A
    Test Class(es):     DemoRequestTriggerActions_Test.testSetDestinationAddress
    ------------------------------------------------------------*/
    public static void setDestinationAddress(List<Demo_Request__c> reqs){
        //Gather parent Ids
        Map<Id, Schema.Location> destLocsById = new Map<Id, Schema.Location>();
        Map<Id, Site_Location__c> endLocsById = new Map<Id, Site_Location__c>();
        for(Demo_Request__c req : reqs){
            if(req.Destination_Location__c != null){
                destLocsById.put(req.Destination_Location__c, null);
            }
            if(req.End_Customer_Location__c != null){
                endLocsById.put(req.End_Customer_Location__c, null);
            }
        }
        
        //Query for destination locations
        destLocsById = new Map<Id, Schema.Location>([
            SELECT Id
                  ,VisitorAddressId
                  ,(SELECT Id
                          ,Street
                          ,City
                          ,StateCode
                          ,CountryCode
                          ,PostalCode
                      FROM Addresses
                   )
              FROM Location
             WHERE Id IN :destLocsById.keySet()
        ]);
        
        //Query for site locations
        endLocsById = new Map<Id, Site_Location__c>([
            SELECT Id
                  ,Address_Line_1__c
                  ,Address_Line_2__c
                  ,Address_Line_3__c
                  ,Address_Line_4__c
                  ,City__c
                  ,State__c
                  ,Country__c
                  ,Zip_Code__c
              FROM Site_Location__c
             WHERE Id IN :endLocsById.keySet()
        ]);
        
        for(Demo_Request__c req : reqs){
            if(req.Destination_Location__c != null){
                Schema.Location destLoc = destLocsById.get(req.Destination_Location__c);
                
                if(req.End_Customer_Location__c == null){
                    req.Destination_Address__c = destLoc.VisitorAddressId;
                } else {
                    Site_Location__c endLoc = endLocsById.get(req.End_Customer_Location__c);
                    
                    String endLocStreet = endLoc.Address_Line_1__c;
                    if(endLoc.Address_Line_2__c != null){
                        endLocStreet += ' ' + endLoc.Address_Line_2__c;
                    }
                    if(endLoc.Address_Line_3__c != null){
                        endLocStreet += ' ' + endLoc.Address_Line_3__c;
                    }
                    if(endLoc.Address_Line_4__c != null){
                        endLocStreet += ' ' + endLoc.Address_Line_4__c;
                    }
                    
                    Boolean addressFound = false;
                    for(Schema.Address addr : destLoc.Addresses){
                        if(addr.Street          == endLocStreet
                            && addr.City        == endLoc.City__c
                            && addr.StateCode   == endLoc.State__c
                            && addr.CountryCode == endLoc.Country__c
                            && addr.PostalCode  == endLoc.Zip_Code__c
                        ){
                            addressFound = true;
                            req.Destination_Address__c = addr.Id;
                        }
                    }
                    
                    if(addressFound == false){
                        Schema.Address newAddress = new Schema.Address();
                        newAddress.ParentId             = req.Destination_Location__c;
                        newAddress.Street               = endLocStreet;
                        newAddress.City                 = endLoc.City__c;
                        newAddress.StateCode            = endLoc.State__c;
                        newAddress.CountryCode          = endLoc.Country__c;
                        newAddress.PostalCode           = endLoc.Zip_Code__c;
                        newAddress.AddressType          = 'Shipping';
                        newAddress.LocationType         = 'Site';
                        newAddress.Active__c            = true;
                        
                        //Do DML inside the for loop, since nothing has an ID yet
                        insert newAddress;
                        req.Destination_Address__c = newAddress.Id;
                    }
                }
            }
        }
    }
    
    /*------------------------------------------------------------
    Author:             Dave Mansell, Salesforce
    Description:        Check for APPROVED status and perform consequent actions
    Inputs:             List of records, Map of old records
    Returns:            N/A
    Test Class(es):     DemoRequestTriggerActions_Test.testCheckForApproval
    ------------------------------------------------------------*/
    public static void checkForApproval(Map<Id, Demo_Request__c> newMap, Map<Id, Demo_Request__c> oldMap){
        List<Demo_Request__c> validReqs = new List<Demo_Request__c>();
        Map<Id, Asset> assetsToUpdateById = new Map<Id, Asset>();
        for(Demo_Request__c req : newMap.values()){
            Demo_Request__c old = oldMap.get(req.Id);
            if(req.Status__c == 'Approved' && old.Status__c != 'Approved'){
                validReqs.add(req);
                if(req.Asset__c != null){
                    assetsToUpdateById.put(req.Asset__c, null);
                }
            }
        }
        
        if(validReqs.isEmpty()){
            return;
        }
        
        validReqs = [
            SELECT Id
                  ,Asset__c
                  ,Destination_Address__c
                  ,Destination_Address__r.Street
                  ,Destination_Address__r.City
                  ,Destination_Address__r.StateCode
                  ,Destination_Address__r.CountryCode
                  ,Destination_Address__r.PostalCode
                  ,Destination_Location__c
                  ,Destination_Location__r.Oracle_Party_ID__c
                  ,Destination_Location__r.VisitorAddressId
                  ,End_Customer_Account__c
                  ,End_Customer_Location__c
                  ,Product__c
                  ,OwnerId
                  ,(SELECT Id
                          ,Product__c
                          ,Quantity__c
                      FROM Demo_Request_Lines__r
                     WHERE Product__c != null
                   )
              FROM Demo_Request__c
             WHERE Id IN :validReqs
        ];
        
        //Gather DRI product IDs and find PBEs
        Set<Id> productIds = new Set<Id>();
        for(Demo_Request__c req : validReqs){
            if(req.Product__c != null){
                productIds.add(req.Product__c);
            }
            for(Demo_Request_Item__c dri : req.Demo_Request_Lines__r){
                productIds.add(dri.Product__c);
            }
        }
        Id standardPBId = Configuration_Settings__c.getInstance().Standard_Pricebook__c;
        Map<Id, PricebookEntry> pbesByProductId = new Map<Id, PricebookEntry>();
        if(productIds.size() > 0){
            for(PricebookEntry pbe : [
                SELECT Id
                      ,Product2Id
                      ,UnitPrice
                      ,CurrencyIsoCode
                  FROM PricebookEntry
                 WHERE Product2Id IN :productIds
                   AND Pricebook2Id = :standardPBId
                   AND CurrencyIsoCode = 'USD'
            ]){
                pbesByProductId.put(pbe.Product2Id, pbe);
            }
        }
        
        //Update Assets
        if(assetsToUpdateById.size() > 0){
            assetsToUpdateById = new Map<Id, Asset>([
                SELECT Id
                  FROM Asset
                 WHERE Id IN :assetsToUpdateById.keySet()
            ]);
            
            for(Demo_Request__c req : validReqs){
                if(req.Asset__c != null){
                    Asset asst = assetsToUpdateById.get(req.Asset__c);
                    if(req.End_Customer_Location__c != null){
                        asst.Install_Location__c    = req.End_Customer_Location__c;
                    }
                    asst.Ship_To_Address__c         = req.Destination_Address__c;
                    asst.Install_Address__c         = req.Destination_Address__c;
                    asst.Bill_To_Address__c         = req.Destination_Location__r.VisitorAddressId;
                }
            }
            
            update assetsToUpdateById.values();
        }
        
        //Create Orders and OIs
        Map<Id, Order> ordersByReqId = new Map<Id, Order>();
        Map<Id, List<OrderItem>> oisByReqId = new Map<Id, List<OrderItem>>();
        Id ordRTId = GlobalUtility.getRecordTypeId('Order', 'Demo_Order');
        Id ordAccId = Configuration_Settings__c.getInstance().Default_Internal_Account__c;
        for(Demo_Request__c req : validReqs){
            if(req.Asset__c == null || req.Demo_Request_Lines__r.size() > 0){
                //Create Orders
                Order ord = new Order();
                ord.Demo_Request__c             = req.Id;
                ord.Type                        = 'Demo Order';
                ord.RecordTypeId                = ordRTId;
                ord.Operating_Unit__c           = 'HOLX_US_OU';
                ord.Pricebook2Id                = standardPBId;
                ord.End_Customer_Account__c     = req.End_Customer_Account__c;
                ord.End_Customer_Location__c    = req.End_Customer_Location__c;
                ord.AccountId                   = ordAccId;
                ord.Oracle_Party_Id__c          = req.Destination_Location__r.Oracle_Party_ID__c;
                ord.ShippingStreet              = req.Destination_Address__r.Street;
                ord.ShippingCity                = req.Destination_Address__r.City;
                ord.ShippingStateCode           = req.Destination_Address__r.StateCode;
                ord.ShippingCountryCode         = req.Destination_Address__r.CountryCode;
                ord.ShippingPostalCode          = req.Destination_Address__r.PostalCode;
                ord.Address_Type__c             = 'Other Address';
                ord.EffectiveDate               = Date.today();
                ord.Status                      = 'DRAFT';
                ord.OwnerId                     = req.OwnerId;
                ord.CurrencyIsoCode             = req.Product__c != null ? pbesByProductId.get(req.Product__c).currencyIsoCode : 'USD';
                ordersByReqId.put(req.Id, ord);
                System.debug('1st pass:'+ord.Pricebook2Id);
                //Create OIs
                List<OrderItem> ois = new List<OrderItem>();
                
                if(pbesByProductId.size() > 0){
                    if(req.Product__c != null){
                        PricebookEntry reqPBE = pbesByProductId.get(req.Product__c);
                        if(reqPBE != null){
                            OrderItem reqOI = new OrderItem();
                            reqOI.Product2Id            = req.Product__c;
                            reqOI.PricebookEntryId      = reqPBE.Id;
                            reqOI.UnitPrice             = reqPBE.UnitPrice;
                            reqOI.Quantity              = 1;
                            reqOI.Line_Type__c          = 'Shipment Demo';
                            ois.add(reqOI);
                        }
                    }
                }
                    
                for(Demo_Request_Item__c dri : req.Demo_Request_Lines__r){
                    PricebookEntry pbe = pbesByProductId.get(dri.Product__c);
                    if(pbe == null){
                        newMap.get(req.Id).addError('One or more of this Demo Request\'s line items does not have a matching pricebook entry in the standard pricebook.');
                    } else {
                        OrderItem oi = new OrderItem();
                        oi.Product2Id           = dri.Product__c;
                        oi.PricebookEntryId     = pbe.Id;
                        oi.UnitPrice            = pbe.UnitPrice;
                        oi.Quantity             = dri.Quantity__c;
                        oi.Line_Type__c         = 'Demo Accessory';
                        ois.add(oi);
                    }
                }
                oisByReqId.put(req.Id, ois);
            }
        }
        
        if(ordersByReqId.size() > 0){
            //Insert orders
            insert ordersByReqId.values();
            
            //Insert OIs with parent Order Id
            List<OrderItem> oisToInsert = new List<OrderItem>();
            for(Id reqId : oisByReqId.keySet()){
                Order ord = ordersByReqId.get(reqId);
                for(OrderItem oi : oisByReqId.get(reqId)){
                    System.debug('final pass:'+oi.Order.Pricebook2Id);
                    oi.OrderId = ord.Id;
                    oisToInsert.add(oi);
                }
            }
            insert oisToInsert;
            
            //Update orders in "ENTERED" status
            for(Order ord : ordersByReqId.values()){
                ord.Status = 'ENTERED';
            }
            update ordersByReqId.values();
        }
    }
}