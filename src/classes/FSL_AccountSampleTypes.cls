public with sharing class FSL_AccountSampleTypes {
	@AuraEnabled
    public static String getTypes(){
        return Custom_Links__c.getInstance().Sample_Type__c;
    }
}