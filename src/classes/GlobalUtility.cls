/*------------------------------------------------------------
Author:         Denise Bacher
Company:        Salesforce.com
Description:    A global utility class for common functions
Test Class:     

History:
<Date>          <Authors Name>      <Brief Description of Change>
03/28/2016      Denise Bacher       Initial Creation
------------------------------------------------------------*/
public with sharing class GlobalUtility {
    //maps to hold the record type info
    private static Map<String, Schema.SObjectType> globalDescribe {
        get{
            if(globalDescribe == null){
                globalDescribe = Schema.getGlobalDescribe();
            }
            return globalDescribe;
        }
        set;
    }
    private static Map<String, List<RecordType>> allRecordTypesBySObjectType;
    private static Map<String, Map<Id, String>> recordTypesById = new Map<String, Map<Id, String>>();
    private static Map<String, Map<String, Id>> recordTypesByName = new Map<String, Map<String, Id>>();
    private static Map<String, Map<Id, String>> recordTypesByIdDev = new Map<String, Map<Id, String>>();
    
    private static List<RecordType> getAllRecordTypesForObject(String objectName){
        if(allRecordTypesBySObjectType == null){
            allRecordTypesBySObjectType = new Map<String, List<RecordType>>();
            for(RecordType rt : [
                SELECT Id
                      ,SObjectType
                      ,Name
                      ,DeveloperName
                  FROM RecordType
            ]){
                List<RecordType> rtList = allRecordTypesBySObjectType.get(rt.SObjectType);
                if(rtList == null){
                    rtList = new List<RecordType>();
                }
                rtList.add(rt);
                allRecordTypesBySObjectType.put(rt.SObjectType, rtList);
            }
        }
        return allRecordTypesBySObjectType.get(objectName);
    }

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Function to retrieve the record type map for object 
    Inputs:         objectName - The name of the SObject
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/28/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    private static void retrieveRecordTypeMapsForObject(String objectName) {
        // get the object description
        if (String.isNotBlank(objectName) && globalDescribe.containsKey(objectName)) {
            Schema.SObjectType sObj = globalDescribe.get(objectName);
            
            List<RecordType> recordTypes = getAllRecordTypesForObject(objectName);
            //List<RecordType> recordTypes = [Select Id, DeveloperName, Name, SobjectType From RecordType Where SobjectType =: objectName];
            
            for(RecordType r : recordTypes){
                if(!recordTypesByName.containsKey(objectName)){
                    recordTypesByName.put(objectName, new Map<String, Id>());
                }
                recordTypesByName.get(objectName).put(r.DeveloperName, r.Id);
                
                if(!recordTypesById.containsKey(objectName)){
                    recordTypesById.put(objectName, new Map<Id, String>());
                }
                recordTypesById.get(objectName).put(r.Id, r.Name);
                
                if(!recordTypesByIdDev.containsKey(objectName)){
                    recordTypesByIdDev.put(objectName, new Map<Id, String>());
                }
                recordTypesByIdDev.get(objectName).put(r.Id, r.DeveloperName);
            }
        }
        
        //System.debug('recordTypesByName ' +recordTypesByName);
        //System.debug('recordTypesById ' +recordTypesById);
    }

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Given a record type name for a SObject, return the record type id 
    Inputs:         objectName - The name of the SObject
                    recordTypeName - The name of the record type (API Name)
    Returns:        The Id of the specified record type
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/28/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static Id getRecordTypeId(String objectName, String recordTypeName) {
        Id recordTypeId = null;
        // make sure we have this object's record types mapped
        if (!recordTypesByName.containsKey(objectName)){
            retrieveRecordTypeMapsForObject(objectName);
        }

        // now grab and return the requested id 
        Map<String, Id> rtMap = recordTypesByName.get(objectName);
        if (rtMap != null && rtMap.containsKey(recordTypeName)) {
            recordTypeId = rtMap.get(recordTypeName);
        }
        
        return recordTypeId;
    }

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Given a record type id for a SObject, return the record type name 
    Inputs:         objectName - The name of the SObject
                    recordTypeId - The id of the record type 
    Returns:        The name of the specified record type (Label Name)
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/28/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static String getRecordTypeName(String objectName, Id recordTypeId) {
        String recordTypeName = null;
        // make sure we have this object's record types mapped
        if (!recordTypesById.containsKey(objectName)){
            retrieveRecordTypeMapsForObject(objectName);
        }
        
        // now grab and return the requested id 
        Map<Id, String> rtMap = recordTypesById.get(objectName);
        if (rtMap != null && rtMap.containsKey(recordTypeId)) {
            recordTypeName = rtMap.get(recordTypeId);
        }
        
        return recordTypeName;
    }

    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Given a record type id for a SObject, return the record type name 
    Inputs:         objectName - The name of the SObject
                    recordTypeId - The id of the record type 
    Returns:        The name of the specified record type (Developer Name)
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    07/20/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static String getRecordTypeDeveloperName(String objectName, Id recordTypeId) {
        String recordTypeName = null;
        // make sure we have this object's record types mapped
        if (!recordTypesByIdDev.containsKey(objectName)){
            retrieveRecordTypeMapsForObject(objectName);
        }
        
        // now grab and return the requested id 
        Map<Id, String> rtMap = recordTypesByIdDev.get(objectName);
        if (rtMap != null && rtMap.containsKey(recordTypeId)) {
            recordTypeName = rtMap.get(recordTypeId);
        }
        
        return recordTypeName;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Given a SObject, return all the record types by name and Id
    Inputs:         objectName - The name of the SObject 
    Returns:        The a map of object record types by Name (API Name), and Id
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/31/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static Map<String, Id> getAllObjectRecordTypeByName(String objectName) {
        // make sure we have this object's record types mapped
        if (!recordTypesByName.containsKey(objectName)){
            retrieveRecordTypeMapsForObject(objectName);
        }
        
        return recordTypesByName.get(objectName);
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Given a SObject, return all the record types by Id and name
    Inputs:         objectName - The name of the SObject 
    Returns:        The a map of object record types by Id, and Name (Label Name)
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/31/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static Map<Id, String> getAllObjectRecordTypeById(String objectName) {
        // make sure we have this object's record types mapped
        if (!recordTypesByID.containsKey(objectName)){
            retrieveRecordTypeMapsForObject(objectName);
        }
        
        return recordTypesByID.get(objectName);
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    given an object field, return the pick list values as a list of strings
    Inputs:         field - the pick list field  
    Returns:        All picklist options as a list of strings
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/31/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static List<String> getFieldPickListValues(Schema.SObjectField field) {
        System.assert(null != field, 'field param cannot be null');
        
        List<String> values = new List<String>();
        for (Schema.PicklistEntry val : field.getDescribe().getPickListValues()) {
            values.add(val.getValue());
        }

        return values;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    given an object field, return the pick list values as a list of SelectOption
    Inputs:         field - the pick list field  
    Returns:        All picklist options as a list of SelectOption
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    04/04/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public static List<SelectOption> getPickListAsSelectOptions(Schema.SObjectField field) {
        System.assert(null != field, 'field param cannot be null');
        
        List<SelectOption> options = new List<SelectOption>();
        for (Schema.PicklistEntry val : field.getDescribe().getPickListValues()) {
            options.add(new SelectOption(val.getValue(), val.getLabel()));
        }

        return options;
    }
    
    /*------------------------------------------------------------
    Author:         Denise Bacher
    Company:        Salesforce.com
    Description:    Custom Exceptions
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    04/04/2016      Denise Bacher       Initial Creation
    ------------------------------------------------------------*/
    public class GenericException extends Exception {}
    
    /*------------------------------------------------------------
    Author:         Mani
    Description:    Prevent Recusrsion
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    10/13/2016      Mani                 Initial Creation
    ------------------------------------------------------------*/
    public static Boolean run = true;
    public static Boolean runOnce(){
        if(run){
            run = false;
            return true;
        }
        else{
            return run;
        }
    }
    
    /*------------------------------------------------------------
    Author:         Mani
    Description:    Activate/Deactivate triggers using TriggerSwitch custom setting
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    02/10/2017      Mani                 Initial Creation
    ------------------------------------------------------------*/
    
    public static Boolean isTriggerActive(String triggerName){
    
        Boolean isActive=false;
       // isActive=[SELECT Name, Active__c FROM Trigger_Switch__C WHERE Name = :triggerName].Active__c;
        Trigger_Switch__c pmpSwitch = Trigger_Switch__c.getValues(triggerName);
        if(pmpSwitch != null)
            isActive = pmpSwitch.Active__c;
        
        return isActive;  
    }

   /*------------------------------------------------------------
    Author:        Raj Sharan  AppsAssociates
    Description:   2 Method to set a Boolean Flag False & Set Boolean to True.
                  Called at the beginning and end of a trigger execution, so that it doesn't run due to other automations.
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/1/2017      Raj Sharan                Initial Creation
    ------------------------------------------------------------*/

   private static boolean serviceTrigger = false;
   
   /*public static boolean callServiceTrigger(){
        return serviceTrigger;
    }

    public static void setServiceTrigger(){
        serviceTrigger = true;
    }*/
    
    /*------------------------------------------------------------
    Author:         Mani
    Description:    Prevent Recusrsion on Before Event Triggers
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/24/2017      Mani                 Initial Creation
    ------------------------------------------------------------*/
    /*public static Boolean runBefore = true;
    public static Boolean runOnceOnBefore(){
        if(runBefore){
            runBefore = false;
            return true;
        }
        else{
            return runBefore;
        }
    }*/
    
    /*------------------------------------------------------------
    Author:         Mani
    Description:    Prevent Recusrsion on After Event Triggers
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/24/2017      Mani                 Initial Creation
    ------------------------------------------------------------*/
    public static Boolean runAfter = true;
    public static Boolean runOnceOnAfter(){
        if(runAfter){
            runAfter = false;
            return true;
        }
        else{
            return runAfter;
        }
    }
     /*------------------------------------------------------------
    Author:         Kasmoor Reddy
    Description:    Insert Apex Debug Log object to log the exceptions from required Apex Classes/Triggers
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    02/23/2018      Kasmoor Reddy       Initial Creation(US-3995)
    ------------------------------------------------------------*/
     public static Apex_Log__c NewApexLog(String ClassName, String MethodName, String ErrorMessage,Datetime CompletedDate,String ExtendedStatus,Integer JobItemsProcessed,String JobType,Integer NumberOfErrors,String Status,Integer TotalJobItems,Integer LineNumber,String TypeName) {
        return new Apex_Log__c(
            Class_Name__c = ClassName
            , Method_Name__c = MethodName
            , Error_Message__c = ErrorMessage
            ,CompletedDate__c=CompletedDate
            ,ExtendedStatus__c=ExtendedStatus
            ,JobItemsProcessed__c=JobItemsProcessed
            ,JobType__c=JobType
            ,NumberOfErrors__c=NumberOfErrors
            ,Status__c=Status
            ,TotalJobItems__c=TotalJobItems
            ,LineNumber__c=LineNumber
            ,TypeName__c=TypeName
            
        );
    }
    
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Description:    Delay method that can be invoked to introduce a delay in the logic
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    03/22/2018      Mani Sundaresan      Initial Creation
    ------------------------------------------------------------*/
    @future
    public static void sleep(integer milliseconds) 
    {
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        do
        {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliseconds);
             
    }

  /*public static Boolean CheckValidationRules(String validationname){
    //if(validationname =='Opportunity_validations__c'){
     return Validation_Rule_Exception__c.getInstance().Opportunity_validations__c;
    //}
      
    //return false;  
    
  }*/

    
}