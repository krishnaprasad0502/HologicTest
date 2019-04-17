/***************************************************************************
Author:Vrushabh Kataria
Company:Hexaware Technologies
Description: This controller class is used fetch/display/update current logged in User details

History:
<Date>              <Author Name>        <Brief description of change>      <Copa.do US#>
03/01/2018          Vrushabh Kataria     Initial creation                   US-0006454

****************************************************************************/
public class UserProfileDetailController {

    public static User currentUser = [SELECT id,AccountId,ContactId,account.ParentId,Name,Email,CompanyName,City,Extension,Title,
                                      MobilePhone,Phone,PostalCode,State,FirstName,LastName,IsActive 
                                      FROM User 
                                      Where id =: userInfo.getUserId()];
    /*
     * Method Name: fetchUser()
     * Input Param: none
     * Return: User reference 
     * Description: This method is created to return current user record details.
     */
    @auraEnabled
    public static user fetchUser(){
        User oUser = currentUser;
        return oUser;
    }
    
    @auraEnabled
    public static user UpdateUser(Id CurrentUser,String OfficePhone,String Ext,String MobilePhone){
        User U = [Select Id from User where Id=: CurrentUser];
        U.Phone = OfficePhone;
        U.Extension = Ext;
        U.MobilePhone = MobilePhone;
        update U;
        return U;
    }
    
     @auraEnabled
    public static Case SubmitNewCase(){
        Id queueID = [select Id from Group where  Type = 'Queue' AND NAME = 'B&SH Service Admin'].Id;
        Case cs = new Case();
        String caseSubject = system.Label.Community_Profile_Update_CaseSubject;
        cs.Subject = caseSubject;
        cs.Status = 'New';
        cs.Origin = 'Web';
        cs.Type = 'Web';
        cs.Priority = 'Sev 3';
        cs.System_Status__c = 'Up';
        cs.AccountId = currentUser.AccountId;
        cs.ContactId = currentUser.ContactId;
        cs.Customer_Name__c = currentUser.account.ParentId;
        if (queueID != Null)
            cs.OwnerId = queueID;
        insert cs;
        return cs;
    }
    
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
}