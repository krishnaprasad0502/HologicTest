@isTest
private class DeliveryInfoOrderDetails_Test {


    public static String localDateTime(Datetime z) {    
        if (z != null) {
            return z.format('MM/dd/yyyy H:mm a z');
        } else {
            return null;
        }
    }

	private static testMethod void checkData() {
	    try {
	    	Order testOrder = new DeliveryInfoOrderDetails().theOrder;
	    	
	    } catch(Exception e){}
	}
	
	private static testMethod void checkDates() {
	    
	    DateTime currentDate = System.Now();
	    
	    TestUtility.setupConfigurationSettings();
	    
	    // insert an account
        Account custAccount = TestUtility.newAccount('Customer Account', 'testCust', 'ABC Street', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert custAccount;
        
        //insert Pricebook
        Pricebook2 pb =TestUtility.newPricebook('Test Pricebook');
        insert pb;
	    
        //insert an Order
        Order ord = TestUtility.newOrder(custAccount.Id,pb.Id,null,'DRAFT',Date.Today());
        ord.Delivery_Date_Time__c = currentDate;
        ord.Pickup_Date_Time__c = currentDate;
        insert ord;
        
        DeliveryInfoOrderDetails diod = new DeliveryInfoOrderDetails();
        System.assertEquals(null, diod.DeliveryTime);
        System.assertEquals(null, diod.PickupTime);
        
        diod.theOrder = ord;
        System.assertEquals(localDateTime(currentDate), diod.DeliveryTime);
        System.assertEquals(localDateTime(currentDate), diod.PickupTime);
        
	}

}