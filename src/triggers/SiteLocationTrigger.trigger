/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    Trigger framework for the Site_Location__c object
Test Class:     SiteLocationTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/28/2016      Denise Bacher       Initial Creation (US460)
------------------------------------------------------------*/
trigger SiteLocationTrigger on Site_Location__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    private static Boolean isActive = GlobalUtility.isTriggerActive('sitelocTrigger');
    
    if (Trigger.isBefore && isActive) {
        if (Trigger.isInsert) {
            SiteLocationTriggerActions.setAccountLookup((List<Site_Location__c>)Trigger.new);
            SiteLocationTriggerActions.setSiteAccount((List<Site_Location__c>)Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            SiteLocationTriggerActions.setAccountLookup((List<Site_Location__c>)Trigger.new);
            SiteLocationTriggerActions.setSiteAccount((List<Site_Location__c>)Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }

    if (Trigger.isAfter && isActive) {
        if (Trigger.isInsert) {
            SiteLocationTriggerActions.updateCustomerAccountAddress((List<Site_Location__c>)Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            SiteLocationTriggerActions.updateCustomerAccountAddress((List<Site_Location__c>)Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {}
        if (Trigger.isUndelete) {}
    }
}