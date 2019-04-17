/********************************************************************************************
Author:Vrushabh Katariya
Company:Hexaware Technologies
Description: Controller class for ServiceReportSummaryView component. 

TestClass: ServiceReportSummaryViewControllerTest
Code Coverage:  100

History:
<Date>              <Author Name>        	<Brief description of change >   <Copa.do US#>
11/15/2018			Vrushabh Katariya		Initial Creation				  US-0006170
*********************************************************************************************/
public class ServiceReportSummaryViewController {

    @AuraEnabled
    public static ServiceAppointment getServiceAppointment(Id objectRecordId){
        ServiceAppointment SARecord = [SELECT id,Community_Service_Report_ID__c,Community_Service_Report_Link__c,
                                       ParentRecordId, Related_Work_Order__c, SchedStartTime, SchedEndTime
                                       FROM ServiceAppointment WHERE id =: objectRecordId];   
        return SARecord;
    }
}