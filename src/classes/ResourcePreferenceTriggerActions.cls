public class ResourcePreferenceTriggerActions {
    
    public static Boolean overrideUserCheck = false;
    
    public static void checkToPreventAction(List<ResourcePreference> prefs){
        List<ResourcePreference> validPrefs = new List<ResourcePreference>();
        for(ResourcePreference pref : prefs){
            if(pref.RelatedRecordId.getSObjectType() == Account.SObjectType){
                validPrefs.add(pref);
            }
        }
        
        if(validPrefs.size() > 0){
            Map<Id, UserRole> fseRoles = new Map<Id, UserRole>([
                SELECT Id
                  FROM UserRole
                 WHERE DeveloperName LIKE '%B_SH_Field_Engineer%'
            ]);
            
            System.debug('overrideUserCheck:'+overrideUserCheck);
            System.debug('userrole:'+fseRoles.keySet().contains(UserInfo.getUserRoleId()));
            
            if(fseRoles.keySet().contains(UserInfo.getUserRoleId()) || overrideUserCheck == true){
                for(ResourcePreference pref : validPrefs){
                    pref.addError('FSEs cannot create, edit or delete Preferred Resources at the Account level, please work with your DSM.');
                }
            }
        }
    }

}