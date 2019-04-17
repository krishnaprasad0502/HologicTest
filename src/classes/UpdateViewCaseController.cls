/********************************************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 02/11/2019 
 	Description  : This class is used as controller to enable /disable the view all cases value on account relationship object.

    History:
    <Date>         <Author Name>            <Brief Description of Change>    <Copa.do US#>
    02/11/2019	   Sunil					Initial Creation				  US-0006703	
********************************************************************************************************************/
public without sharing class UpdateViewCaseController {

    @AuraEnabled
    public static List <AccountContactRelation> fetchAccount(Id contactId) {
        
        List < AccountContactRelation > returnList = new List < AccountContactRelation > ();
        List < AccountContactRelation > lstOfAccount = [SELECT Id,Account.Name,Community_View_All_Cases__c FROM AccountContactRelation WHERE ContactId=:contactId];
        
        for (AccountContactRelation acc: lstOfAccount) {
            returnList.add(acc);
        } 
        return returnList;
    }
    
  // method for update records after inline editing  
    @AuraEnabled
    public static List < AccountContactRelation > saveAccount(List<AccountContactRelation> lstAccount) {
        update lstAccount;
        return lstAccount;
    }
    
  // method for fetch picklist values dynamic  
    @AuraEnabled
    public static List < String > getselectOptions(sObject objObject, string fld) {
        system.debug('objObject --->' + objObject);
        system.debug('fld --->' + fld);
        List < String > allOpts = new list < String > ();
        // Get the object type of the SObject.
        Schema.sObjectType objType = objObject.getSObjectType();
        
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values =
            fieldMap.get(fld).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            allOpts.add(a.getValue());
        }
        system.debug('allOpts ---->' + allOpts);
        allOpts.sort();
        return allOpts;
    }
}