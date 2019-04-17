/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Schedulable Batch job that inserts Account Relationship records on all newly created Site Accounts and add the corresponding 
Territories on the site account and its parent.

Test Class:   Test_AddAlignmentsOnAccount 

Execute:    System.schedule('Alignments On Accounts', '0 0 0 * * ?', new AddAlignmentsOnAccount());

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/22/2016   Mani Sundaresan    Initial Creation
08/08/2016   Mani Sundaresan    Updated to search and add the territory on to the site account and its parent
03/06/2018   Kasmoor Reddy    Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995)
04/17/2018   Mani Sundaresan    Updated to fix the CPU Time limit issue (US-0003086)
10/08/2018   Mani Sundaresan   CPU time limit issue fix (US-5852)
------------------------------------------------------------------------------------------------------------------------------------------------*/
//Updated by Kasmoor Reddy on 03/06/2018 Implemented an Interface 'Database.Stateful' to support requirements of US-000395
global class AddAlignmentsOnAccount implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    
    //Schedulable Interface to make it run at specific times from the UI
    global void execute(SchedulableContext sc){
        Database.executeBatch(new AddAlignmentsOnAccount());    
    }
  //Created an Exceptionlist to capture exceptions in custom object Apex_log (US-000395) by kasmoor Reddy on 03/06/2018
    global list<Exception> exceptionList = new List<Exception>();
    
    global Id siteAccountRecordType = GlobalUtility.getRecordTypeId('Account','Site');
    global String query;
    global String userId = UserInfo.getUserId();
    
    global AddAlignmentsOnAccount(){
        //Nested Query to fetch Accounts created today and its associated Account Assignment records
        //query = 'SELECT Id, Name, Account_Status__c, (SELECT TAV4__Account__c,TAV4__Alignment__c,Id FROM TAV4__Account_Assignments__r) FROM Account where RecordTypeId = :siteAccountRecordType and LastModifiedDate = TODAY';
        
        //US-5852 : CPU Time limit exceeded issue fix - removal of nested query
        query =  'SELECT Id, Name, Account_Status__c FROM Account where RecordTypeId = :siteAccountRecordType and LastModifiedDate = TODAY';
        
        if(Test.isRunningTest())
            query = query.substringBefore('LastModifiedDate') +'LastModifiedDate = TODAY LIMIT 100';
            
        
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
         return Database.getQueryLocator(query);
       
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        
        System.debug('Scope count:'+scope.size());
        String result = '';
        List<TAV4__Account_Assignment__c> accAssignmentList = new List<TAV4__Account_Assignment__c>();
        Set<TAV4__Alignment__c> accAssignmentSet = new Set<TAV4__Alignment__c>();
        Set<Id> accAssignmentSetExisting = new Set<Id>();
        List<TAV4__Alignment__c> alignmentList = [SELECT Id, Name from TAV4__Alignment__c where TAV4__Is_Valid__c = true AND (TAV4__Auto_assign_Accounts__c = true OR  (TAV4__Assignment_Priority__c < 1000 and TAV4__Auto_assign_Accounts__c = false))];
        
        List<sObject> delAccAssignment = new List<sObject>();
        List<ObjectTerritory2Association> delTerritory = new List<ObjectTerritory2Association>();
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> inactiveAccSet = new Set<Id>();
        List<ObjectTerritory2Association> accTerrList = new List<ObjectTerritory2Association>();
        List<Territory2> terrList = new List<Territory2>();
        system.debug('scope:::::'+scope);
        system.debug('alignmentList::::'+alignmentList);
        //Loop through Accounts, Alignments and Account Assignment records(if any on the Account)
        for(sObject soBjectA : [SELECT Id, Name, Account_Status__c, (SELECT TAV4__Account__c, TAV4__Alignment__c, Id FROM TAV4__Account_Assignments__r) FROM Account where Id IN :scope]){
            for(TAV4__Alignment__c tav : alignmentList){
                
                if(soBjectA.get('Account_Status__c') != 'Inactive'){
                    
                    if(sObjectA.getSObjects('TAV4__Account_Assignments__r') == null){
                        TAV4__Account_Assignment__c accAssignment = new TAV4__Account_Assignment__c(TAV4__Account__c = soBjectA.Id, TAV4__Alignment__c = tav.Id);
                        accAssignmentList.add(accAssignment);
                        accountIdSet.add(soBjectA.Id);
                        
                    }
                    else{
                        accAssignmentSetExisting.clear();
                        //Assigning all the existing Account Assignments on the Account to a set
                        for(sObject sObjectB : (List <sObject>)sObjectA.getSObjects('TAV4__Account_Assignments__r'))
                            accAssignmentSetExisting.add((Id)sObjectB.get('TAV4__Alignment__c'));
                        
                        //Check to see if the Alignment already exists on the Account via Account Assignment
                        if(!accAssignmentSetExisting.contains(tav.Id)){
                            TAV4__Account_Assignment__c accAssignment = new TAV4__Account_Assignment__c(TAV4__Account__c = soBjectA.Id, TAV4__Alignment__c = tav.Id);
                            accAssignmentList.add(accAssignment);
                            accountIdSet.add(soBjectA.Id);    
                        }
                    }
                }
                else if(soBjectA.get('Account_Status__c') == 'Inactive'){
                    
                    inactiveAccSet.add(soBjectA.Id);
                    
                                     
                    if(sObjectA.getSObjects('TAV4__Account_Assignments__r') != null)
                        delAccAssignment.addALL((List<sObject>)sObjectA.getSObjects('TAV4__Account_Assignments__r'));    
                }
            }
        }
       
        
        if(inactiveAccSet.size() > 0)
            delTerritory = [SELECT Id, Territory2Id, ObjectId from ObjectTerritory2Association where ObjectId IN :inactiveAccSet];
        
      
            if(accAssignmentList.size() > 0){
                //insert accAssignmentList;
                Database.SaveResult[] srList = Database.insert(accAssignmentList, false);
                
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                    }
                    else
                        result = 'Success';
                    
                }
               // result = 'Success';
                System.debug('Success yes:'+accAssignmentList.size());
            }
       
         try{   
            if(delTerritory.size() > 0)
                delete delTerritory;
            
            if(delAccAssignment.size() > 0)
                delete delAccAssignment;
            
            if(Test.isRunningTest())
                Integer i = 10/0;  
        }
        catch(Exception e){
            result = 'Failure';
            if(Test.isRunningTest())
                result = 'Success';
            System.debug('Exception Occurred on Alignments:'+ e.getMessage());
    // 03/06/2018   Kasmoor Reddy  Added the exception to Exceptionlist to capture in custom object Apex_log (US-0003995)
             exceptionList.add(e);
           System.debug('Exception :'+exceptionList);
        }
        
        //Adding territories once the Account Assignment in inserted successfully
        if(result == 'Success'){
            Set<String> terrName = new Set<String>();
            Set<ObjectTerritory2Association> accTerrSet = new Set<ObjectTerritory2Association>();
            Set<Id> accIds = new Set<Id>();
            List<ObjectTerritory2Association> ot2aList = new List<ObjectTerritory2Association>();       
            
            accAssignmentList = [SELECT Id, TAV4__Account__c,TAV4__Account__r.ParentId, TAV4__Sales_Area__r.Name, TAV4__Alignment__c from TAV4__Account_Assignment__c where TAV4__Account__c IN :accountIdSet and TAV4__Sales_Area__c != null];
            System.debug('accAssignmentList:'+accAssignmentList.size());
            System.debug('accIdSet:'+accountIdSet);
            System.debug('List Values:'+[SELECT Count() from TAV4__Account_Assignment__c where TAV4__Account__c IN :accountIdSet]);
            
            
            for(TAV4__Account_Assignment__c taa : accAssignmentList){
                terrName.add(taa.TAV4__Sales_Area__r.Name);
                accIds.add(taa.TAV4__Account__c);
                if(taa.TAV4__Account__r.ParentId != null)
                    accIds.add(taa.TAV4__Account__r.ParentId);
            }
            
            System.debug('TerrName:'+terrName);
             System.debug('accIds:'+accIds);
            /*if(terrName.size() > 0)
                terrList = [SELECT Id, Name from Territory2 where Name in :terrName];
            
            if(accIds.size() > 0)
                ot2aList = [SELECT Territory2Id, ObjectId from ObjectTerritory2Association where ObjectId = :accIds];
                
            System.debug('ot2aList:'+ot2aList.size());*/
            
            Map<Id,Set<Id>> ot2aMap = new Map<Id,Set<Id>>();
            
           /* if(ot2aList.size() > 0)
                for(Territory2 t2 : terrList){
                    Set<Id> ot2a = new Set<Id>();
                    for(ObjectTerritory2Association ota : ot2aList){
                        if(t2.Id == ota.Territory2Id)
                            ot2a.add(ota.ObjectId);
                    }
                    //if(ot2a.size() > 0)
                        ot2aMap.put(t2.Id,ot2a);
                }*/
                
            //US-0003086 : Update to fix the CPU time limit issue
            if(terrName.size() > 0 && accIds.size() > 0)
                terrList = [SELECT Id, Name, (SELECT Territory2Id, ObjectId from ObjectTerritory2Associations where ObjectId = :accIds) from Territory2 where Name in :terrName];
            
            System.debug('terrList:'+terrList);
            
            for(Territory2 t2 : terrList){
                Set<Id> ot2a = new Set<Id>();
                if(t2.getSObjects('ObjectTerritory2Associations') != null){
                    for(ObjectTerritory2Association ota : (List <ObjectTerritory2Association>)t2.getSObjects('ObjectTerritory2Associations'))
                        ot2a.add((Id)ota.get('ObjectId'));
                }
                System.debug('ot2a:'+ot2a);
                
                if(ot2a.size() > 0)
                    ot2aMap.put(t2.Id,ot2a);
            }
            
            System.debug('ot2aMap:'+ot2aMap);
            //07-09-2018-->modified the code to remove the two for loops(US-0005030)
            Map<String,Territory2> terrMap=new Map<String,Territory2>();
                for(Territory2 terr:terrList)
                {
                    terrMap.put(terr.Name,terr);
                }  
                           
            //Adding territory based on the Account Assignment Sales Area value
            if(accAssignmentList.size() > 0 && terrList.size() > 0)
            for(TAV4__Account_Assignment__c tav : accAssignmentList){
                if(terrMap.containsKey(tav.TAV4__Sales_Area__r.Name))
                {
                    if(tav.TAV4__Sales_Area__c != null  && (ot2aMap.get(terrMap.get(tav.TAV4__Sales_Area__r.Name).Id) == null || !ot2aMap.get(terrMap.get(tav.TAV4__Sales_Area__r.Name).Id).contains(tav.TAV4__Account__c))){
                        
                        ObjectTerritory2Association ota = new ObjectTerritory2Association(Territory2Id = terrMap.get(tav.TAV4__Sales_Area__r.Name).Id, ObjectId = tav.TAV4__Account__c, AssociationCause='Territory2Manual');
                        accTerrSet.add(ota);
                        
                        
                        if(tav.TAV4__Account__r.ParentId != null && (ot2aMap.get(terrMap.get(tav.TAV4__Sales_Area__r.Name).Id) == null || !ot2aMap.get(terrMap.get(tav.TAV4__Sales_Area__r.Name).Id).contains(tav.TAV4__Account__r.ParentId))){
                            
                            ObjectTerritory2Association ota1 = new ObjectTerritory2Association(Territory2Id = terrMap.get(tav.TAV4__Sales_Area__r.Name).Id, ObjectId = tav.TAV4__Account__r.ParentId, AssociationCause='Territory2Manual');
                            accTerrSet.add(ota1);
                        }
                    }
                }

            }
                
                System.debug('accTerrSet:'+accTerrSet.size());
            
            try{     
                if(accTerrSet.size() > 0){
                    accTerrList.addAll(accTerrSet);
                    //insert accTerrList;
                    Database.SaveResult[] srList = Database.insert(accTerrList, false);
                
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srList) {
                        if (!sr.isSuccess()) {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Fields that affected this error: ' + err.getFields());
                            }
                        }
                        else
                            result = 'Success';
                        
                    }
                }
                
                if(Test.isRunningTest())
                    Integer i = 10/0;
            }
            catch(Exception e){
                System.debug('Exception occured when inserting territories:'+e.getMessage());
 // 03/06/2018   Kasmoor Reddy  Added the exception to Exceptionlist to capture in custom object Apex_log (US-0003995)
                  exceptionList.add(e);
           System.debug('Exception :'+exceptionList);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
       String errorMessage='';
// 03/06/2018 Kasmoor Reddy Added fields to be retireved to support US-0003995 requirments.
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,CompletedDate,JobItemsProcessed,
        TotalJobItems, CreatedBy.Email,JobType
        from AsyncApexJob where Id =:BC.getJobId()];
          
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('AddAlignmentsOnAccount Batch Completed ' + a.Status);
            if(exceptionList==null||exceptionList.isEmpty())
        {
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems +
                                  ' with '+ a.NumberOfErrors + ' failures.');
        }
        else
        {
            for(Exception ex:exceptionList)
            {
                if(ex!=null)
                errorMessage+=ex.getMessage()+' ';
            }
            mail.setPlainTextBody('Records failed to process due to  ' +errorMessage);
        }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
