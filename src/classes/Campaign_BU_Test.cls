@isTest (seealldata = true)
public class Campaign_BU_Test {

static testMethod void TestCampaign ()
{
 

 PAM__Business_Unit__c INBU = [Select ID from PAM__Business_Unit__c where Name = 'International' limit 1];
 
 Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
 User u = [Select Id from User where profileId = :p.id limit 1]; 
 
 campaign c = new campaign ();
 c.Name = 'Test Campaign';
 c.Type = 'Email';
 c.ownerid = u.id;
 c.Product_Claim__c = 'Body Contouring';
 c.EndDate = system.today() +365;   
 c.StartDate = system.today();   
 insert c;
 
 campaign cTest = [Select Id, PAM__Business_Unit__c from campaign where id = :c.id];
 
 //System.assertEquals(cTest.PAM__Business_Unit__c,INBU.ID);


 PAM__Business_Unit__c NABU = [Select ID from PAM__Business_Unit__c where Name = 'North America' limit 1];
 Profile p1 = [SELECT Id FROM Profile WHERE Name='Medical Aesthetics Sales User']; 
 User u1 = [Select Id from User where profileId = :p1.id limit 1]; 

campaign c1 = new campaign ();
 c1.Name = 'Test1 Campaign1';
 c1.Type = 'Email';
 c1.ownerid = u1.id;
 c1.Product_Claim__c = 'Body Contouring';
 c1.EndDate = system.today() +365;   
 c1.StartDate = system.today();    
 insert c1;
 
 campaign c1Test = [Select Id, PAM__Business_Unit__c from campaign where id = :c1.id];
 
 //System.assertEquals(c1Test.PAM__Business_Unit__c,NABU.ID);


}

}