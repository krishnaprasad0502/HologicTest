/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 12/19/2018
    Description  : Custom controller to create breadcrumbs
    Test Class   : BreadCrumbListController_Test    
    Coverage     : 100%  

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    12/19/2018       Sunil Sharma           Initial Creation                US-0006345
**************************************************************************************/
public class BreadCrumbListController {
	 /*
     * Method Name: fetchConfigData()
     * Input Param: none
     * Return: Service_Community_Config__c reference 
     * Description: This method is created to fetch custom setting data.
     */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
    
        /*
     * Method Name: fetchRecordName()
     * Input Param: current record id, field api name, object api name
     * Return: Record Field value
     * Description: This method is created to return the selected field value of the current record.
     */
    @AuraEnabled
    public static String fetchRecordName(String currentRecId, String fieldAPI, String objType){
        
        string str = 'SELECT id ';
        if(fieldAPI != Null && fieldAPI != ''){
            str += ','+fieldAPI+' ';
        }
        str += ' FROM '+ String.escapeSingleQuotes(objType)+' WHERE Id =: currentRecId';
       	list<sObject> dynamicRecs = new list<sObject>();
        system.debug('query part is '+ str);
       	for(sObject SO : Database.query(str)){
            dynamicRecs.add(SO);
        }    
        if(dynamicRecs.size()> 0){
            return string.valueof(dynamicRecs[0].get(fieldAPI));
        }else{
            return null;
        }
        
    }
}