/*--------------------------------------------------------------------------------------------------
Author:      Mani Sundaresan
Description:  Test class to validate CDAccess Trigger
Tests Excecuted:


History:
<Date>      <Authors Name>    <Brief Description of Change>
12/22/2016  Mani Sundaresan   Initial Creation
---------------------------------------------------------------------------------------------------------*/
@isTest(seeAllData = True)
private class test_CDAccess{

    static testMethod void testContentDocInsert(){
        
        
        ContentVersion doc = new ContentVersion();
        string before = 'Testing ContentDocument'; 
        Blob beforeblob = Blob.valueOf(before);
        doc.Title = 'ServiceReport';
        //doc.PathOnClient = title;
        doc.ContentUrl = ApexPages.currentPage().getHeaders().get('Host')+'/06961000000zl0C';
        //doc.VersionData = beforeblob;
        doc.FirstPublishLocationID = UserInfo.getUserId();
        
        Test.startTest();
        insert doc; 
        Test.stopTest();
        
    }
}