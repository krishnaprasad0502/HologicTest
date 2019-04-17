/**************************************************************************************
Author       : Nikhil Mutyam
Company      : Hexaware Technologies
Created Date : 8/13/2018 2:39 AM
Description  : Customer Self Registration Controller 
Test Class   : LightningSelfRegisterControllerTest  

History:
<Date>          <Author Name>           <Brief Description of Change>           <Copa.do US#>
8/13/2018       Nikhil Mutyam           Initial Creation                        US-0005630
10/15/2018      Niraj Wani              Approval Process                        US-0005861
10/30/2018      Vrushabh Katariya       Fetching TimeZone                       US-0005861
11/13/2018      Vrushabh katariya       Updated timezone code                   US-0006062
11/13/2018      Niraj Wani              Case on CSR                             US-0006257
12/21/2018      Nomita Walke            Added default Product to case           US-0006345
12/21/2018      Yogitha Malireddy       Added function to fetch country values  US-0006345 
12/31/2018		Yogitha Malireddy		Updated FetchCountryPicklistValues()	US-0006345
01/02/2019		Vrushabh Katariya		Grey-out submit button					US-0006703
**************************************************************************************/
global without sharing class LightningSelfRegisterController {
    /*
* Method Name: LightningSelfRegisterController()
* Input Param: No inputs required
* Return: NA 
* Description: Constructor
*/
    public LightningSelfRegisterController() {
        
    }
    
    /*
* Method Name: isValidPassword()
* Input Param: password and confirmPassword
* Return: Boolean 
* Description: Check and returns true if password matches with confirmPassword
*/
    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    /*
* Method Name: siteAsContainerEnabled()
* Input Param: Communityurl URL in the form od string
* Return: Boolean 
* Description: returns if the site is enabled as container
*/
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    /*
* Method Name: validatePassword()
* Input Param: User, password string and confirmPassword string
* Return: void 
* Description: validates the password for the user
*/
    
    /*
@TestVisible 
private static void validatePassword(User u, String password, String confirmPassword) {
if(!Test.isRunningTest()) {
Site.validatePassword(u, password, confirmPassword);
}
return;
} */
    
    /*
* Method Name: selfRegister()
* Input Param: All User related fields
* Return: string 
* Description: Creates User and Contact records as a part of Self Registration
*/
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, 
                                      String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword,
                                      string JobTitle, string Company, string MobilePhone, string OfficePhone, string BusinessStreetAddress, 
                                      string City, string State, string Country, string zip, string newUserRegUrl, 
                                      string productInterest, string serialNumber, string TimeZone) {
                                          Savepoint sp = null;
                                          //Validate FirstName is not blank                                    
                                          if (firstname == null || String.isEmpty(firstname)) {
                                              return  System.Label.Support_Self_Register_FirstName_Error;
                                          }
                                          //Validate LastName is not blank          
                                          if (lastname == null || String.isEmpty(lastname)) {
                                              return Label.Site.lastname_is_required;
                                          }
                                          
                                          //Validate Email is not blank       
                                          if (email == null || String.isEmpty(email)) {
                                              return Label.Site.email_is_required;
                                          }
                                          else{
                                              // If User already exists with email address, then show message to user and do not allow submission of request
                                              list<User> existingUsers = [SELECT Id FROM User WHERE UserType = 'PowerCustomerSuccess' and Email =: email];
                                              if(existingUsers != Null && existingUsers.size() > 0){
                                                  return label.Support_Duplicate_Username_Error;
                                              }
                                          }
                                          
                                          //Validate JobTitle is not blank          
                                          if (JobTitle == null || String.isEmpty(JobTitle)) {
                                              return Label.Community_JobTitle_Required;
                                          }
                                          //Validate Company is not blank       
                                          if (Company == null || String.isEmpty(Company)) {
                                              return Label.Community_Company_Required;
                                          } 
                                          //Validate Office Phone is not blank          
                                          if (OfficePhone == null || String.isEmpty(OfficePhone)) {
                                              return Label.Community_OfficePhone_Required;
                                          }                                    
                                          //Validate Business Street Address is not blank       
                                          if (BusinessStreetAddress == null || String.isEmpty(BusinessStreetAddress)) {
                                              return Label.Community_BusinessStreetAddress_Required;
                                          }                                              
                                          //Validate City is not blank          
                                          if (City == null || String.isEmpty(City)) {
                                              return Label.Community_City_Required;
                                          } 
                                          //Validate State is not blank         
                                          if (State == null || String.isEmpty(State)) {
                                              return Label.Community_State_Required;
                                          }
                                          //Validate Country is not blank         
                                          if (Country == null || String.isEmpty(Country)) {
                                              return Label.Community_Country_Required;
                                          }                                          
                                          //Validate Zip is not blank       
                                          if (zip == null || String.isEmpty(zip)) {
                                              return Label.Community_Zip_Required;
                                          } 
                                          
                                          //Validate TimeZone is not blank                                    
                                          if (TimeZone == null || String.isEmpty(TimeZone)) {
                                              return  System.Label.Community_TimeZone_Error;
                                          }                                          
                                          
                                          //Log Community Self Registration Request and Create case assigned to Service Admin Queue                                         
                                          try {
                                              
                                              String caseDescription= '';
                                              String ContactId = '';
                                              String ContactAccountId = '';
                                              String CustomerAccountId = '';
                                              Boolean multipleContactExists = false;
                                              String existingContactFound = '';
                                              List<Contact> Contacts = new List<Contact>();
                                              Contacts = [select Id, AccountId, Account.ParentId,Account.RecordType.Name from Contact Where Email =: email];
                                              If(Contacts != Null && Contacts.size() == 1){
                                                  system.debug('The Contact is'+Contacts[0]);
                                                  system.debug('The Contact is'+Contacts[0].Account.RecordType.Name);
                                                  ContactId = Contacts[0].Id; 
                                                  //map the Site Account on the CSR only if the COntact's Account is a L3.
                                                  if(Contacts[0].Account.RecordType.Name == 'Site'){
                                                      ContactAccountId = Contacts[0].AccountId;
                                                  }
                                                  system.debug('The Contact is'+ContactAccountId);
                                                  CustomerAccountId = Contacts[0].Account.ParentId;
                                              }
                                              Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
                                              String baseUrl = config.Base_URL__c;
                                              If(Contacts != Null && Contacts.size() > 1){
                                                  multipleContactExists =true;
                                                  existingContactFound = ' There are '+ Contacts.size() + ' contacts found matching with email:' + email + ' ';
                                                  for(Contact duplContact: Contacts){
                                                      existingContactFound = existingContactFound + '\n' + baseUrl + '/' + duplContact.Id;
                                                  }
                                                  System.debug('Message Deuplicate Contact: ' + existingContactFound);
                                              }
                                              
                                              //Retrieve ID of Service Admin Queue
                                              Id queueID = [select Id from Group where  Type = 'Queue' AND NAME = 'B&SH Service Admin'].Id;
                                              
                                              sp = Database.setSavepoint();           
                                              //Prepare Community Self Registration Request
                                              
                                              Community_Self_Registration_Request__c  commUser = new Community_Self_Registration_Request__c();
                                              commUser.Community_Email__c = email;
                                              commUser.Community_First_Name__c = firstname;
                                              commUser.Community_Last_Name__c = lastname;
                                              commUser.Community_Job_Title__c = JobTitle;
                                              commUser.Community_Company_Name__c = Company;
                                              commUser.Community_Mobile_Phone__c = MobilePhone;
                                              commUser.Community_Office_Phone__c = OfficePhone;
                                              commUser.Community_Street_Address__c = BusinessStreetAddress;
                                              commUser.Community_City__c = City;
                                              commUser.Community_State__c = State;
                                              commUser.Community_Country__c = Country;
                                              commUser.Community_Zip_Code__c = zip;
                                              //commUser.Password__c = password;
                                              commUser.Community_Status__c = 'Submitted';
                                              commUser.OwnerId = queueID;
                                              commUser.Community_Timezone__c = TimeZone;
                                              if (ContactId <> '')
                                              {
                                                  commUser.Community_Contact__c = ContactId;
                                                  system.debug('The Contact is'+ContactAccountId);
                                                  if(ContactAccountId != ''){
                                                      commUser.Community_Account__c = ContactAccountId;
                                                  }
                                                  
                                                  commUser.Community_Customer_Account__c = CustomerAccountId;
                                              }
                                              
                                              //System.debug('New Fields: ' + productInterest + ' ...' + serialNumber);
                                              
                                              commUser.Community_Product_Interest__c = productInterest;
                                              commUser.Community_Serial_Number__c = serialNumber;   
                                              commUser.Community_Comments__c = existingContactFound;
                                              
                                              insert commUser;
                                              
                                              //Add Note 
                                              String caseNoteStr = '';
                                              Note userNote = new Note();
                                              userNote.ParentId = commUser.Id;
                                              caseNoteStr = String.format(Label.Community_User_Case_Note, new List<String>{firstname, lastname, String.valueOf(System.now()) });
                                              system.debug('Case Note: '+ caseNoteStr);
                                              userNote.Body = caseNoteStr;
                                              //'User ' + firstname + ' , ' + lastname  + ' registered on ' + System.now() + ' for access and accepted the Hologic T&C';
                                              userNote.Title = 'New Community User - T&C Acceptance';
                                              insert userNote;            
                                              
                                              if (commUser.Id != null){ 
                                                  //Create Case for assignment to Service Admin Queue
                                                  //Fetch Dummy Contact which will be assigned in cases where no contact matches based on email id
                                                  List<Contact> dummyContact = new List<Contact>();
                                                  String dummyContactId = '';
                                                  dummyContact = [select Id from Contact Where FirstName =: Label.Community_Self_Registration_Contact_FirstName];
                                                  if (dummyContact.size() > 0 )
                                                        dummyContactId = dummyContact[0].Id;                                                  
                                                  Case cs = new Case();
                                                  //Web Registration Request - COMPANY – FIRST NAME LAST NAME – BUSINESS STREET ADDRESS, STATE
                                                  String caseSubject = 'Web Registration Request - ' + Company + ' - ' + firstname + ' - ' 
                                                      + lastname + ' - ' + BusinessStreetAddress + ' - ' + State;
                                                  if (caseSubject.length() > 254)
                                                      caseSubject = caseSubject.mid(0, 253);
                                                  
                                                  cs.Subject = caseSubject;
                                                  String requestURL =  URL.getOrgDomainUrl().toExternalForm() + '/' + commUser.Id; 
                                                  
                                                  caseDescription = 'A New Web Registration Request has been received for ' + Company 
                                                      + ' - ' + firstname + ',' +  lastname 
                                                      +  existingContactFound
                                                      + '\n Visit below URL to review and approve this request: ' + requestURL;
                                                  cs.Description = caseDescription;
                                                  cs.Status = 'New';
                                                  cs.Type = 'Web Registration';
                                                  cs.Origin = 'Web';
                                                  if (ContactId != '')
                                                      cs.ContactId = ContactId;
                                                  else 
                                                      cs.ContactId = dummyContactId;
                                                  cs.Priority = 'Other';
                                                  cs.System_Status__c = 'Up';
                                                  
                                                  if (queueID != Null)
                                                      cs.OwnerId = queueID;
                                                  
                                                  //Get the default product for the case
                                                  List<Product2> listprd = new List<Product2>();
                                                  listprd = [select Id from Product2 where Name =: Label.Community_Registration_Default_Product limit 1];
                                                  if(listprd.size() > 0){
                                                      cs.ProductId = listprd[0].Id;
                                                  }
                                                  insert cs;
                                                  
                                                  commUser.Case__c = cs.Id;
                                                  update commUser;
                                                  
                                                  system.debug('The case id is'+cs.Id);
                                                  
                                              }
                                              
                                              ApexPages.PageReference confirmRef = new PageReference(newUserRegUrl);
                                              if(!Test.isRunningTest()) {
                                                  aura.redirect(confirmRef);   
                                              }
                                              
                                              return 'true';
                                              //return null;
                                          }
                                          catch (Exception ex) {
                                              system.debug('The exception line number is '+ex.getLineNumber());
                                              system.debug('Stack trace: ' + ex.getStackTraceString());
                                              system.debug('Cause: ' + ex.getCause());
                                              Database.rollback(sp);
                                              //return ex.getMessage();
                                              return label.Support_Self_Register_Error;            
                                          }
                                      }
    
    /*
* Method Name: getExtraFields()
* Input Param: Fieldset name in the form of string
* Return: List<Map<String,Object>> 
* Description: Fetches fields from Fieldset if defined
*/
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.User.fieldSets.getMap().get(extraFieldsFieldSet);
        /*if(!Test.isRunningTest()) {
if (fieldSet != null) {
for (Schema.FieldSetMember f : fieldSet.getFields()) {
Map<String, Object> fieldDetail = new Map<String, Object>();
fieldDetail.put('dbRequired', f.getDBRequired());
fieldDetail.put('fieldPath', f.getFieldPath());
fieldDetail.put('label', f.getLabel());
fieldDetail.put('required', f.getRequired());
fieldDetail.put('type', f.getType());
fieldDetail.put('value', '');   // client will populate
extraFields.add(fieldDetail);
}
}
}*/
        return extraFields;
    }
    
    /*
* Method Name: setExperienceId()
* Input Param: expId in the form of string
* Return: String
* Description: Sets Experience Id
*/
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    }
    
    /*
* Method Name: FetchStatePicklistValues()
* Input Param: Object Type
* Return: list<string>
* Description: Fetch State Picklist Values
*/
    @AuraEnabled
    public static list<string> FetchStatePicklistValues(sObject objDetail){
        system.debug('You are here: '+objDetail);
        List<string> options = new List<string>();                 
        Map<String, List<String>> CountryStateMap = LightningSelfRegisterController.getDependentMap(objDetail,'CountryCode','StateCode');
        system.debug('The country state map is: '+CountryStateMap);
        for(string str : CountryStateMap.keySet()){
            if(str == 'United States'){
                for(string str2 : CountryStateMap.get(str)){
                    system.debug('The Country is: '+str2);
                    options.add(str2);
                }    
            }    
        }        
        list<Account> Accounts = new list<Account>();
        return options;
    }
    
    /*
* Method Name: FetchCountryPicklistValues()
* Input Param: Object Type
* Return: list<string>
* Description: Fetch Country Picklist Values
*/
    @AuraEnabled
    public static List<string> FetchCountryPicklistValues(sObject objDetail){
        Map<String, List<String>> CountryStateMap = LightningSelfRegisterController.getDependentMap(objDetail,'CountryCode','StateCode');
        list<string> countryOptions = new List<string>();
        for(String st:CountryStateMap.keySet()){
            if(st != 'United States'){
                countryOptions.add(st);
            }
        }
        return countryOptions;
    }
    /*
* Method Name: getDependentMap()
* Input Param: Object Type, Dependent Picklist Api, Controllint Picklist Api
* Return: Map<String, List<String>>
* Description: Helper method to fetch state picklist values based on Country
*/
    @AuraEnabled 
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }
    
    /*
* Method Name: decimalToBinary()
* Input Param: Integer
* Return: string
* Description: Converts decimal value to binary value
*/
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    /*
* Method Name: base64ToBits()
* Input Param: string
* Return: string
* Description: Converts base64 value to bits
*/
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    /*Helper class for picklist*/
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }
    
    
    /*
* Method Name: getSelectOptions()
* Input Param: Object API name,Field API name
* Return: Map < String,String >
* Description: This method is created to return picklist values based on oject name and field value input.
*/
    @AuraEnabled
    public static Map < String,String > getSelectOptions(sObject objObject, string fld) {
        Map < String,String > allOpts = new Map < String,String > ();
        Schema.sObjectType objType = objObject.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        
        list < Schema.PicklistEntry > values =
            fieldMap.get(fld).getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a: values) {
            allOpts.put(a.getValue(),a.getlabel());
        }
        return allOpts;
    }
    
}