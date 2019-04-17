/********************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Controller class for DynamicObjectSummaryView component. 

TestClass: 
Code Coverage: 

History:
<Date>              <Author Name>           <Brief description of change >   <Copa.do US#>
09/23/2018          Sunil Kumar Sharma      Initial Creation                  US-0005701 
*********************************************************************************************/
public class DynamicObjectSummaryViewController {
    @AuraEnabled
    public static List<String> readFieldSet(String fieldSetName, String objectName)
    {
        system.debug('Values are:'+ fieldSetName + 'and' + objectName);
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = sObjectTypeObj.getDescribe();
    
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
    
        List<String> fieldApiNamesList = new List<String>();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields())
        {
            fieldApiNamesList.add(fieldSetMemberObj.getFieldPath()); 
        }
        return fieldApiNamesList ;
        
    } 
    
    @AuraEnabled
    public static String getRelatedObjectId(Id parentRecordId,String relatedObjectApiName,String parentFieldName){
        String masterRecordId = parentRecordId ;
        String queryStr = 'SELECT Id FROM '+ relatedObjectApiName ;
        if(parentFieldName != '' && parentFieldName != null){
             String whereClause = ' WHERE ' + parentFieldName + '= \'' + masterRecordId +'\''  ;    
            queryStr = queryStr + whereClause ;
        }
        queryStr = queryStr + ' LIMIT 1' ;
        system.debug('Query Is '+ queryStr);
        List<sobject> sobjRecordList = Database.query(queryStr);
        if(sObjRecordList.size() > 0){
            return sObjRecordList[0].Id ;
        }else{
            return null ;
        }       
    }
    
    @AuraEnabled
    public static String getParentObjectId(Id parentRecordId,String ObjectApiName,String parentFieldName){
        String masterRecordId = parentRecordId ;
        String queryStr = 'SELECT Id,'+parentFieldName+ ' FROM '+ ObjectApiName + ' WHERe Id = \'' + masterRecordId +'\'';
        /*if(parentFieldName != '' && parentFieldName != null){
             String whereClause = ' WHERE ' + parentFieldName + '= \'' + masterRecordId +'\''  ;    
            queryStr = queryStr + whereClause ;
        }*/
        queryStr = queryStr + ' LIMIT 1' ;
        system.debug('Query Is '+ queryStr);
        List<sobject> sobjRecordList = Database.query(queryStr);
        if(sObjRecordList.size() > 0){
            return string.valueof(sobjRecordList[0].get(parentFieldName)) ;
        }else{
            return null ;
        }       
    }
}