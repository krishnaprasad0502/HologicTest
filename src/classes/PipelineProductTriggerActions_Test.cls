/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate PipelineProduct Framework
Tests Excecuted: 

History:
<Date>      <Authors Name>    <Brief Description of Change>
03/15/2019  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest 
private class PipelineProductTriggerActions_Test {

    @isTest
    private static void testCalcAmount() {
        //Setup Test Data
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('PipelineProductTrigger');
        Record_Type_IDs__c rtIds = new Record_Type_IDs__c();
        rtIds.Opportunity_Intl_Breast_Health_Sales__c = GlobalUtility.getRecordTypeId('Opportunity','International_Breast_Health_Sales_Opportunity');
        insert rtIds;
        
        
        Account custAcc = TestUtility.newAccount('Test Customer Account','');
        insert custAcc;
        
        Opportunity opp = TestUtility.newOpportunity('Test Opportunity',custAcc.Id,date.today(),'Close','Expected');
        opp.RecordTypeId = (Id)(String.valueOf(GlobalUtility.getRecordTypeId('Opportunity','International_Breast_Health_Sales_Opportunity')).substring(0,15));
        insert opp; 

        List<Pipeline_Products__c> pipeProdList = new List<Pipeline_Products__c>();
        for(Integer i=0; i<5; i++){
            Pipeline_Products__c pp = new Pipeline_Products__c();
            pp.RecordTypeId = GlobalUtility.getRecordTypeId('Pipeline_Products__c','International_Breast_Health');
            pp.Opportunity__c = opp.Id;
            pp.Volume__c =  100;
            pipeProdList.add(pp);
        }

        insert pipeProdList;

        pipeProdList[0].Volume__c = 50;
        update pipeProdList[0];

        delete pipeProdList[0];


    }
}