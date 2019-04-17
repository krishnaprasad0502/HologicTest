@isTest
private class ResourcePreferenceTriggerActions_Test {

    private static testMethod void testCheckToPreventAction() {
        TestUtility.setupConfigurationSettings();
        TestUtility.insertCustSetting('ResourcePreferenceTrigger');
        Account acc = TestUtility.newAccount('Test Account', null);
        insert acc;
        
        Id profId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        User use = TestUtility.newUser(profId, 'prim');
        insert use;
        
        ServiceResource sres = new ServiceResource();
        sres.Name = 'Test SR';
        sres.RelatedRecordId = use.Id;
        sres.IsActive = true;
        insert sres;
        
        ResourcePreference pref = new ResourcePreference();
        pref.RelatedRecordId = acc.Id;
        pref.ServiceResourceId = sres.Id;
        
        Test.startTest();
        
        //Check to prevent insert
        ResourcePreferenceTriggerActions.overrideUserCheck = true;
        Boolean errorThrown = false;
        
        try {
            insert pref;
        } catch(Exception e){
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown);
        
        //Check to prevent edit
        ResourcePreferenceTriggerActions.overrideUserCheck = false;
        insert pref;
        
        ResourcePreferenceTriggerActions.overrideUserCheck = true;
        errorThrown = false;
        
        try {
            update pref;
        } catch(Exception e){
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown);
        
        //Check to prevent delete
        ResourcePreferenceTriggerActions.overrideUserCheck = true;
        errorThrown = false;
        
        try {
            delete pref;
        } catch(Exception e){
            errorThrown = true;
        }
        System.assertEquals(true, errorThrown);
    }

}