@isTest(seeAllData = True)
private class updateServiceAppointment_Test{

    static testMethod void testScheduler(){
        Test.startTest();
        updateServiceAppointment scheduledJob = new updateServiceAppointment();     
        String sch = '0 0 0 * * ?';
        String jobId = System.schedule('Test Schedule', sch, scheduledJob);
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }
    
    static testMethod void testBatch(){
        
        Test.startTest();
        Database.executeBatch(new updateServiceAppointment());    
        Test.stopTest();   
    }
}