/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate DeleteZeroQtyStock trigger
Tests Excecuted:


History:
<Date>      <Authors Name>    <Brief Description of Change>
11/02/2016  Mani Sundaresan      Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_DeleteZeroQtyStock{

     static{
        TestUtility.setupConfigurationSettings();
    }

    static testMethod void deleteRecord(){
    
        Trigger_Switch__c ts = new Trigger_Switch__c();
        ts.Name = 'DeleteZeroQtyStock';
        ts.Active__c = true;
        insert ts;
        
        Account testAccount =  TestUtility.newAccount('Test Account', 'testSite2', 'ABC Street2', null, GlobalUtility.getRecordTypeId('Account', 'Customer'));
        insert testAccount;
        
        FSO__Location__c Location = new FSO__Location__c(Name='Test Location', FSO__Account__c=testAccount.Id, FSO__Geolocation__Latitude__s=26.1700000 , FSO__Geolocation__Longitude__s=-80.2700000);
        insert Location;
        
        FSO__LocationStock__c LocationStock = new FSO__LocationStock__c(FSO__Location__c=Location.Id, FSO__Quantity__c=1);
        insert LocationStock;
        
        LocationStock.FSO__Quantity__c=0;
        update LocationStock;
    }
}