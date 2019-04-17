@isTest(seeAllData = True)
public class AccountBatchTest {

    static testmethod void testAccountUpdate() {

        //TestUtility.setupConfigurationSettings();

        Account acc1 = TestUtility.newAccountWithAddresses('Account1', null, GlobalUtility.getRecordTypeId('Account', 'Customer'), '123 Main Street', 'Boston', 'Massachusetts', 'United States', '02111', '123 Main Street', 'Boston', 'Massachusetts', 'United States', '02111');
        insert acc1;
        
        
        List<Territory2> thisTerritory = [select Id, DeveloperName, Name from Territory2 where DeveloperName = 'MA09_New_York'];

        ObjectTerritory2Association ota = new ObjectTerritory2Association();
        ota.ObjectId = acc1.Id;
        ota.Territory2Id = thisTerritory[0].Id;
        ota.AssociationCause = 'Territory2Manual';
        insert ota;

        Test.startTest();
        AccountBatch acctBatch = new AccountBatch();
        String sch = '00 01 * * * ?';
        String jobID = System.schedule('Account Updates', sch, acctBatch);
        Test.stopTest();
    }
}