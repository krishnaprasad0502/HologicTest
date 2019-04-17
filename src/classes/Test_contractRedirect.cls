/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate ContractRedirectPage visualforce page
Tests Excecuted:

testRedirect - verifies if the page has redirected as expected. 

History:
<Date>      <Authors Name>    <Brief Description of Change>
10/04/2016  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest
private class Test_contractRedirect{
    
    static testMethod void testRedirect(){
    
        Test.startTest();
        User currentUser = [SELECT Operating_Unit__c from User where Id = :UserInfo.getUserId()];
        Contract c1 = new Contract();
        Apexpages.StandardController stdController = new Apexpages.StandardController(c1);
        contractRedirect conRed = new contractRedirect(stdController);
        conRed.pageRedirect();
        Test.stopTest();
    }
}