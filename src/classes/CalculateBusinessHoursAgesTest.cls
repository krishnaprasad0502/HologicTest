@isTest
public class CalculateBusinessHoursAgesTest {

    /*private static Configuration_Settings__c orgDefaults;
    private static Account parentAccount;
    
    static{
        //orgDefaults = TestUtility.setupConfigurationSettings();
        
        parentAccount = TestUtility.newAccount('Parent Account', null, null); 
        insert parentAccount;   
    }*/
    
    public static testMethod void testBusinessHoursBucketer() {
         // 13/09/2017-Krishna Prasad-Added trigger switch to fix case Trigger isuue     
        TestUtility.insertCustSetting('CaseTrigger'); 
        Stop_Status__c ss = new Stop_Status__c(Name = 'On Hold');
        insert ss;
        
        
        
        //Case c = new Case();
        Case c = TestUtility.newCase(null, null, null, null, GlobalUtility.getRecordTypeId('Case', 'B_SH_Connectivity'), 'Applications', 'New', 'Low', 'Phone');
        //c.Status = 'New';
        c.Last_Status_Change__c = System.Now();
        //c.RecordTypeId = GlobalUtility.getRecordTypeId('Case', 'B_SH_Service');
        insert c;
        
        Test.startTest();
        c.Status = 'On Hold';
        update c;

        c.Status = 'New';
        update c;

        Case updatedCase = [select Time_With_Customer__c,Time_With_Support__c,Case_Age_In_Business_Hours__c from Case where Id=:c.Id];
        System.assert(updatedCase.Time_With_Customer__c!=null);
        System.assert(updatedCase.Time_With_Support__c!=null);
        System.assert(updatedCase.Case_Age_In_Business_Hours__c==null);

        c.Status = 'Closed';
        update c;
        Test.stopTest();
        
        updatedCase = [select Time_With_Customer__c,Time_With_Support__c,Case_Age_In_Business_Hours__c from Case where Id=:c.Id];

        System.assert(updatedCase.Time_With_Customer__c!=null);
        System.assert(updatedCase.Time_With_Support__c!=null);
        System.assert(updatedCase.Case_Age_In_Business_Hours__c!=null);
    }
}