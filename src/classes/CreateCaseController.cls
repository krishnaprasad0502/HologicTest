/*------------------------------------------------------------
Author:         Amarendra Nagireddy
Company:        AppsAssociates 
Description:    Create case from Account or Asset
Class Name:     CreateCaseController          
Test Class:     CreateCaseController_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
4/7/2017        Mani Sundaresan          Initial Creation(US-0001634)
4/13/2017       Amarendra Nagireddy      Added validation logic to check for existing contact based on email address, email 
                                         address validation while creating new contact if not exist in system as part of US-0002746
4/27/2017       Amarendra Nagireddy      Added logic to set the recordtype id for case creation as part of US-0002746
5/22/2017       Amarendra Nagireddy      Consolidated code for the case creation process from Account/Asset as part of US-0002746, US-0002765
                                         Added exception handling while inserting contact, case
                                         Modified logic to update case only if note type =Problem description
                                         Added exception handling for insert task, update case
05/29/2017     Amarendra Nagireddy       Added logic to reset selected contact
06/29/2017     John Christy              Fixed Defect #437 - Asset not carrying over Bill To/Ship To Customer name/address
11/28/2017     John Christy              Fixed Help Me HD-7256 - Remove H1 Contacts from customer Case creation VF page
2/27/2018      Kasmoor Reddy             Modified the code to associate the account to contact as part of US-0004018 
------------------------------------------------------------*/
public class CreateCaseController{
    public Asset asst;
    public string accountid;
    public string getaccountid;
    //5/22/2017(Amarendra Nagireddy)-Declared variables to get object name, record id (US-0002746,US-0002765)
    public string Recordid;
    public String ObjName;
    public Contact cont;
    //public Case caseobj {get;set;}
    public string recSelected {get;set;}
    // the soql without the order and limit
    private String soql {get;set;}
    // the collection of contacts to display
    public List<Contact> contacts {get;set;}
    // variable containing the selected contact
    public String selectedContact {get;set;}
    
    //variable containing the Configuration Settings
    public Configuration_Settings__c configSetting;
    public Set<id> AccountSet = new Set<id> ();
    
    public String selectedCaseType {get;set;}
    // case object to contain case variables
    public Case newCase = new Case();
    // Variable that get the new case
    public Case getnewCase()
    {
        return newCase;
    }
    // Variable that set the new case
    public void setnewCase(Case newCase)
    {
        this.newCase = newCase;
    }
    // variable containing the id of the Asset
    public String assetId;
    // offset variable used for pagination
    public Integer pagination = 0;
    //varible to hold the total contact returned
    public Integer contactCount{get;set;}
    
    String firstName;
    String lastName;
    public String accountName {set;get;}
    public String customeraccount {set;get;}
    String email;
    String phone;
    String extension;
    string addiphone;
    string addiextension;
    String role;
    //Method to get value for pagination
    public Integer getPagination(){
        return pagination;
    }
    //Method to set value for pagination
    public void setPagination(Integer pagination){
        this.pagination = pagination;
    }
    
    // variable containing total contact
    public Integer totalContact {get; set;}
    // variable to clear the pagination value
    public Boolean clearPagination = true;
    // task wrapper variable
    public List<wrapperTaskList> waTaskList {get;set;}
    public Integer rowToRemove {get;set;}
    public String selectedNoteType {get;set;}
    public List<SelectOption> statusOptions { get;set; }
    
    //08/08/2017(Amarendra Nagireddy)-Declared variables to allow contact duplication
     private List<sObject> duplicateRecords;
     public boolean hasDuplicateResult{get;set;}
     public String createduplicatecontact {get;set;}
     
     

   //wrapper class variables
    public class wrapperTaskList{
    public Integer index {get;set;}
    public Task record {get;set;}
    public string noteType {get;set;}
        
    }
    /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    A script to reset the user selected contact
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    05/29/2017      Amarendra Nagireddy     Initial Creation(US-0002746)
    ------------------------------------------------------------*/
    public void clearselectedcontact()
    {
        selectedContact=null;

    }
    /*------------------------------------------------------------
    Author:         Amarendra Nagireddy
    Company:        Apps Associates
    Description:    A script validate the user entered email address. If email is not valid, it will retrun false
    Inputs:         string 
    Returns:        boolean
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    04/13/2017      Amarendra Nagireddy     Initial Creation(US-0002746)
    ------------------------------------------------------------*/
public static Boolean validateEmail(String email) {
    Boolean res = true;
    String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
    Pattern MyPattern = Pattern.compile(emailRegex);
    Matcher MyMatcher = MyPattern.matcher(email);
         if (!MyMatcher.matches())
         {
            res = false;
         }
      return res; 
    }
  /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Apps Associates
    Description:    Getting the selected extension,role,addiphone and
                    addiextension from  vf page 
    Inputs:         string 
    Returns:        boolean
    
