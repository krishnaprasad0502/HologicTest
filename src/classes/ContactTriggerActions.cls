/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Apps Associates
Description:    Contact Trigger functions
Test Class:     ContactTrigger_Test

History:
<Date>          <Authors Name>      <Brief Description of Change>
12/05/2018      Kasmoor Reddy        Initial Creation (US6207)
------------------------------------------------------------*/
public class ContactTriggerActions {
    
    /*------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Capitalizing the Firstname and Lastname on contact

History:
<Date>          <Authors Name>      <Brief Description of Change>
12/05/2018       Kasmoor Reddy       Initial Creation
------------------------------------------------------------*/
    public static void capitalizeContactName(List<Contact> contacts, Map<Id, Contact> oldMap){
       
        Configuration_Settings__c customSetting = Configuration_Settings__c.getInstance(UserInfo.getProfileId());

        //Configuration_Settings__c customSetting = [Select  Contact_Trigger_Actions__c from Configuration_Settings__c where SetupOwnerId =: UserInfo.getProfileId()]; 
        if(customSetting.Contact_Trigger_Actions__c!=true) 
        {
            String Firstname;
            String Lastname;
            String MiddleName;
            for(Contact con: contacts){
                
                //Contact old = oldMap.get(con.Id);
                if(con.LastName != null || con.FirstName != null||con.MiddleName!=null){
                    Firstname = con.FirstName;
                    Lastname = con.LastName;
                    MiddleName=con.MiddleName;
                    system.debug(Firstname);
                    system.debug(Lastname);
                }
                if(Firstname != null || Lastname != null || MiddleName!=null){
                    String first = Firstname;
                    if(first!=null)
                    {
                        List<String> firstnamewords = first.split(' ');
                        first = '';
                        if(firstnamewords.size()>0)
                            for(String x : firstnamewords){
                                if(x.Length()>=1)
                                    first += x.substring(0,1).toUpperCase()+x.substring(1,x.length()).toLowerCase() + ' ';
                                
                                system.debug(first);
                            }
                        con.FirstName = first;
                    }
                    String last = Lastname;
                    if(last!=null)
                    {
                        List<String> lastnamewords = last.split(' ');
                        last = '';
                        if(lastnamewords.size()>0)
                            for(String y : lastnamewords){
                                if(y.Length()>=1)
                                    last += y.substring(0,1).toUpperCase()+y.substring(1,y.length()).toLowerCase() + ' ';
                                
                                system.debug(last);
                            }
                        con.LastName = last;
                    }
                    String middle = MiddleName;
                    if(middle!=null)
                    {
                        List<String> Middlenamewords = middle.split(' ');
                        middle = '';
                        if(Middlenamewords.size()>0)
                            for(String z : Middlenamewords){
                                if(z.Length()>=1)
                                    middle += z.substring(0,1).toUpperCase()+z.substring(1,z.length()).toLowerCase() + ' ';
                                
                                system.debug(middle);
                            }
                        con.MiddleName = middle;
                    }
                }  
            } 
        } 
    }
}