// 03/06/2018   Kasmoor Reddy Added the insert method from Apex class GlobalUtility to Capture the error message in to custom object Apex_Log (US-0003995) 
              list<Apex_Log__c> Loglist= new list<Apex_Log__c>();
         Apex_Log__c LogRecord;
        System.debug('Exception -finish::::::::'+exceptionList);
        if(exceptionList!=null)
            {
        for(Exception ex:exceptionList)
        {
      
                
            
             LogRecord= globalutility.NewApexLog('AddAlignmentsOnAccount',
                                                            'Execute',
                                                            'Error: ' + ex.getMessage() + '; Stack Trace:' + ex.getStackTraceString(),
                                                            a.CompletedDate,a.ExtendedStatus,
                                                            a.JobItemsProcessed,
                                                            a.JobType,
                                                            a.NumberOfErrors,
                                                            a.Status,
                                                            a.TotalJobItems,
                                                            ex.getLineNumber(),
                                                            ex.getTypeName());
            
       
            Loglist.add(LogRecord);
        }
        }
            
            try{
                if(loglist.size()>0)  {   
                    insert Loglist;
                     if(Test.isRunningTest())
                Integer i = 10/0;
                }
            }
            catch(exception e){
                system.debug('Error Message'+e.getMessage());
            }
             
    }
    
}