    History:
    <Date>          <Authors Name>         <Brief Description of Change>
    08/09/2016      Mani Sundaresan         Initial Creation(US-0001634)
    04/27/2017    Amarendra Nagireddy       get additional fields that are added to the contact search layout.
                                          added fields are addiphone,addiextension
    ------------------------------------------------------------*/
  public void setSelectedContact(){
      extension = Apexpages.currentPage().getParameters().get('extension');
      role=Apexpages.currentPage().getParameters().get('role');
      //added additional fields to contact search layout
      addiphone=Apexpages.currentPage().getParameters().get('addiphone');
      addiextension=Apexpages.currentPage().getParameters().get('addiextension');
  }
  /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    Setting the value for the field complaint on case.
    Inputs:         string 
    Returns:        boolean
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    08/09/2016      Mani Sundaresan     Initial Creation(US-0001634)
    ------------------------------------------------------------*/
  public void setCaseComplaint(){
      if(newCase.Type == 'Issue' || newCase.Type == 'Service')
          //newCase.Patient_Impact__c = 'Yes';
          newCase.Complaint__c = 'Yes';
  }
  
  /*public void testCheckBox(){
  System.debug('PO Cap:'+newCase.PO_Cap__c);
  System.debug('PO Number:'+newCase.PO_Number__c);
  }*/
  
  //to get the total count of contact
  public void getTotalContact(){
         //09/20/2017      krishna prasad  return all values from AccountId or asset related account (custom settings)Instance
                 
        totalContact = [SELECT Count() from Contact where AccountId IN: AccountSet   ]; 
    }
  //to set the next link pagination count of contact.
  public void setNext(){
      if(pagination < totalContact)
          pagination += 10;
      else
          pagination = totalContact;
       runQuery();
  }
  //to set the previous link pagination count of contact
  public void setPrevious(){
      if(pagination != 0)
          pagination -= 10;
      else
          pagination = 0; 
       runQuery();
  }
  

