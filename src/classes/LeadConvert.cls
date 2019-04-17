public with sharing class LeadConvert {
    
    //public List<InnerClass> searchaccs {set;get;}
    public LeadConvert (){
        // Constructor..
    }

    // JS Remoting action called when searching for a movie name
    public static RecordType soldToRT = [SELECT Id FROM RecordType WHERE DeveloperName ='Prospect' Limit 1];
    public static RecordType shipToRT = [SELECT Id FROM RecordType WHERE DeveloperName ='Site' Limit 1];
    public static Id medAesOpptyRT = GlobalUtility.getRecordTypeId('Opportunity','Medical_Aesthetics_Capital_Sales_Opportunity');
    public LeadConvert(ApexPages.StandardController stdController) {
    }
    @RemoteAction
    public static map<String,Object> convertLead( map<String,Object> formData,List<String> statuses) {
        map<String,Object> results = new map<String,Object>();
        results.put('formData',formData);
        Set<String> setStatus = new Set<String>(statuses);
        //Account soldTo;
        Account soldToNew;
        Account shipToNew;
        Contact objCon;
        Id ParentId;
        Id AccountId;
        Id ConId;
        Id SiteLocationAccountId;

        /// Account Stuff
        system.debug('formData :'+formData);
        for(String str : formData.keySet()){
            system.debug(str+':'+formData.get(str));
        }
        if((Boolean)formData.get('soldToNew')){
            
            User userProfile = [select id,Profile.name from User where ID=:UserInfo.getUserId()];
            If(!Lead_Conversion_Profiles__C.getAll().containsKey(userProfile.Profile.Name)){
                 results.put('Error','User is not allowed to create new Accounts');
                return results;
            }
            soldToNew = new Account(recordTypeId = soldToRT.Id);
            soldToNew.Name =(String)formData.get('soldToName');
            if(((String)formData.get('street')).split('\n').size() > 0){
                soldToNew.BillingStreet = ((String)formData.get('street')).split('\n')[0];
            }else{
                soldToNew.BillingStreet = (String)formData.get('street');
            }
            system.debug(' soldToNew.BillingStreet'+ soldToNew.BillingStreet);
            soldToNew.BillingCity=(String)formData.get('city');
            soldToNew.BillingCountryCode=(String)formData.get('country');
            soldToNew.BillingStateCode=(String)formData.get('state');
            soldToNew.BillingPostalCode=(String)formData.get('zip');
            //soldToNew.IsSourcedFromLeadConversion__c = true;
            soldToNew.Phone = (String)formData.get('phone');
            insert soldToNew;
            system.debug('---soldToNew :'+soldToNew);
            system.debug( '------soldToNew : '+soldToNew.BillingCountryCode);
            ParentId =soldToNew.Id;
        }
        else{
            ParentId = (Id)formData.get('soldToId');
            soldToNew = [Select Id, Oracle_Party_Id__c,CDM_Record_Id__c From Account Where Id =: ParentId Limit 1];
        }
             system.debug('ParentId  :'+ParentId );
             results.put('ParentId',''+ParentId);
             
   //    if(!(Boolean)formData.get('soldToNew')){
      //  if((Boolean)formData.get('soldToId')){
//     soldToNew = [Select Id, Oracle_Party_Id__c,CDM_Record_Id__c From Account Where Id =: ParentId Limit 1];       
 //      }
       
        system.debug('ParentId  :'+ shipToNew );
        
      if((Boolean)formData.get('locationNew')){
           // formData.put('LocationName',formData.get('street'));
            shipToNew = new Account(recordTypeId = shipToRT.Id);
            shipToNew.Name = (String)formData.get('street');
            if(((String)formData.get('street')).split('\n').size() > 0){
                shipToNew.Name = ((String)formData.get('street')).split('\n')[0];
                shipToNew.BillingStreet = ((String)formData.get('street')).split('\n')[0];
            }else{
                shipToNew.Name = (String)formData.get('street');
                shipToNew.BillingStreet = (String)formData.get('street');
            }//shipToNew.BillingStreet = (String)formData.get('street');
            shipToNew.BillingCity=(String)formData.get('city');
            shipToNew.BillingCountryCode=(String)formData.get('country');
            shipToNew.BillingStateCode=(String)formData.get('state');
            shipToNew.BillingPostalCode=(String)formData.get('zip');
            //shipToNew.IsSourcedFromLeadConversion__c = true;
            shipToNew.Phone = (String)formData.get('phone');
            shipToNew.parentId = ParentId;
            insert shipToNew;
            
            Site_Location__c loc = new Site_Location__c();

          //  loc.Parent_CDM_Record_Id__c=shipToNew.CDM_Record_Id__c;
            //loc.Parent_Oracle_Party_ID__c=shipToNew.Oracle_Party_Id__c;

           // system.debug('CDMRecordId  :'+ loc.Parent_CDM_Record_Id__c );
          //  system.debug('PartyID  :'+ loc.Parent_Oracle_Party_ID__c );
            if(((String)formData.get('street')).split('\n').size() > 0){    
                loc.Name = ((String)formData.get('street')).split('\n')[0];
            }else{
                loc.Name = (String)formData.get('street');
            }
            loc.Account__c  = shipToNew.id;
            loc.City__c = (String)formData.get('city');
            loc.Country__c =(String)formData.get('country');
            loc.State__c = (String)formData.get('state');
            loc.Zip_Code__c=(String)formData.get('zip');
               // Added to create the site location correctly under the account;
            loc.Parent_CDM_Record_Id__c=soldToNew.CDM_Record_Id__c;
            loc.Parent_Oracle_Party_ID__c=soldToNew.Oracle_Party_Id__c;
            loc.Ship_To__c = true;
            if((Boolean)formData.get('soldToNew')){
                loc.Primary_Bill_To__c = true;
                loc.Bill_To__c = true;
                loc.Primary_Ship_To__c = true;
                loc.Identifying_Address__c = true;
            }
            
            if(((String)formData.get('street')).split('\n').size() >= 2 && !Test.isRunningTest()){  
            loc.Address_Line_1__c = ((String)formData.get('street')).split('\n')[0];
            if(((String)formData.get('street')).split('\n')[1] != null)
                loc.Address_Line_2__c = ((String)formData.get('street')).split('\n')[1];
            }
            else{
                loc.Address_Line_1__c = (String)formData.get('street');
            }
            
            
            System.debug('hello World!!!');
            
            insert loc;
            //SiteLocationAccountId = loc.Account__c;
            
        }

        //AccountId = ((Boolean)formData.get('locationNew') || (Boolean)formData.get('soldToNew'))?(Id)SiteLocationAccountId:(Id)formData.get('shipToId');
        AccountId = ((Boolean)formData.get('locationNew') || (Boolean)formData.get('soldToNew'))?(Id)ShipToNew.Id:(Id)formData.get('shipToId');
        
        System.debug('AccountId:'+AccountId);
        
        //if(AccountId == null) AccountId = soldToNew.Id;
        

        if((Boolean)formData.get('locationNew') || (Boolean)formData.get('ConNew')){
            // Inserting Contact..
            objCon = new Contact();
            //Add flag to prevent merge logic
            //objCon.SL_Lead_Conversion_Custom_VF_page__c = true;
            //Split Contact Name into First/Last if no space to separate first and last we will simply null out first name
            String conName = (String)formData.get('ConName') != Null ? (String)formData.get('ConName') : '';
            system.debug('conName :'+conName);
            conName = conName;
            if(String.isNotEmpty(conName))
            {
              Integer spaceIndex = conName.indexOf(' ');

              if(spaceIndex>-1)
              {
                objCon.FirstName = conName.substring(0,spaceIndex);
                objCon.LastName = conName.substring(spaceIndex+1);
              }
              else
              {
                objCon.FirstName = null;
                objCon.LastName = conName;
              }
            }
            else
            {
              objCon.FirstName = '';
              objCon.LastName = (String)formData.get('soldToName');
            }

            objCon.MailingStreet = (String)formData.get('street');
            objCon.MailingCity=(String)formData.get('city');
            objCon.MailingCountryCode=(String)formData.get('country');
            objCon.MailingStateCode=(String)formData.get('state');
            objCon.MailingPostalCode=(String)formData.get('zip');
            //objCon.AccountId = AccountId;
            objCon.AccountID = ParentId ;
            system.debug('objCon.AccountID :'+objCon.AccountID);
            insert objCon;
             system.debug('objCon :'+objCon);
        }
       
        ConId = (Boolean)formData.get('ConNew') ? objCon.Id : (Id)formData.get('ConId');    // Contact Id..
        if(formData.get('ConId') != null){
            Contact con = new Contact(ID=ConID);
            con.AccountID = (ID)formData.get('soldToId');
            update con;    
        }
        Lead objLead = [Select Id, IsConverted From Lead Where Id =: (Id)formData.get('leadId')];
        if(objLead.isConverted){
            results.put('Error','Lead has been already converted');
            return results;
        }else{
            //Lead Stuff
            // This is the lead convert object that will convert the lead
            Database.LeadConvert leadConvert = new database.LeadConvert();
            try{
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE MasterLabel in :statuses AND IsConverted=true LIMIT 1];
                leadConvert.setConvertedStatus(convertStatus.MasterLabel);
                
            }catch(exception e){
                   
                   
            }    
             leadConvert.setLeadId((Id)formData.get('leadId'));
                // leadConvert.setAccountId((Id)formData.get('shipToId'));
                leadConvert.setAccountId(ParentID);
                leadConvert.setContactId(ConId);
            if((Boolean)formData.get('opportunityNew')){
               leadConvert.setAccountId(ParentId );
                leadConvert.setDoNotCreateOpportunity(false);
                leadConvert.setOpportunityName((String)formData.get('opportunityName'));
            }
            else{
                leadConvert.setDoNotCreateOpportunity(true);
            }
            leadConvert.setOwnerId((Id)formData.get('ownerId'));
            
            Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);
            Id convertedOppty = leadConvertResult.getOpportunityId();
            List<Contact> conList= [select id,accountID from Contact where accountID=:accountID OR accountID=:ParentId];
            
            if(!conList.isEmpty()){
                for(Contact con : conList){
                    con.AccountID = accountID;
                }
                
                Database.DMLOptions dml = new Database.DMLOptions(); 
                dml.DuplicateRuleHeader.allowSave = true;
                //dml.DuplicateRuleHeader.runAsCurrentUser = true;
                List<Database.SaveResult> sr = Database.update(conList, dml);
                //update conList;
            }
            
            
            List<Opportunity> oppList = [select id,accountID, (Select ContactId from OpportunityContactRoles) from Opportunity where Id = :convertedOppty and RecordTypeId = :medAesOpptyRT];
            if(!oppList.isEmpty()){
                for(Opportunity opp : oppList){
                    System.debug('OpportunityId:'+opp.Id);
                    //opp.AccountID = ParentID;
                    opp.Account_Site__c = AccountId;
                    if(opp.getSObjects('OpportunityContactRoles') != null){
                        for(OpportunityContactRole ocr : (List <OpportunityContactRole>) opp.getSObjects('OpportunityContactRoles'))
                            opp.LPS_Contact__c = ocr.ContactId;
                    }
                        
                    
                }
                update oppList;
            }
            results.put('AccountId',AccountId);
            
            
            
            return results;
        }

    }

    @RemoteAction
    public static map<String,Object> init(Id leadId){
        UserRecordAccess objRecAccess = [SELECT RecordId, HasEditAccess,HasReadAccess, MaxAccessLevel FROM UserRecordAccess WHERE RecordId =: leadId and UserId =: Userinfo.getUserId() limit 1];
        map<String,Object> results = new map<String, Object>();

        if(objRecAccess.MaxAccessLevel != 'Read' && objRecAccess.MaxAccessLevel != 'None'){
            Lead l = [SELECT Id, Name, FirstName, LastName, Company,Street,City,State,PostalCode,Country FROM Lead WHERE Id=:leadId Limit 1];
            String completeAddress = l.Street+';'+l.City+';'+l.Country +';'+l.PostalCode ;
            Account soldTo ;
            Account shipTo ;
            Contact conRec ;
            List<Account> shipTos;
            List<Contact> lstcons;
            if(l.Company!=null){
                List<Account> soldTos = searchAccounts(l.Company.escapehtml4(), false);
                if(!soldTos.isEmpty()){
                     soldTo = soldTos[0];
                     shipTos=searchInitialLocations(l.Company.escapehtml4(),completeAddress ,soldTo); //searchLocations(l.Company,l.street,soldTo);
                     if(!shipTos.isEmpty()) {
                        shipTo = shipTos[0];

                        //Reference new search function.
                        // conRec = findContact(l.FirstName.escapehtml4(), l.LastName.escapehtml4(), shipTo.Id);
                        conRec = findContact(l.FirstName, l.LastName, shipTo.Id);
                     }
                }
            }
            results.put('lead',l);
            results.put('soldTo',soldTo);
            results.put('shipTo',shipTo);
            results.put('ConRec',conRec);
            system.debug('results: '+results);
           
        }else
            results.put('Error', 'Insufficient Access');

        return results;
    }

    @RemoteAction
    public static List<Account> searchAccounts(String searchTerm, Boolean searchByLike) {
        String query='Select Id,ShippingStreet,Name,BillingCity,BillingState,ShippingState,ShippingCity,ShippingPostalCode from Account where name';
        if(searchByLike)
            query += ' like \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
        else
            query += ' = \'' + String.escapeSingleQuotes(searchTerm) + '\'';

        query += ' AND (RecordType.DeveloperName=\'Prospect\'  OR RecordType.DeveloperName=\'Customer\') limit 100';

        List<Account> accounts = Database.query(query);
        system.debug('Accounts:'+accounts);
        return accounts;
    }

    public static List<Account> searchInitialLocations(String searchTerm, String strStreet, Account account)
    {
        String query='SELECT Id, Name,BillingStreet,BillingState,BillingCity,BillingPostalCode,BillingCountry,BillingCountryCode, BillingStateCode, parentId,parent.Name from Account WHERE ';
       /* if(searchTerm != null && searchTerm != '')
        {
            query+=' Name like \'%' + String.escapeSingleQuotes(searchTerm) +'%\' AND ';
        }*/
        system.debug('strStreet :'+strStreet);
        if(String.isNotEmpty(strStreet))
        {
           
            system.debug('strStreet :'+strStreet );
            query+=' Name like \'%' + String.escapeSingleQuotes(strStreet.split(';')[0]) +'%\' AND ';
            query+='BillingStreet = \'' + String.escapeSingleQuotes(strStreet.split(';')[0]) +'\' AND';
        }
        else
            //Don't match empty Street
            query+= 'BillingStreet = null AND';
       
        query+= ' RecordType.DeveloperName=\'Site\'';
        if(account.Id!=null){
            query+=' AND parentId=\''+account.Id+'\'';
        }
        query += '  order by createdDate DESC limit 100';
        system.debug('query: '+query);

        List<Account> accounts = Database.query(query);
        system.debug('Site Account : '+accounts);
        /*List<Site_Location__c> location = [select id,name from Site_Location__c where name =:strStreet.split(';')[0] and Address_Line_1__c=:strStreet.split(';')[0] and City__c =:strStreet.split(';')[1] and Country__c =:strStreet.split(';')[2] and Zip_Code__c =:strStreet.split(';')[3]];
        if(location.isEmpty()){
            Site_Location__c loc = new Site_Location__c();
            loc.Name = strStreet.split(';')[0];
            loc.Account__c  = accounts[0].id;
            loc.Address_Line_1__c = strStreet.split(';')[0];
            loc.City__c = strStreet.split(';')[1];
            loc.Country__c =strStreet.split(';')[2];
            loc.Zip_Code__c=strStreet.split(';')[3];
            insert loc;
        }*/
        return accounts;
    }

    @RemoteAction
    public static List<Account> searchLocations(String searchTerm, String strStreet, Account account) {
        String query='SELECT Id, Name,ShippingStreet,ShippingState,ShippingCity,ShippingPostalCode,ShippingCountry,ShippingCountryCode, ShippingStateCode, parentId,parent.Name from Account WHERE ';
        if(searchTerm != null && searchTerm != '')
        {
            query+=' Name like \'%' + String.escapeSingleQuotes(searchTerm) +'%\' AND ';
        }

        query+= ' RecordType.DeveloperName=\'Site\'';
        if(account.Id!=null){
            query+=' AND parentId=\''+account.Id+'\'';
        }
        query += '  order by ShippingCity ASC LIMIT 100 ';

        List<Account> accounts = Database.query(query);
        return accounts;
    }

    @RemoteAction
    public static List<User> searchOwners(String searchTerm) {
        String query='Select Id, Name from User where Name like \'%' + String.escapeSingleQuotes(searchTerm) + '%\' AND IsActive = True limit 100';
        List<user> users = Database.query(query);
        return users;
    }

    //New Method to find exact match
    public static Contact findContact(String firstName, String lastName, Id accountId)
    {
        if(accountId != Null)
        {
            List<Contact> contacts = [Select Id, FirstName, LastName, AccountId from Contact where FirstName=:firstName and LastName=:lastName and AccountId=:accountId order by CreatedDate limit 1];

            if(contacts.size()>0)
            {
              return contacts.get(0);
            }
        }

        return null;
    }

    @RemoteAction
    public static List<Contact> searchContacts(String searchTerm, Id accountId) {
        system.debug('searchTerm :'+searchTerm);
        if(accountId != Null){
            String query='Select Id,FirstName,AccountId, LastName from Contact where (LastName like \'%' + String.escapeSingleQuotes(searchTerm) + '%\' OR FirstName like \'%' + String.escapeSingleQuotes(searchTerm) + '%\')';
            query += ' AND AccountId =\'' +accountId+ '\'';


            query += ' limit 100';
            List<Contact> cons = Database.query(query);
            return cons;
        }

        return null;
    }

    @RemoteAction
    public static Lead getLeadAddress(String leadId) {
        Lead objLead = new Lead();
        objLead =  [SELECT Id, Street, City, State, PostalCode FROM Lead WHERE Id =: Id.valueOf(leadId)];
        return objLead;

    }

    @RemoteAction
    public static void cancelLead(String leadId){
        // Updating this lead.SL_Lead_Conversion_Custom_VF_page__c field to pass this value to contact..
       // Lead objLead = new Lead(Id=leadId);
        //objLead.SL_Lead_Conversion_Custom_VF_page__c = false;
       // update objLead;
    }

    
}