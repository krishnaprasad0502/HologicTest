@isTest(seeAllData=true)
private class MARE_CheckJob_TestMethods
{
    private static testMethod void test1()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        
        Async_MARE_Job__c amj = new Async_MARE_Job__c();
        amj.Swarm_Name__c = 'Test Swarm';
        amj.Swarm_Territory__c = st.Id;
        amj.Job_Status__c = 'Accepted';
        amj.MARE_Job_Id__c = 'mare-us-west-2-routing-32-1543606185.72292-232';
        amj.Submitted_By__c = UserInfo.getUserId();
        insert amj;
        
        string inputJSON = 'mare-us-west-2-routing-32-1543606185.72292-232';
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_UNFINISHED_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            System.enqueueJob(new MARE_CheckJob (amj.Id));
        Test.stopTest();
    }
    
    private static testMethod void test2()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        
        Async_MARE_Job__c amj = new Async_MARE_Job__c();
        amj.Swarm_Name__c = 'Test Swarm';
        amj.Swarm_Territory__c = st.Id;
        amj.Job_Status__c = 'Accepted';
        amj.MARE_Job_Id__c = 'mare-us-west-2-routing-32-1543606185.72292-232';
        amj.Submitted_By__c = UserInfo.getUserId();
        amj.Size__c = 10;
        insert amj;
        
        string inputJSON = 'mare-us-west-2-routing-32-1543606185.72292-232';
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_FAILED_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            System.enqueueJob(new MARE_CheckJob (amj.Id));
        Test.stopTest();
    }

    private static testMethod void test3()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        
        Async_MARE_Job__c amj = new Async_MARE_Job__c();
        amj.Swarm_Name__c = 'Test Swarm';
        amj.Swarm_Territory__c = st.Id;
        amj.Job_Status__c = 'Accepted';
        amj.MARE_Job_Id__c = 'mare-us-west-2-routing-32-1543606185.72292-232';
        amj.Submitted_By__c = UserInfo.getUserId();
        amj.Size__c = 10;
        insert amj;
        
        string inputJSON = 'mare-us-west-2-routing-32-1543606185.72292-232';
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_COMPLETED_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            System.enqueueJob(new MARE_CheckJob (amj.Id));
            MARE_CheckJob.codeBuffer();
        Test.stopTest();
    }     
    
    private static testMethod void test4()
    {
        Swarm_Territory__c st = [SELECT Id FROM Swarm_Territory__c LIMIT 1];
        
        Async_MARE_Job__c amj = new Async_MARE_Job__c();
        amj.Swarm_Name__c = 'Test Swarm';
        amj.Swarm_Territory__c = st.Id;
        amj.Job_Status__c = 'Failed';
        amj.MARE_Job_Id__c = 'mare-us-west-2-routing-32-1543606185.72292-232';
        amj.Submitted_By__c = UserInfo.getUserId();
        amj.Size__c = 10;
        insert amj;
        
        string inputJSON = 'mare-us-west-2-routing-32-1543606185.72292-232';
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('MARE_FAILED_OUTPUT');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            System.enqueueJob(new MARE_CheckJob (amj.Id));
        Test.stopTest();
    }                 

}