  // the current sort direction. defaults to asc
  public String sortDir {
    get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
    set;
  }

  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) {sortField = 'lastName'; } return sortField;  }
    set;
  }
    /*  // format the soql for display on the visualforce page
  public String debugSoql {
    
    get { return soql + ' order by ' + sortField + ' ' + sortDir + ' limit 10 OFFSET ' +pagination; }
    set;
  }*/

    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    init the controller and display some sample data when the page loads
                     
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>         <Brief Description of Change>
    4/7/2017         Mani Sundaresan       Initial Creation(US-0001634)
    4/27/2017        Amarendra Nagireddy   Get record type id from URL that is selected from the caserecordtypeselect page and 
                                           set to the case intiated to get field values based on record type.
                                           Edited contact search query to search contacts based on account and customer account fields. 
    5/22/2017       Amarendra Nagireddy     Consolidated code to fetch contact details based on object type, record id values. 
    
    5/29/2017       Amarendra Nagireddy    Fetch product detail from asset and map it to case.
    06/29/2017     John Christy              Fixed Defect #437 - Asset not carrying over Bill To/Ship To Customer name/address   
    2/27/2018      Kasmoor Reddy             Modified the code to associate the account to contact as part of US-0004018                                          
   ------------------------------------------------------------*/
  public CreateCaseController() {
  
  contactCount=0;
   //09/20/2017      krishna prasad  return all values from Configuration_Settings__c (custom settings)Instance
    configSetting = Configuration_Settings__c.getInstance(); 
        
         
  //4/27/2017(Amarendra Nagireddy)Get case recordtype id from URL and map to case initiated 
  recSelected = Apexpages.currentPage().getParameters().get('RecordType'); 
  newCase.RecordTypeId=recSelected;
  waTaskList = new List<wrapperTaskList>();
    
  addNewRowToTaskList();
  statusOptions = new list<SelectOption>();
  statusOptions.add(new SelectOption('null','--None--'));
    //Getting the NoteType values from custom setting
  for(NoteType__c nt : NoteType__c.getAll().values())
      statusOptions.add(new SelectOption(nt.Note_Type__c,nt.Note_Type__c));
    
    //5/22/2017(Amarendra Nagireddy)-Get object type and record id from page parameters
   Recordid = Apexpages.currentPage().getParameters().get('aId');
   ObjName  =  Apexpages.currentPage().getParameters().get('objname');
   system.debug(Recordid);
   system.debug(ObjName);
    
    //5/22/2017(Amarendra Nagireddy)-Fetching account details associated with the corresponding Account/Asset
    if(Recordid != null && Objname=='Asset')
    {
        assetId=Recordid;
        //05/29/2017(Amarendra Nagireddy)-Fetch product details
        //06/29/2017(John Christy) - added install/ship/bill locations/account.name to query and newCase.insert
        asst = [Select Id, AccountId, Account.Name, Customer_Account__c, Customer_Account__r.name, Product2id,
                Install_Location__c, Install_Location__r.Account__r.Parent.Id,
                Ship_To_Location__c, Ship_To_Location__r.Account__r.Parent.Id,
                Bill_To_Location__c, Bill_To_Location__r.Account__r.Parent.Id
                from Asset 
                where Id = :Recordid];
        getaccountid=asst.AccountId;
        system.debug('Initail account id:::'+asst.AccountId);
        system.debug('Initail account id:::'+getaccountid);
        newCase.AccountId = asst.AccountId;
        newCase.Customer_Name__c = asst.Customer_Account__c;
        newCase.Bill_to_Site_Location__c = asst.Bill_To_Location__c;
        newCase.Bill_to_Customer__c  = asst.Bill_To_Location__r.Account__r.Parent.Id;
        newCase.Ship_to_Site_Location__c = asst.Ship_To_Location__c;
        newCase.Ship_to_Customer__c = asst.Ship_To_Location__r.Account__r.Parent.Id;
        newCase.Install_Location__c = asst.Install_Location__c; 
        newCase.Install_Customer__c = asst.Install_Location__r.Account__r.Parent.Id;
        //5/29/2017(Amarendra Nagireddy)-Map Asset and Product details to case.if user creating case from asset 
        newCase.AssetId=asst.id;
        newcase.ProductId=asst.Product2id;
        accountName=asst.Account.Name;
        customeraccount=asst.Customer_Account__r.name;
        
        
        if(Asst.Accountid != null){
        AccountSet.add(Asst.Accountid);         
        }
        if(Asst.Customer_Account__c != null){
        AccountSet.add(Asst.Customer_Account__c);
        }
          /* // 11/28/2017 (John Christy) Excluded Default Hologic Accounts from contact list (HD-7256)
        if(configSetting.Return_Default_Account__c != null){
         AccountSet.add(configSetting.Return_Default_Account__c);
        }
        if(configSetting.Return_Default_Customer_Account__c!= null){
            AccountSet.add(configSetting.Return_Default_Customer_Account__c);             
        }
         */      
    }
      else if(recordid != null && Objname=='Account')
      {
          Account acc=[select id,name,Parentid,Parent.name from account where id=:recordid];
          system.debug(recordid);
         /*Modified the code to associate the account to contact by Kasmoor Reddy on 2/27/2018  as part of US-0004018 */
          /* getaccountid=accountid;*/
          getaccountid=acc.id;
           system.debug('Initail account id:::'+getaccountid);
          newCase.AccountId = recordid;
          newCase.Customer_Name__c = acc.Parentid;
          accountName=acc.name;
          customeraccount=acc.Parent.name;
          
          if(acc.id != null){
              AccountSet.add(acc.id);         
          }
          if(acc.Parentid != null){
              AccountSet.add(acc.Parentid);
          }
          
          /* // 11/28/2017 (John Christy) Excluded Default Hologic Accounts from contact list (HD-7256)
          if(configSetting.Return_Default_Account__c != null){
              AccountSet.add(configSetting.Return_Default_Account__c);
          }
          if(configSetting.Return_Default_Customer_Account__c!= null){
              AccountSet.add(configSetting.Return_Default_Customer_Account__c);             
          }
          */
      }
      //4/27/2017(Amarendra Nagireddy)If account and customer account are null, then display all the contacts, if not null display only corresponding contacts
      if(AccountSet.size()>0)
      {
          soql = 'select firstname, lastname, account.name, phone, email, name from contact where AccountId IN: AccountSet';
      }
      
      
      runQuery();
    
     //08/08/2017(Amarendra Nagireddy)-Initialize empty list of potential duplicate records
        this.duplicateRecords = new List<sObject>();
        this.hasDuplicateResult = false;
        
  }//End of constructor
    
    //08/08/2017(Amarendra Nagireddy)-Return duplicate records to the Visualforce page for display
    public List<sObject> getDuplicateRecords() {
        return this.duplicateRecords;
    }
  /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    toggles the sorting of query from asc<-->desc
                     
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    4/7/2017         Mani Sundaresan          Initial Creation(US-0001634)
    ------------------------------------------------------------*/ 
  public void toggleSort() {
    // simply toggle the direction
    sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
    // run the query again
    runQuery();
  }
  
   /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:     runs the actual query to search contact
                     
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    4/7/2017          Mani Sundaresan        Initial Creation(US-0001634)
    ------------------------------------------------------------*/ 
 
  public void runQuery() {
    try 
    {
        //Run query to get contacts
      contacts = Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 10 OFFSET ' +pagination);
      contactCount = contacts.size();
    } catch (Exception e) 
    {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
    }

  }
    /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    runs the contact search with parameters passed via Javascript
                     
    Inputs:         N/A 
    Returns:        PageReference
    
    History:
    <Date>          <Authors Name>             <Brief Description of Change>
    4/7/2017         Mani Sundaresan             Initial Creation(US-0001634)
    4/13/2017       Amarendra Nagireddy          Edited soql query string to get the contact matched with any of the account and customer account
                                                 Edited Soql query string to get contact if only matched with email
    4/27/2017       Amarendra Nagireddy          Add additional fields those are included in the VF page contact creation.fields are extension,addiphone,addiextension  
    ------------------------------------------------------------*/
  
  public PageReference runSearch() {

    firstName = Apexpages.currentPage().getParameters().get('firstname');
    lastName = Apexpages.currentPage().getParameters().get('lastname');
    accountName = Apexpages.currentPage().getParameters().get('accountName');
    customeraccount= Apexpages.currentPage().getParameters().get('customeraccount');
    email = Apexpages.currentPage().getParameters().get('email');
    phone = Apexpages.currentPage().getParameters().get('phone');
    extension= Apexpages.currentPage().getParameters().get('extension');
    role= Apexpages.currentPage().getParameters().get('role');
    String clearpagination = Apexpages.currentPage().getParameters().get('clearPagination');
      //4/27/2017(Amarendra Nagireddy)Added additional fields those are included in the VF page contact creation 
    addiphone= Apexpages.currentPage().getParameters().get('addiphone');
    addiextension= Apexpages.currentPage().getParameters().get('addiextension');
    
    if(clearpagination == 'true')
        pagination = 0;
    //4/13/2017(Amarendra Nagireddy)Modified below dynamic soql to search contacts based on email id along with first,last name
    soql = 'select firstname, lastname, account.name, phone, email, name from contact where (account.name != null';
    if (!firstName.equals(''))
      soql += ' and firstname LIKE \''+String.escapeSingleQuotes(firstName)+'%\'';
    if (!lastName.equals(''))
      soql += ' and lastname LIKE \''+String.escapeSingleQuotes(lastName)+'%\'';
  
    if (!accountName.equals('') && !customeraccount.equals('') )
    {
        //Get all the related contact matched with account and customer account 
       //soql += ' and (account.name LIKE \''+String.escapeSingleQuotes(accountName)+'%\''+'or account.name LIKE \''+String.escapeSingleQuotes(customeraccount)+'%\''+')';
        soql += ' and AccountId IN: AccountSet';
    }
    else if( !accountName.equals('') && customeraccount.equals(''))
    {
      soql += ' and account.name LIKE \''+String.escapeSingleQuotes(accountName)+'%\'';
    }
    else if(accountName.equals('') && !customeraccount.equals(''))
    {
      soql += ' and account.name LIKE \''+String.escapeSingleQuotes(customeraccount)+'%\'';
    }
    
    if (!email.equals(''))
      soql += ' and email LIKE \''+String.escapeSingleQuotes(email)+'%\'';
    if(!phone.equals(''))
    {
      soql += ' and phone LIKE \''+String.escapeSingleQuotes(phone)+'%\'';
    }
    if (!email.equals(''))
    {
       //Get the contact record if matched with user entred email in contact search 
   soql += ' ) or email LIKE \''+String.escapeSingleQuotes(email)+'%\'';
   }
   else
   {
     soql += ' )';
   }
      
    // run the query again
    runQuery();
    return null;
  }

   /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    validate contact details, if contact not exits with given deatils, create contact and map contact id on 
                    case and insert case as well.create tasks with entered Note type information.
                     
    Inputs:         N/A 
    Returns:        PageReference
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    4/7/2017         Mani Sundaresan       Initial Creation(US-0001634)
    4/13/2017        Amarendra Nagireddy   display message to user on VF page if contact already exists with the given email.check 
                                           all the required fields before contact creation.if not, alert user to enter required fields.check user entred email is valid or not
    4/27/2017       Amarendra Nagireddy     Map newly added fields to contact creation. fields are additional phone,Extenstion;
    5/22/2017       Amarendra Nagireddy     Added exception handling while inserting contact, case
                                            Modified logic to update case only if note type =Problem description
                                            Added exception handling for insert task, update case
    ------------------------------------------------------------*/ 
  //save method to create records
  public PageReference createRecords(){
      PageReference pageref;
      
      //Create Contact
      Contact con;
      List<Contact> conlist=new List<Contact>();
      createduplicatecontact=Apexpages.currentPage().getParameters().get('createduplicatecontact');
      if(selectedContact != null && (createduplicatecontact==null ||createduplicatecontact==''))
      {
          //if user selected contact from existing contact, map selected contact to contact intiated
          con = new Contact(Id=selectedContact);
          system.debug('first selected contact is not null');
      }
      else{
          system.debug('second selected contact is  null');
          //if user does not select any contact from existing contact list create new contact with user entered details
          con = new Contact();
          con.FirstName = firstName;
          con.LastName = lastName;
          con.Email = email;
          con.Phone = phone;
          //con.AccountId = asst.AccountId;
          con.AccountId=getaccountid;
         
          //4/27/2017(Amarendra Nagireddy)-Added additional fields
          con.Extension__c =extension;
          con.OtherPhone=addiphone;
          con.Role__c = role;
          //Ftech the contact details based on user entred email
          system.debug('+++'+email);
         
           //check all the required fields before inserting contact
           system.debug(firstName);
           system.debug(lastName);
           system.debug(Email);
           system.debug(Phone);
           if(!String.isBlank(firstName)&&!String.isBlank(lastName)&&!String.isBlank(Email)&&!String.isBlank(Phone))
           {
             //validate user entred email, if it is not valid throw an error message
             system.debug(validateEmail(email));
             if(validateEmail(email)!=false)
             {
                 
                 
                 Database.DMLOptions dml = new Database.DMLOptions(); 
                 
                 if(createduplicatecontact==null ||createduplicatecontact=='')
                 {
                   dml.DuplicateRuleHeader.allowSave = false;
                 }else
                 {
                   dml.DuplicateRuleHeader.allowSave = true;
                 }
                 dml.DuplicateRuleHeader.runAsCurrentUser = true;
                 System.debug('createduplicatecontact-->'+createduplicatecontact);
                Database.SaveResult saveResult = Database.insert(con, dml);
                if (!saveResult.isSuccess()) 
                {
                    for (Database.Error error : saveResult.getErrors()) {
                        
                        if (error instanceof Database.DuplicateError) {
                           
                            Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                            Datacloud.DuplicateResult duplicateResult =duplicateError.getDuplicateResult();
                            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Duplicate Error: ' + 
                            duplicateResult.getErrorMessage());
                            ApexPages.addMessage(errorMessage);
                            
                            this.duplicateRecords = new List<sObject>();

                            Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                            Datacloud.MatchResult matchResult = matchResults[0];
                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                            for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                System.debug('MatchRecord: ' + matchRecord.getRecord());
                                this.duplicateRecords.add(matchRecord.getRecord());
                            }
                            this.hasDuplicateResult = !this.duplicateRecords.isEmpty();
                        }
                    }
            }
              
              }
              else
              {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter Valid Email'));
              }
           }
      }
      //Create a new case If the contact id is not null
      if(con.ID!=null){
      newCase.ContactId = con.Id;
      //newCase.AccountId = asst.AccountId;
      newCase.AssetId = assetId;
          system.debug(newCase);
          //5/22/2017(Amarendra Nagireddy)-Added exception handling while inserting case
      try{
           insert newCase;
         }catch (DMLException e){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem While creating Case '+e.getMessage()));
         }
      
      //Create Task
      List<Task> taskList = new List<Task>();
      for(wrapperTaskList wtl : waTaskList){
          System.debug('Cmon man:'+wtl.record);
          Task tsk = wtl.record;
          tsk.WhatId = newCase.Id;
          tsk.WhoId = con.Id;
          tsk.Status = 'Completed';
          taskList.add(tsk);
      }
      //5/22/2017(Amarendra Nagireddy)-Added exception handling
      try{
           insert taskList;
         }catch (DMLException e){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem While Inserting Task '+e.getMessage()));
         }
       
       boolean notetypePrblemDesc = false; 
       boolean updatecase=false;
        for(Task t: taskList){
        if(t.Note_Type__c == 'Problem Description')
            {
                    if(newCase.subject == null){
                       newCase.subject = t.Subject;
                    }
                
                    if(newCase.Description != null){
                        newCase.Description = newCase.Description + '\n\n' + t.Description;
                    }
                    else{
                            newCase.Description = t.Description;
                            
                        }
                 updatecase=true;
                }
            
        }
          //5/22/2017(Amarendra Nagireddy)-Modified logic to update case only if note type =Problem description, added exception handling
      if(updatecase){
          
         try{
            update newCase;
         }catch (DMLException e){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem While updating Case '+e.getMessage()));
         }
          
      
      }
     
      
      pageref = new PageReference('/'+newCase.Id);
  
      return pageref;
      }
      else{
         //If contact id is null throw an error message
        if(con.id==null && hasDuplicateResult==false)
        {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Select from an existing Contact or Fill in all information related to a new Contact: First Name, Last Name, Email, Phone'));
        }
        else
        {
           Apexpages.currentPage().getParameters().put('firstname',firstname);
           Apexpages.currentPage().getParameters().put('lastname',lastname);
           Apexpages.currentPage().getParameters().put('email',email);
           Apexpages.currentPage().getParameters().put('phone',phone);
           Apexpages.currentPage().getParameters().put('extension',extension);
           Apexpages.currentPage().getParameters().put('addiphone',addiphone);
           Apexpages.currentPage().getParameters().put('role',role);

        }
      }
      return null;
  }
  
  /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    Redirect to asset page when user clicks on cancel
    Inputs:         N/A 
    Returns:        PageReference
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    4/7/2017         Mani Sundaresan             Initial Creation(US-0001634)
    ------------------------------------------------------------*/
  //cancel method
  public PageReference Cancel(){
      PageReference pageref = new PageReference('/'+Recordid);
      pageref.setredirect(true);
      return pageref;
  }
  /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    Remove selected row under case description information, this method will call when user click on 
                    Remove link under Description Information.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    4/7/2017         Mani Sundaresan             Initial Creation(US-0001634)
    ------------------------------------------------------------*/
  public void removeRowFromTaskList(){
       waTaskList.remove(rowToRemove);
  }
  
     /*------------------------------------------------------------
    Author:         Mani Sundaresan
    Company:        Hologic
    Description:    Insert a new row to enter case Note Type description information, this method will call when user click on 
                    Add row command link under case Description Information.
    Inputs:         N/A 
    Returns:        N/A
    
    History:
    <Date>          <Authors Name>      <Brief Description of Change>
                     Mani Sundaresan        Initial Creation(US-0001634)
    ------------------------------------------------------------*/
  public void addNewRowToTaskList(){
  
      wrapperTaskList newTask = new wrapperTaskList();
      wrapperTaskList newTask1 = new wrapperTaskList();
      
      if(waTaskList.size() == 0){
          Task tsk = new Task();
          newTask.record = tsk;
          newTask.index =  waTaskList.size();
          newTask.record.Note_Type__c = 'Problem Description';
          
          Task tsk1 = new Task();
          newTask1.record = tsk1;
          newTask1.index =  waTaskList.size()+1;
          newTask1.record.Note_Type__c = 'Patient Impact';
          
          waTaskList.add(newTask);  
          waTaskList.add(newTask1);   
      }
      else{
          Task tsk = new Task();
          newTask.record = tsk;
          newTask.index =  waTaskList.size();
          waTaskList.add(newTask);
      }
        
     
  }
}