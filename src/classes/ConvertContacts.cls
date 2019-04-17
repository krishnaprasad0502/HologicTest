/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Class which supports the VFPage 'ConvertContacts' to display the list of contacts and save 
                the selected records in AccountProfile object

History:
<Date>          <Authors Name>         <Brief Description of Change>
05/24/2017      Kasmoor Reddy          Initial Creation (US2752)
06/08/2017      Josh Saylor            Updated references for API change to Profile_Data__c
06/09/2017      Kasmoor Reddy          Updated the field values on profile data(US3316)
----------------------------------------------------------------------------------------------------------------*/

public with sharing class ConvertContacts {

    //Variable declarations    
    private Opportunity OppAccID {get; set;}
    private List<AccountContactRelation> ListofACR{get; set;}
    private set<id> SetofAccid;
    private set<id> SetofConid;
    public id[] ContactIds{get; set;}
    public String OppName{get; set;}
    public String Oppassaytype{get; set;}
    public String Oppcompassaytypename{get; set;}
    public String Oppassaytestname{get; set;}
    public list<Profile_Data__c> AccProfiles{get; set;}
    public boolean Render{get; set;}
    public Profile_Data__c AccProfileData{get; set;}
    public id RecordID{get; set;}
    public Opportunity Opprec { get; set; }
    public boolean disablesave{get;set;}
    public List<ContactWrapper> lstWrapper {get;set;}
    public List<ContactWrapper> lstSetController{get;set;}
    CustomIterable obj;
    Public id Oppid{get;set;}
    public Set<id> contactidstoinsert {set;get;}
    /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Constructor for Variable initializion and fetching the contacts 
                 to display on the intial load of VF Page
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    05/24/2017      Kasmoor Reddy              Initial Creation (US2752)
    06/08/2017      Josh Saylor                Updated references for API change to Profile_Data__c
    06/09/2017      Kasmoor Reddy              Updated the field values on profile data(US3316)
-----------------------------------------------------------------------------------*/
    public ConvertContacts(ApexPages.StandardController controller) {
        
        //Variable instantiation
        ContactIds = new id[]{};
        SetofAccid = new set<id>();
        SetofConid = new set<id>();
        Render = false;
        disablesave = true;
        AccProfileData =new Profile_Data__c();
        contactidstoinsert=new Set<id>();
        //Fetching the recordtyprId of Physician Conversion
        RecordID = GlobalUtility.getRecordTypeId('Profile_Data__c', 'Physician_Conversion'); 
        
        //Assigning the record type and auto-populating the field on the VF page
        AccProfileData.RecordtypeId = RecordID;
        AccProfileData.Division__c = 'Diagnostics | Physician';
        AccProfileData.Type__c = 'Conversion';
        
        
        
        //fetching the Opportunity record 
        this.Opprec  = (Opportunity) controller.getRecord();
        
        //fetching the Account related to the Opportunity
        OppAccID = [SELECT AccountId,Account_Site__c,Assay_Type__c,Competitive_Assay_Test_Name__c,Assay_Test_Name__c,name FROM Opportunity where id =: Opprec.id];
        SetofAccid.add(OppAccID.AccountId);
        SetofAccid.add(OppAccID.Account_Site__c);
        //Variable used to display the Opportunity name on the VF Page
        OppName= OppAccID.name;
        Oppid = OppAccID.Id;
        Oppassaytype = OppAccID.Assay_Type__c;
        Oppcompassaytypename = OppAccID.Competitive_Assay_Test_Name__c;
        Oppassaytestname = OppAccID.Assay_Test_Name__c;
        //06/09/2017  added by Kasmoor Reddy to update the field values on profile data with opportunity assay type values(US3316)
        AccProfileData.Conversion_Assay_Type__c = Oppassaytype;
        AccProfileData.Converted_From__c = Oppcompassaytypename;
        AccProfileData.Converted_To__c = Oppassaytestname;
        //End of code(US3316)
        
        //fetching the AccountContactRelation records related to the Account
        ListofACR= new List<AccountContactRelation>();
        if(Opprec!=null){
            ListofACR = [SELECT id, ContactId FROM AccountContactRelation where accountid IN: SetofAccid LIMIT 25]; 
            if(ListofACR.size()>0){
                for(AccountContactRelation ACR: ListofACR){ 
                    SetofConid.add(ACR.ContactId);
                } 
            }
        }       
        
         lstWrapper =  new List<ContactWrapper>();
         lstSetController = new List<ContactWrapper>();
        //Passing Contacts to the Wrapper
         List<Contact> lstContact = [SELECT Accountid, name, Description from Contact where accountid IN: SetofAccid];
        system.debug('lstContact====='+lstContact.size()); 
        for(Contact cont : lstContact )
        {
            lstWrapper.add(new ContactWrapper(cont ,false));
        }
        system.debug('lstWrapper===='+lstWrapper.size());
        obj = new CustomIterable (lstWrapper); 
        obj.setPageSize = 10;
        next();    
        
    }
//Setting the boolean value for next page    
 public Boolean hasNext {
  get 
  {
     return obj.hasNext();
  }
  set;
 }
 //Setting the boolean value for previous page       
 public Boolean hasPrevious {
  get 
  {
     return obj.hasPrevious();
  }
  set;
 }
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Setting the next count of records to display in pagination.
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    05/24/2017     Kasmoor Reddy        Initial Creation (US2752)
-----------------------------------------------------------------------------------*/        
public void next() 
 {
     
     for (ContactWrapper w: lstSetController ){
            
            if(w.isSelected != false){
                contactidstoinsert.add(w.cont.id);
                
            }
         }
     
    lstSetController = obj.next();
     
 }
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Setting the previous count of records to display in pagination.
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    05/24/2017     Kasmoor Reddy        Initial Creation (US2752)
-----------------------------------------------------------------------------------*/         
public void previous() 
 {
     for (ContactWrapper w: lstSetController ){
            
            if(w.isSelected != false){
                contactidstoinsert.add(w.cont.id);
                
            }
         }
     
    lstSetController = obj.previous();
    
 }
    
 /*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which executes on click of the button 'Next' on the VF Page
                 and it stores the list of selected contacts
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    05/24/2017     Kasmoor Reddy       Initial Creation (US2752)
-----------------------------------------------------------------------------------*/
    
    //Storing the extracted contacts
     public Void Nextpage(){
        
         for (ContactWrapper w: lstSetController ){
             system.debug('ContactWrapper' + w);
            if(w.isSelected != false){
                contactidstoinsert.add(w.cont.id);
                
            }
         }
        ContactIds.addAll(contactidstoinsert);
        Render = true; 
     }
     
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which executes on click of the button 'Back To Opportunity'
                 on the VF page and re-directs to the Opportunity
    Returns:     Opportunity page reference
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    05/24/2017     Kasmoor Reddy        Initial Creation (US2752)
-----------------------------------------------------------------------------------*/
     //Back to the Opportunity record
     public pagereference back(){
        Pagereference PageRef = new pagereference('/' + Opprec.id);
        PageRef.setRedirect(true);
        return PageRef;
    }
    
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method which executes on click of the button 'Save' on the VF Page,
                 it considers the selected contacts and the values assigned to the fields 
                 displayed on VF Page and then inserts the records in the 
                 Profile_Data__c object against the number of selected contacts
    Returns:     N/A
      
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/24/2017      Kasmoor Reddy       Initial Creation (US2752)
    06/08/2017      Josh Saylor         Updated references for API change to Profile_Data__c
-----------------------------------------------------------------------------------*/
    //Save the records for each selected contact with the values given in the VF page
    public void Save(){  
        AccProfiles = new list<Profile_Data__c>();
        system.debug('ContactIds===='+ContactIds.size());
        if(ContactIds.size()!=0){
            
                for(Integer i=0; i<ContactIds.size(); i++){
                    Profile_Data__c AP = new Profile_Data__c();
                    AP.Contact__c  = ContactIds[i];
                    AP.RecordtypeId = RecordID;
                    AP.Division__c = AccProfileData.Division__c ;
                    AP.Type__c = AccProfileData.Type__c ;
                    //06/09/2017  added by Kasmoor Reddy to update the field values on profile data with opportunity assay type values(US3316)
                    AP.Conversion_Assay_Type__c = AccProfileData.Conversion_Assay_Type__c;
                    AP.Converted_From__c=  AccProfileData.Converted_From__c;
                    AP.Converted_To__c= AccProfileData.Converted_To__c;
                    //End of code (US3316)
                    AP.Primary_Lab_Affiliation__c=AccProfileData.Primary_Lab_Affiliation__c;
                    AP.Secondary_Lab_Affiliation__c=AccProfileData.Secondary_Lab_Affiliation__c;
                    AP.Date__c=AccProfileData.Date__c;
                    AP.Description__c=AccProfileData.Description__c;
                    Ap.Opportunity__c = Oppid;
                    Accprofiles.add(AP);
                }
                system.debug('Accprofiles======='+Accprofiles.size());
                If(Accprofiles.size()>0){
                try{
                    Insert Accprofiles;
                    AccProfileData=null;
                    //display success message after the records are saved in the Account Profile object
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'All the contacts have been inserted as Account Profiles!'));
                }catch(DMLException e){
                    //display error message after the records are saved in the Account Profile object
                   
                    ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.Warning, e.getmessage() )); 
                }    
             } 
        }
        disablesave = false;
    }
    
     
}