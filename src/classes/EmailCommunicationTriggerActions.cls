/*------------------------------------------------------------
Author:         Krishna Prasad
Company:        Apps Associates
Description:   Email Communication Trigger Actions
Test Class:    Emailcommunication_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
------------------------------------------------------------*/
public with sharing class EmailCommunicationTriggerActions {
 

    /*------------------------------------------------------------
   Author:         Krishna Prasad
Company:        Apps Associates
Description:   Email Communication Trigger Actions
Test Class:    Emailcommunication_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
    ------------------------------------------------------------*/
//DELETS TASK AND EMAIL MESSAGE FROM CASE 
    public static void deleteActivity(List<Email_Communication__c> allEmailCommunication, Map<Id, Email_Communication__c> oldEmailCommunications){
        list<id> listemailcomid = new list<id> ();
        list<EmailMessage>  emList = new list<EmailMessage> ();
        list<Task>  tList = new list<Task> ();
        
        for(Email_Communication__c ec:allEmailCommunication)
        {
        Email_Communication__c oldEmailCommunication = oldEmailCommunications != null && oldEmailCommunications.containsKey(ec.Id) ? oldEmailCommunications.get(ec.Id) : null;
            if( ec.Case__c != oldEmailCommunication.Case__c){   
               if(ec.Case__c!=null){
                    listemailcomid.add(ec.id);
               }
            }
        }
        
        if(listemailcomid.size()>0){
            
            for(EmailMessage em: [select id from EmailMessage where Email_Communication_Id__c IN: listemailcomid and Email_Communication_Id__c!= null ]){
                emList.add(em);
            }
             
            for(Task tdetail: [select id from Task where Email_Communication_Id__c IN: listemailcomid and Email_Communication_Id__c!= null] ){
                tList.add(tdetail);
            }
              
        }
        if (emList.size()>0){
            try{
                delete emList;
            }
            catch(Exception e){
                System.debug('Exception occured when deleting EmailMessage:'+e.getMessage());
            }
        }
        if (tList.size()>0){
            try{
                delete tList;
            }
            catch(Exception e){
                System.debug('Exception occured when deleting Task:'+e.getMessage());
            }
        }   
    
    }
    
    /*------------------------------------------------------------
   Author:         Krishna Prasad
Company:        Apps Associates
Description:   Email Communication Trigger Actions
Test Class:    Emailcommunication_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
    ------------------------------------------------------------*/
//CREATE TASK AND EMAIL MESSAGE TO CASE 

    public static void createTaskEm(List<Email_Communication__c> allEmailCommunication, Map<Id, Email_Communication__c> oldEmailCommunications){
        list<task> tasks = new list<task>();
        list<EmailMessage> emailmsg = new list<EmailMessage>();
            
        for(Email_Communication__c ec:allEmailCommunication)
        { 
            Task tsk = new Task(
                whatID = ec.case__c , 
                Ownerid = ec.ownerId, 
                status='Completed',
                Subject= ec.Subject__c,
               Email_Communication_Id__c=ec.Id
            ); 
            tasks.add(tsk); 
            
            EmailMessage msg = new EmailMessage(
                FromAddress = ec.From_Address__c,
                ToAddress = ec.To_Address__c,
                FromName = ec.From_Name__c,
                Subject = ec.Subject__c,
                HtmlBody = ec.Email_Body__c,
                TextBody = ec.Email_Body__c != null ? ec.Email_Body__c.replaceAll('<[^>]+>',' ') : null,
                ParentId = ec.Case__c,
                Incoming = false,
                CcAddress=ec.cc_Address__c,
                BccAddress=ec.Bcc_Address__c,
                Email_Communication_Id__c=ec.Id,
                Status = '0'
            );
            emailmsg.add(msg);
        }
        
        if (tasks.size()>0){
            try{
                insert tasks;  
            }
            catch(Exception e){
                System.debug('Exception occured when inserting Task:'+e.getMessage());
            }
        }
        if (emailmsg.size()>0){
            try{
                insert emailmsg;
            }
            catch(Exception e){
                System.debug('Exception occured when inserting EmailMessage:'+e.getMessage());
            }
        }
    }
    
  
    /*------------------------------------------------------------
   Author:         Krishna Prasad
Company:        Apps Associates
Description:   Email Communication Trigger Actions
Test Class:    Emailcommunication_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
    ------------------------------------------------------------*/
//insert Attacments TO CASE 


    public static void insertAttacments(List<Email_Communication__c> allEmailCommunication, Map<Id, Email_Communication__c> oldEmailCommunications){
        list<id> attId =new list<id> ();
        list<Email_Communication__c> listec =new list<Email_Communication__c> ();
        list<Attachment> attList = new list<Attachment> ();
        list<Attachment> attnewList = new list<Attachment> ();
        id caseid;
        map<id,id>emCase = new map<id,id>();
        
        for(Email_Communication__c ec:allEmailCommunication)
        {
            Email_Communication__c oldEmailCommunication = oldEmailCommunications != null && oldEmailCommunications.containsKey(ec.Id) ? oldEmailCommunications.get(ec.Id) : null;
                if( ec.Case__c != oldEmailCommunication.Case__c){   
                system.debug('AttacmentIds__c:::::::'+ec.AttacmentIds__c);
                system.debug('Case__c :::::::'+ec.Case__c );
                if( ec.AttacmentIds__c != null ){
               
                    for(String key : ec.AttacmentIds__c.split(','))
                    {
                        system.debug('AttacmentIds__c:::::::key '+key );
                        attId.add(id.valueof(key));
                    }
                    caseid = ec.Case__c;
                    listec.add(ec);
                }
            }
    
        }
        if(attId.size()>0){
                attList =[select Body,BodyLength,ContentType,Description,Id,IsDeleted,IsPrivate,Name,ParentId from Attachment where id IN:attId];
                if(attList.size()>0){
                system.debug('attList::::'+attList);
                    for(Attachment attdetails : attList){
                        Attachment attnew = new Attachment();
                        
                        attnew.Body = attdetails.Body;
                        //attnew.BodyLength =attdetails.BodyLength;
                        attnew.ContentType =attdetails.ContentType;
                        attnew.Description =attdetails.Description;
                        //attnew.IsDeleted =attdetails.IsDeleted;
                        attnew.IsPrivate =attdetails.IsPrivate;
                        attnew.Name =attdetails.Name;
                        system.debug('attdetails.ParentId::::'+attdetails.ParentId);
                         system.debug('emCase::::'+emCase);
                        attnew.ParentId = caseid  ;
                        
                        attnewList.add(attnew);
                    }
                     system.debug('attnewList::::'+attnewList);
                }
                if(attnewList.size()>0){
                    try{
                        insert attnewList;
                        system.debug('afterattnewList::::'+attnewList);
                    }
                    catch(Exception e){
                        System.debug('Exception occured when inserting new Attachment:'+e.getMessage());
                    }
                    String[] stringList = new String[0];
                    for (Attachment  attdetals: attnewList){
                        stringList.add(String.valueOf(attdetals.id));
                    }   
                    String result = String.join(stringList, ',');  
                    listec[0].AttacmentIds__c= result ;
                    if(listec[0].AttacmentIds__c!= null && listec[0].AttacmentIds__c.length()>0){
                        
                        try{
                            //update listec[0];
                        }
                        catch(Exception e){
                            System.debug('Exception occured when updating new email communition record:'+e.getMessage());
                        }
                    }
                }       

                if(attList.size()>0){
                    try{
                        delete attList;
                    }
                    catch(Exception e){
                    
           
            
                        System.debug('Exception occured when deleteing old Attachment:'+e.getMessage());
                       
                    }
                
                }
            }

    }       
    
    
    
}