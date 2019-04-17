@isTest(seeAllData=true)
private class MARE_Sort_TestMethods
{
    private static testMethod void test1()
    {
        string RecordId = '';
        
        for (Lead l : [SELECT Id FROM Lead LIMIT 1])
        {
            RecordId = l.Id;    
        }
    
        ApexPages.currentPage().getParameters().put('RecordIds', RecordId);
        MARE_Sort controller = new MARE_Sort();
        controller.getSwarmTerritoryOptions();
    }
    
    private static testMethod void test2()
    {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'MARE_INPUT' LIMIT 1];
        string inputJSON = sr.Body.toString();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_SENDREQUEST_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            MARE_Sort.sendMARERequest(inputJSON, 51);
        Test.stopTest();
    }

    private static testMethod void test3()
    {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'MARE_INPUT' LIMIT 1];
        string inputJSON = sr.Body.toString();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_SENDREQUEST_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            MARE_Sort.sendMARERequest(inputJSON, 50);
        Test.stopTest();
    }
        
    private static testMethod void test4()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        string inputJSON = 'mare-us-west-2-routing-32-1543606185.72292-232';
        Test.startTest();
            MARE_Sort.saveMAREJobInfo(inputJSON, 'Test Swarm', st.Id, 51, 'Test Address', 0, 0, 'Test Address', 0, 0, 1);
        Test.stopTest();
    }
    
    private static testMethod void test5()
    {
        list<string> RecordIds = new list<string>();
        
        for (Lead l : [SELECT Id FROM Lead LIMIT 1])
        {
            RecordIds.add(l.Id);   
        }
        
        MARE_Sort.getSalesforceRecords(string.join(RecordIds, ','), 'SELECT Id, Name, Latitude, Longitude FROM Lead');
        
        MARE_Sort.getBaseObjectId();
    }                     
}