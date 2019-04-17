/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: This controller class is used to return Service Appointment related to Asset for Quicklinks 
			 for system detail Page on Asset detail page.

TestClass: SARelatedListViewController_Test
Code Coverage: 100%

History:
<Date>              <Author Name>        <Brief description of change >         <Copa.do US#>
1/10/2018	   		Vrushabh Katariya			Initial Creation				US-0006454
1/19/2018			Vrushabh Katariya		PM schedule on Home page and 
											My System detail Page				US-0006553
****************************************************************************/
public class SARelatedListViewController {
    /*
     * Method Name: fetchServiceAppointment()
     * Input Param: Object Name, Fieldset Name, Asset Id
     * Return: List<ServiceAppointment>
     * Description: This method is created to return Service Appointment records based on the asset id.
     * 
     * PM Schedule data while case creation 
     * US-0006345 START 
     */
        
    @AuraEnabled
    public static List<ServiceAppointment> fetchServiceAppointment(String strObjectName, String strFieldSetName, Id AssetId, String assetaction){                
        
        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        List<ServiceAppointment> lstServiceAppointment = new List<ServiceAppointment>();
        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(! lstFieldsToQuery.isEmpty()){  
            System.debug(AssetId);
            
            if(assetaction == 'YES'){
                String WorkTypeName = '\'PM%\'' ;
                String StatusCompleted = '\'Completed\'';
            	String StatusInProgress = '\'In Progress\'';
            	String StatusDispatched = '\'Dispatched\'';
                String query = 'SELECT Id, Related_Work_Order__r.Asset.Name, Related_Work_Order__r.RecordType.Name, ' + String.join(lstFieldsToQuery, ', ') + ' FROM ServiceAppointment WHERE Related_Work_Order__r.Asset.Id =: AssetId AND WorkType.Name LIKE ' + WorkTypeName + ' AND ((SchedStartTime = LAST_N_MONTHS:20 AND Status = ' + StatusCompleted + ' ) OR (SchedStartTime = NEXT_N_MONTHS:20 AND (Status = ' + StatusCompleted + ' OR Status =  ' + StatusInProgress + '  OR Status =  ' + StatusDispatched + ' ))) ORDER BY status ASC';
                System.debug(query);
                lstServiceAppointment = Database.query(query);
            }
            else {
                String query = 'SELECT Id, Related_Work_Order__r.Asset.Name, Related_Work_Order__r.RecordType.Name, ' + String.join(lstFieldsToQuery, ', ') + ' FROM ServiceAppointment WHERE Related_Work_Order__r.Asset.Id =: AssetId ORDER BY status ASC';
                System.debug(query);
                lstServiceAppointment = Database.query(query);
            }
        }
        return lstServiceAppointment;
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

}