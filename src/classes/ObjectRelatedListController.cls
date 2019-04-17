/********************************************************************************************
Author:  Sunil Kumar Sharma
Company:  Hexaware Technologies
Description: Fetch asset list based on the product community product description. 

TestClass: ObjectRelatedListController_test
Code Coverage: 92%

History:
<Date>              <Author Name>        	<Brief description of change >   <Copa.do US#>
12/10/2018			Sunil Kumar Sharma		Initial Creation				  US-0006257  
*********************************************************************************************/
public class ObjectRelatedListController { 
	@AuraEnabled
    public static List <Asset> fetchAssetsList(String communityDescription) {
        
        return [ SELECT Id, Name,Community_Favorite_Asset__c, SerialNumber,Community_Custom_Asset_Name__c,Community_Product_Description__c,Asset_Location__c 
                FROM Asset 
                WHERE Product2.Community_Visible__c = true 
                AND Product2.Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') 
                AND Product2.Community_Product_Description__c =: communityDescription AND Status = 'Installed' ];       
    }
    
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
	Method Name	: getAccRecords
	Purpose		: To get the wrapper of Columns and Headers
	
    @AuraEnabled
    public static DataTableResponse getObjRecords(String strObjectName, String strFieldSetName, String communityDescription){                
       	
        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        //To hold the table hearders 
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();
        
        //The final wrapper response to return to component
        DataTableResponse response = new DataTableResponse();
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            //This way we can set the type of a column
            //We do not get the exact type from schema object which matches to lightning:datatable component structure
            system.debug(String.valueOf(eachFieldSetMember.getLabel()) +'Type is '+ dataType );
            if(dataType == 'datetime'){
                dataType = 'date';
            }
            if(dataType == 'reference'){
                dataType = 'url';
            }
            //Create a wrapper instance and store label, fieldname and type.
            DataTableColumns datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , 
                                                                String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                                dataType );
			lstDataColumns.add(datacolumns);
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        response.lstDataTableColumns = lstDataColumns;
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(! lstDataColumns.isEmpty()){            
            response.lstDataTableColumns = lstDataColumns;
            String query = 'SELECT Id, ' + String.join(lstFieldsToQuery, ',') + ' FROM Asset WHERE Product2.Community_Visible__c = true AND Product2.Division__c IN (\'BREAST HEALTH\',\'SKELETAL HEALTH\') AND Product2.Community_Product_Description__c =:communityDescription AND Status = \'Installed\'';
            System.debug(query);
            response.lstDataTableData = Database.query(query);
        }
        
        return response;
    }
    
    //Wrapper class to hold Columns with headers
    public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        
        //Create and set three variables label, fieldname and type as required by the lightning:datatable
        public DataTableColumns(String label, String fieldName, String type){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;            
        }
    }
    
    //Wrapper calss to hold response - This response is used in the lightning:datatable component
    public class DataTableResponse {
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}                
        
        public DataTableResponse(){
            lstDataTableColumns = new List<DataTableColumns>();
            lstDataTableData = new List<sObject>();
        }
    }*/
}