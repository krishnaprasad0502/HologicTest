public class WorkOrderCreationHelper {
    
    public static void createWorkOrdersAndWOLIs(List<Order> orders, List<OrderItem> orderItems){
        Configuration_Settings__c config = Configuration_Settings__c.getInstance();
        Id pbId             = config.Service_Pricebook_USD__c;
        Id installWORTId    = config.Install_Upgrade_WO_RecordTypeID__c;
        Id clinicalWORTId   = config.Clinical_WO_RecordTypeID__c;
        
        Set<Id> quoteIds = new Set<Id>();
        if(orders != null){
            orderItems = new List<OrderItem>();
            
            for(Order ord : orders){
                if(ord.SBQQ__Quote__c != null){
                    quoteIds.add(ord.SBQQ__Quote__c);
                }
            }
        } else if(orderItems != null){
            orders = new List<Order>();
            
            for(OrderItem oi : [SELECT Order.SBQQ__Quote__c FROM OrderItem WHERE Id IN :orderItems]){
                quoteIds.add(oi.Order.SBQQ__Quote__c);
            }
        }
        
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id
                  ,SBQQ__Quote__c
                  ,SBQQ__Product__c
                  ,Order_Group_By__c
                  ,(SELECT Id FROM Order_Products__r)
              FROM SBQQ__QuoteLine__c
             WHERE SBQQ__Quote__c IN :quoteIds
               AND Order_Group_By__c != null
        ];
        //Group quote lines by GroupBy
        Map<String, List<SBQQ__QuoteLine__c>> lineListsByGroup = new Map<String, List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            List<SBQQ__QuoteLine__c> lineList = lineListsByGroup.get(quoteLine.Order_Group_By__c);
            if(lineList == null){
                lineList = new List<SBQQ__QuoteLine__c>();
            }
            lineList.add(quoteLine);
            lineListsByGroup.put(quoteLine.Order_Group_By__c, lineList);
        }
        //Map quote line groups by key: QuoteId|Product2Id
        Map<String, List<SBQQ__QuoteLine__c>> quoteLineGroupsByKey = new Map<String, List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            String key = quoteLine.SBQQ__Quote__c + '|' + quoteLine.SBQQ__Product__c;
            quoteLineGroupsByKey.put(key, lineListsByGroup.get(quoteLine.Order_Group_By__c));
        }
        
        //Populate order items list with field values we'll need, via query
        Map<Id, OrderItem> oisById = new Map<Id, OrderItem>([
            SELECT Id
                  ,CurrencyISOCode
                  ,PricebookEntryId
                  ,Request_Date__c
                  ,SBQQ__Asset__c
                  ,Ship_To_Site_Location__c
                  ,Trade_In__c
                  ,Upgrade__c
                  ,Quantity
                  ,Order.Account.Credit_Profile_Class__c
                  ,Order.OrderNumber
                  ,Order.OrderReferenceNumber
                  ,Order.OpportunityId
                  ,Order.Opportunity.IT_PACS_Administrator__c
                  ,Order.Opportunity.Mammography_MRI_Manager__c
                  ,Order.Opportunity.RecordType.Name
                  ,Order.Opportunity.Dealer__r.Name
                  ,Order.Opportunity.Quote_Sales_Rep__c
                  ,Order.Oracle_Order_Type__c
                  ,Order.SBQQ__Quote__c
                  ,Order.SBQQ__Quote__r.SBQQ__PrimaryContact__c
                  ,Order.Type
                  ,Product2Id
                  ,Product2.Clinical_Work_Type__c
                  ,Product2.Description
                  ,Product2.Install_Case_Required__c
                  ,Product2.Install_Work_Type__c
                  ,Product2.Preceptorship_Case_Required__c
                  ,Product2.Preceptorship_Work_Type__c
                  ,SBQQ__QuoteLine__c
                  ,SBQQ__QuoteLine__r.SBQQ__UpgradedAsset__c
                  ,SBQQ__QuoteLine__r.Trade_In_Asset__c
                  ,Quote_Line__r.SBQQ__Product__c
                  ,Quote_Line__r.SBQQ__UpgradedAsset__c
                  ,Quote_Line__r.Trade_In_Asset__c
                  ,Returned_Asset__c
                  ,Returned_Asset__r.AccountId
                  ,Ship_To_Site_Location__r.Account__c
                  ,Ship_To_Site_Location__r.Address_Line_1__c
                  ,Ship_To_Site_Location__r.Address_Line_2__c
                  ,Ship_To_Site_Location__r.Address_Line_3__c
                  ,Ship_To_Site_Location__r.City__c
                  ,Ship_To_Site_Location__r.State__c
                  ,Ship_To_Site_Location__r.Zip_Code__c
                  ,Ship_To_Site_Location__r.Country__c
                  ,(SELECT Id
                  	  FROM Assets__r
                   )
              FROM OrderItem
             WHERE (OrderId IN :orders OR Id IN :orderItems)
               AND Order.Status = 'BOOKED'
               AND Order.Account.Credit_Profile_Class__c != 'INTERCOMPANY CUSTOMERS'
               AND Order.Oracle_Order_Type__c != 'WST INTERCO'
               AND Order.Oracle_Order_Type__c != 'WST CAPITAL INTL'
               //Advanced exchange scenario
               AND (Order.Type != 'Advanced Exchange' OR (Line_Type__c = 'Shipment' AND Product2.Product_Source_Division__r.Division__c != 'Medical Aesthetics'))
        ]);
        
        if(oisById.isEmpty()){
            return;
        }
        
        //Create work orders, mapped by key
        Map<String, WorkOrder> wosByKey = new Map<String, WorkOrder>();
        for(OrderItem oi : oisById.values()){
        	if(oi.Product2.Install_Case_Required__c){
	        	if(oi.Product2.Install_Work_Type__c != null && oi.Upgrade__c == false && oi.Trade_In__c == false){
	        		for(Integer i = 0; i < oi.Quantity; i++){
	    				WorkOrder wo = createWorkOrderFromOrderItem(oi, pbId);
	                    String woKey = i + '|' + oi.Id + '|Install';
		                wo.RecordTypeId         	= installWORTId;
		                wo.Type__c              	= 'New Install';
	    				wo.WorkTypeId				= oi.Product2.Install_Work_Type__c;
	    				if(oi.Assets__r.size() > i){
	    					wo.AssetId = oi.Assets__r[i].Id;
	    				} else {
	    					wo.AssetId = null;
	    				}
	                    wosByKey.put(woKey, wo);
	        		}
	            } else if(oi.Product2.Install_Work_Type__c != null && oi.Upgrade__c == true){
	        		for(Integer i = 0; i < oi.Quantity; i++){
	    				WorkOrder wo = createWorkOrderFromOrderItem(oi, pbId);
		                String woKey = i + '|' + oi.Id + '|Upgrade';
		                wo.RecordTypeId         	= installWORTId;
		                wo.Type__c              	= 'Upgrade';
	        			wo.WorkTypeId				= oi.Product2.Install_Work_Type__c;
	        			if(oi.SBQQ__QuoteLine__c != null){
	        				wo.AssetId				= oi.SBQQ__QuoteLine__r.SBQQ__UpgradedAsset__c;
	        			}
		                wosByKey.put(woKey, wo);
	        		}
	            }
	            if(oi.Product2.Clinical_Work_Type__c != null){
	        		for(Integer i = 0; i < oi.Quantity; i++){
	    				WorkOrder wo = createWorkOrderFromOrderItem(oi, pbId);
		                String woKey = i + '|' + oi.Id + '|Clinical';
		                wo.RecordTypeId				= clinicalWORTId;
		                wo.Type__c					= 'New Install';
	        			wo.WorkTypeId				= oi.Product2.Clinical_Work_Type__c;
	        			wo.Dealer_Account__c		= oi.Order.Opportunity.Dealer__r.Name;
	        			wo.Sales_Rep__c				= oi.Order.Opportunity.Quote_Sales_Rep__c;
	    				if(oi.Assets__r.size() > i){
	    					wo.AssetId = oi.Assets__r[i].Id;
	    				} else {
	    					wo.AssetId = null;
	    				}
		                wosByKey.put(woKey, wo);
	        		}
	            }
        	}
            if(oi.Product2.Install_Work_Type__c != null && oi.Trade_In__c == true){
				WorkOrder wo = createWorkOrderFromOrderItem(oi, pbId);
                String woKey = oi.Id + '|TradeIn';
                wo.RecordTypeId         = installWORTId;
                wo.Type__c              = 'De-Install';
        		wo.WorkTypeId			= oi.Product2.Install_Work_Type__c;
    			if(oi.SBQQ__QuoteLine__c != null){
    				wo.AssetId			= oi.SBQQ__QuoteLine__r.Trade_In_Asset__c;
    			}
                wosByKey.put(woKey, wo);
            }
            if(oi.Product2.Preceptorship_Case_Required__c == true){
				WorkOrder wo = createWorkOrderFromOrderItem(oi, pbId);
                String woKey = oi.Id + '|Preceptorship';
                wo.RecordTypeId         = clinicalWORTId;
                wo.Type__c              = 'Preceptorship';
        		wo.WorkTypeId			= oi.Product2.Preceptorship_Work_Type__c;
                wosByKey.put(woKey, wo);
            }
        }
        insert wosByKey.values();
        
        //Associate install work orders to clinical work orders
        List<WorkOrder> clinicalWOsToUpdate = new List<WorkOrder>();
        for(String key : wosByKey.keySet()){
            if(key.endsWith('Clinical')){
                WorkOrder installWO = wosByKey.get(key.replace('Clinical', 'Install'));
                if(installWO != null){
                    WorkOrder clinicalWO = wosByKey.get(key);
                    clinicalWO.ParentWorkOrderId = installWO.Id;
                    clinicalWOsToUpdate.add(clinicalWO);
                }
            }
        }
        update clinicalWOsToUpdate;
        
        //Update Quotelines' OrderItems with WO Ids
        Map<Id, OrderItem> oisToUpdateById = new Map<Id, OrderItem>();
        for(String key : wosByKey.keySet()){
        	if(key.endsWith('Install')){
	        	WorkOrder wo = wosByKey.get(key);
	        	OrderItem oi = oisById.get(key.split('\\|')[1]);
	        	
	        	String key2 = oi.Order.SBQQ__Quote__c + '|' + oi.Product2Id;
	        	if(quoteLineGroupsByKey.get(key2) != null){
	                for(SBQQ__QuoteLine__c quoteLine : quoteLineGroupsByKey.get(key2)){
	                	for(OrderItem quoteLineOI : quoteLine.Order_Products__r){
	                		quoteLineOI.Work_Order__c = wo.Id;
	                		oisToUpdateById.put(quoteLineOI.Id, quoteLineOI);
	                	}
	                }
	        	}
        	}
        }
        update oisToUpdateById.values();
    }
    
    private static WorkOrder createWorkOrderFromOrderItem(OrderItem oi, Id pbId){
    	WorkOrder wo = new WorkOrder();
    	
    	wo.AccountId                = oi.Ship_To_Site_Location__r.Account__c;
    	if(wo.AccountId == null){
    		wo.AccountId			= oi.Returned_Asset__r.AccountId;
    	}
        wo.Street                   = oi.Ship_To_Site_Location__r.Address_Line_1__c;
    	if(oi.Ship_To_Site_Location__r.Address_Line_2__c != null){
        	wo.Street += ' ' + oi.Ship_To_Site_Location__r.Address_Line_2__c;
    	}
    	if(oi.Ship_To_Site_Location__r.Address_Line_3__c != null){
        	wo.Street += ' ' + oi.Ship_To_Site_Location__r.Address_Line_3__c;
    	}
        wo.City                     = oi.Ship_To_Site_Location__r.City__c;
        wo.StateCode                = oi.Ship_To_Site_Location__r.State__c;
        wo.PostalCode               = oi.Ship_To_Site_Location__r.Zip_Code__c;
        wo.CountryCode              = oi.Ship_To_Site_Location__r.Country__c;
        wo.Pricebook2Id             = pbId;
        wo.Opportunity__c           = oi.Order.OpportunityId;
        wo.ContactId                = oi.Order.SBQQ__Quote__r.SBQQ__PrimaryContact__c;
        wo.Applications_Contact__c  = oi.Order.Opportunity.Mammography_MRI_Manager__c;
        wo.Connectivity_Contact__c  = oi.Order.Opportunity.IT_PACS_Administrator__c;
        wo.Order__c                 = oi.OrderId;
        if(oi.Order.Type == 'Advanced Exchange'){
	        wo.Subject              = 'Order#' + oi.Order.OrderNumber;
			wo.Description			= 'Order#' + oi.Order.OrderNumber + ' - ' + oi.Product2.Description;
        } else {
	        wo.Subject              = 'SO#' + oi.Order.OrderReferenceNumber;
			wo.Description			= 'SO#' + oi.Order.OrderReferenceNumber + ' - ' + oi.Product2.Description;
        }
    	wo.Install_Delivery_Date__c	= oi.Request_Date__c;
    	wo.Order_Line_Item__c		= oi.Id;
    	wo.Product__c				= oi.Product2Id;
    	wo.CurrencyISOCode			= oi.CurrencyISOCode;
    	
    	return wo;
    }
}