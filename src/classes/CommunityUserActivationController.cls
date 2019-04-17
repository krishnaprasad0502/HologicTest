/********************************************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 01/24/2018 
 	Description  : This class is used as controller to enable /disable the community users. 

    History:
    <Date>         <Author Name>            <Brief Description of Change>    <Copa.do US#>
    01/24/2018	   Sunil					Initial Creation				  US-0006553	
********************************************************************************************************************/
public class CommunityUserActivationController {
	@AuraEnabled
    public static String enableCommunityUser(Id contactId){
        /*try{
            Below piece of code is temporarily commented. Right now for enabing the user email is sent with activation link 
            but in future it can be resumed.
            List<User> userRec = new List<User>([SELECT Id FROM User Where ContactId=: contactId AND isActive =true AND IsPortalEnabled = true LIMIT 1]);
            if(userRec.size() > 0){
                return 'Community User already enabled for the contact.' ;
            }else{
                List<Contact> recContact = new List<Contact>([SELECT Id,firstName,lastName,email FROM Contact WHERE Id=:contactId LIMIT 1]);
                Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User - Customer']; 
                User u = new User();
                u.firstName = recContact[0].firstName;
                u.lastName = recContact[0].lastName;
                u.ContactId = recContact[0].Id;
                u.Username = recContact[0].email;
                u.Email = recContact[0].email;
                u.ProfileId = p.Id;
                u.CommunityNickname = recContact[0].firstName+System.currentTimeMillis();
                u.Alias = recContact[0].lastName.substring(0,6);
                u.TimeZoneSidKey = 'America/Los_Angeles'; // Required
                u.LocaleSidKey = 'en_US'; // Required
                u.EmailEncodingKey = 'ISO-8859-1'; // Required
                u.LanguageLocaleKey = 'en_US'; // Required
                insert u;      
                return 'Success' ;
            }            
        }catch(System.DmlException e){
            return e.getDmlMessage(0);
        }*/
        try{
        OrgWideEmailAddress owa = [SELECT id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName='Hologic Support' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        //List <Contact> Con= [select id, name from Contact where name =:'xx']; 
        mail.setTargetObjectId(contactId); 
        //mail.setSenderDisplayName('Hologic Support'); 
        mail.setUseSignature(false); 
        mail.setBccSender(false); 
        mail.setOrgWideEmailAddressId(owa.id);
        mail.setSaveAsActivity(false); 
        EmailTemplate et=[Select id from EmailTemplate where Name=:'Enable Community User']; 
        mail.setTemplateId(et.id); 
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        return 'Success';
        }catch(Exception e){
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String disableCommunityUser(Id contactId){
        try{
            User u = [SELECT Id, IsActive, IsPortalEnabled FROM User WHERE ContactId =: contactId LIMIT 1];
         	u.IsActive = false;
         	u.IsPortalEnabled = false;
         	update u;
            return 'Success';
        }catch(System.DmlException e){
            return e.getDmlMessage(0);
        }
    }
    
    @AuraEnabled
    public static Boolean checkCommunityUser(Id contactId){
            List<User> userRec = new List<User>([SELECT Id FROM User Where ContactId=: contactId AND isActive =true AND IsPortalEnabled = true LIMIT 1]);
            if(userRec.size() > 0){
                return false ;
            }else{
                return true ;
            }        
    }
}