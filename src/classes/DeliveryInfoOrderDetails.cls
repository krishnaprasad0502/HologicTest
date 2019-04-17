public class DeliveryInfoOrderDetails {
    
    public static String getLocalDateTime(Datetime z) {    
        if (z != null) {
        	return z.format('MM/dd/yyyy H:mm a z');
        } else {
            return null;
        }
    }
    
    public String DeliveryTime {
        get {
            if (theOrder != null && theOrder.Delivery_Date_Time__c != null) {
                return getLocalDateTime(theOrder.Delivery_Date_Time__c);    
            } else {
                return null;
            }
        }
        set;
    }
    
    public String PickupTime {
        get {
            if (theOrder != null && theOrder.Pickup_Date_Time__c != null) {
                return getLocalDateTime(theOrder.Pickup_Date_Time__c);    
            } else {
                return null;
            }
        }
        set;
    }
    
    public Order theOrder {
        get {
        	if(theOrder == null){
        		return null;
        	}
            return [
                SELECT
                    OrderNumber,
                    OrderReferenceNumber,
                    Account.Name,
                    Ship_To_Site_Location__r.Address_Line_1__c,
                    Ship_To_Site_Location__r.City__c,
                    Ship_To_Site_Location__r.State__c,
                    Ship_To_Site_Location__r.Zip_Code__c,
                    SBQQ__Quote__r.SBQQ__PrimaryContact__r.Name,
                    SBQQ__Quote__r.SBQQ__PrimaryContact__r.Phone,
                    SBQQ__Quote__r.SBQQ__PrimaryContact__r.Email,
                    SBQQ__Quote__r.SBQQ__SalesRep__r.Name,
                    SBQQ__Quote__r.SBQQ__SalesRep__r.Phone,
                    SBQQ__Quote__r.Requested_Date__c,
                    Project_Manager__r.Name,
                    Project_Manager__r.Phone,
                    Owner.Name,
                    Owner.Phone,
                    DeInstalled_Asset__r.Name,
                    Delivery_Date_Time__c,
                    Pickup_Date_Time__c,
                    Special_Instructions__c,
                    Special_Array_Instructions__c,
                    (SELECT 
                        Product2.Name, 
                        Product2.Trade_In_Product__c, 
                        PricebookEntry.Product2.Name, 
                        Asset_Serial_Number__c, 
                        RMA_Number_Scrap__c 
                     FROM OrderItems),
                    (SELECT 
                        Contact.Name, 
                        Owner.Phone,
                        Owner.Name,
                        RecordType.Name
                     FROM Work_Orders__r)
                FROM Order 
                WHERE Id = :theOrder.Id
            ];
        } set;
    }
}