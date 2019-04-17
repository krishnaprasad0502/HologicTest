/***************************************************************************************************
Author       : Vrushabh Katariya
Company      : Hexaware Technologies
Created Date : 11/05/2018 2:39 AM
Description  : Test class - CommunitySelfRegistrationReqTrigger_Test    


History:
<Date>          <Author Name>                   <Brief Description of Change>   <Copa.do US#>
11/05/2018      Vrushabh Katariya               Initial Creation                US-0006075
11/05/2018      Niraj Wani                      Duplicate Validation Change     US-0006075
11/13/2018        Vrushabh katariya    Updated timezone code            US-0006062
12/27/2018      Nomita Walke            Updated code for profile assignment     US-0006345
***************************************************************************************************/
public class CommunitySelfRegistrationTriggerHandler {
    
    public static void onBeforeUpdate(List<Community_Self_Registration_Request__c> SelfRegistrationRequest ,  Map<Id, Community_Self_Registration_Request__c> mapOldSelfRegistrationRequest) {
    Boolean isActive = GlobalUtility.isTriggerActive('CommunitySelfRegistrationTrigger');
    
    if(isActive){
        List<Community_User_Mapper__mdt> CommunityObjectMapper = new List<Community_User_Mapper__mdt>();
        CommunityObjectMapper = [SELECT Id, MasterLabel, DeveloperName, Community_Destination_API__c, Community_Destination_Object_Type__c, 
                                 Community_Source_API__c FROM Community_User_Mapper__mdt];
        system.debug('The list contains: '+CommunityObjectMapper);
        
        //Get profile details from the community registration.
        Schema.DescribeFieldResult fieldResult = Community_Self_Registration_Request__c.Community_Profile__c.getDescribe();
        List<Schema.PicklistEntry> listProfileVal = fieldResult.getPicklistValues();
        Set<String> setProfileNames = new Set<String>();
        for( Schema.PicklistEntry pickListVal : listProfileVal ){
            setProfileNames.add(pickListVal.getLabel());
        }
        //query the profile
        List<Profile> listProfile = [select Id,Name from Profile where Name in: setProfileNames];
        for(Community_Self_Registration_Request__c commUser : SelfRegistrationRequest) {
            // Access the "old" record by its ID in Trigger.oldMap
            Community_Self_Registration_Request__c oldReq = mapOldSelfRegistrationRequest.get(commUser.Id);
            //Check if Old Status was not Approved and Current Status is Approved         
            if (oldReq.Community_Status__c != 'Approved' &&  commUser.Community_Status__c == 'Approved')
            { 
                //Validate if the Account is blank. 
                if (commUser.Community_Contact__c == null && commUser.Community_Account__c == null && commUser.Community_Customer_Account__c == null)
                {
                    System.debug('Validation Failed');
                    commUser.AddError (System.Label.Community_User_Request_Approval_Validation);
                }
                else 
                { 
                    //Set DMLOptions so that email gets triggered to community user for password reset
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.EmailHeader.triggerUserEmail = true;
                    dmo.DuplicateRuleHeader.allowSave = true;
                    dmo.DuplicateRuleHeader.runAsCurrentUser = true;
                    //Prepare Community User Object 
                    Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
                    //String queryProfile = 'SELECT Name, Id From Profile Where Name = \'' + config.Community_Profile_Name__c  + '\'';
                    //Profile p = Database.query(queryProfile);
                    User u = new User();
                    for(Community_User_Mapper__mdt mapper : CommunityObjectMapper){
                        if(mapper.Community_Destination_Object_Type__c == 'User'){
                            u.put(mapper.Community_Destination_API__c,commUser.get(mapper.Community_Source_API__c));
                        }
                    }
                    system.debug('Test User :'+u);
                    // Below line is commented as Timezone need not be hardcoded.
                    //u.TimeZoneSidKey = 'GMT';
                    u.LanguageLocaleKey = 'en_US';
                    u.LocaleSidKey = 'en_US';
                    u.EmailEncodingKey='ISO-8859-1';
                    //u.ProfileId = p.Id;
                    for(Profile prof : listProfile){
                        if(commUser.Community_Profile__c == prof.Name){
                            u.ProfileId = prof.Id;
                        }
                    } 
                    
                    //Prepare Nickname 
                    String firstname = u.FirstName;
                    String lastname = u.LastName;
                    String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
                    nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
                    
                    u.put('CommunityNickname', nickname);
                    u.put('Alias',nickname);  
                    String email = u.Email;
                    String accountId = '';
                    String Company = u.CompanyName;
                    list<Contact> Contacts = new list<Contact>();
                    list<Account> accounts = new list<Account>();
                    
                    //Get Self Registration Account 
                    accounts = [Select Id from Account Where Name = 'Self Registration Account'];
                    if (accounts != Null && accounts.size() > 0)
                        accountId = accounts[0].Id;
                    //Check if Contact already exists 
                    if (commUser.Community_Contact__c != Null){
                        // Contact Exists 
                        u.ContactId = commUser.Community_Contact__c;    
                        u.setOptions(dmo);
                        insert u;
                        commUser.Community_User__c = u.Id;
                    }
                    else
                    {  
                        Contact cnt = new Contact();
                        for(Community_User_Mapper__mdt mapper : CommunityObjectMapper){
                            if(mapper.Community_Destination_Object_Type__c == 'Contact'){
                                cnt.put(mapper.Community_Destination_API__c,commUser.get(mapper.Community_Source_API__c));
                            }
                        }
                        //Assign Account from custom object - Service Admins will have ability to select account from lookup
                        //This will avoid new contact being created for Registration Account 
                        if (commUser.Community_Account__c != Null)
                            cnt.AccountId = commUser.Community_Account__c;
                        else 
                            cnt.AccountId = accountId; 
                        
                        //insert cnt;
                        Database.SaveResult sr = Database.insert(cnt, dmo);
                        u.ContactId = cnt.Id;
                        u.setOptions(dmo);
                        insert u;
                        // userId = u.Id;
                        commUser.Community_Contact__c = cnt.Id;
                        commUser.Community_User__c = u.Id;                       
                    } 
                    
                    //Add Note on Contact - The note will get added on new contact as well existing contact in scenario where contact already exists
                    String noteStr = '';
                    Note userNote = new Note();
                    userNote.ParentId = u.ContactId;
                    noteStr = String.format(Label.Community_User_Case_Note, new List<String>{firstname, lastname, String.valueOf(commUser.CreatedDate) });
                    userNote.Body = noteStr;
                    userNote.Title = 'New Community User - T&C Acceptance';
                    insert userNote;  
                    system.debug('The User Id is: '+ u.id);
                }
            }
        }//Trigger For  
    }//IsActive
    }
}