/*------------------------------------------------------------
Author:      Yogi
Company:    
Description:  Email Note Handler
Used to handle emails sent for attachements to case or Work Order
Emails sent must have a subject that conforms to one of the following formats
- [case: <casenumber>] Subject Description
- [wo: <WOnumber>] Subject Description
Emails sent to WO is attached as a Task
Emails send to a case is attached as a EmailMessage and a Task
Test Class:   EmailNoteHandler_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
06/06/2017    Yogi      Initial Creation 
07/17/2017    Yogi      Updated to create EmailMessage for cases
01/04/2018    Kasmoor Reddy Inserting the email communications records when inbound emails fails.
02/08/2018    Krishna Prasad Added the cc and bcc address to email communication object.(US3969)
------------------------------------------------------------------------------------------------*/


global class EmailNoteHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                           Messaging.InboundEnvelope env)
    {
        
        // Create an InboundEmailResult object for returning the result of the 
        // Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        String myPlainText= '';
        //keep track of errors
        Boolean processError = false; 
        String processErrorDescription;                                                       
        String objType;
        List<Email_Communication__c> Insertemailcomm = new List<Email_Communication__c>();
        
        
        Id ObjectID; // Id of the object to attach the note to
        
        Configuration_Settings__c orgDefaults = Configuration_Settings__c.getOrgDefaults();
        
        
        //get Object type from email subject - find chars before ':'
        if (email.subject.indexof(':')>0){
            System.debug('Subject: ' + email.subject);
            objType = email.subject.substringAfter('[').substringBefore(':').toLowerCase().trim(); //sample subject "fwd: [case: 01234] Email Complaint" 
            System.debug('objType: ' + objType);
            if (objType == 'case'){
                //find the case number - anything after the ':' char
                String caseNum = email.subject.substringAfter('[').substringAfter(':').substringBefore(']').trim();
                List<Case> emailCase = [select Id from case where CaseNumber = :caseNum];
                if (emailCase.size()==0){
                    //01/04/2018    Kasmoor Reddy Inserting the email communications records when inbound emails fails.
                    createEmailRec(email);
                    
                    processError = true;
                    processErrorDescription = 'Invalid case number provided, ' + caseNum + ' not found. \n \nAll emails must have the full Case number and must be provided in the following format. \nExample, [Case: 00060404] where full H1 Case number is 00060404';
                       
                
                }else{
                    ObjectID = emailCase[0].Id;
                }
            }
            else if (objType == 'work order' || objType == 'wo'|| objType == 'workorder'){
                //find the wo number - anything after the ':' char
                String woNum = email.subject.substringAfter('[').substringAfter(':').substringBefore(']').trim();
                System.debug('woNum: ' + woNum);
                List<WorkOrder> emailWO = [select Id from WorkOrder where WorkOrderNumber  = :woNum];
                if (emailWO.size()==0){
                    processError = true;
                    processErrorDescription = 'Error: Could not locate WO with WO number: ' + woNum;
                }else{
                    ObjectID = emailWO[0].Id;
                }
            }
            else{
                //01/04/2018    Kasmoor Reddy Inserting the email communications records when inbound emails fails.
                createEmailRec(email);
                
                processError = true;
                processErrorDescription = 'Error: Invalid Object Specified : ' + objType;
                   
                
            }
            
        }else{
            
           //01/04/2018    Kasmoor Reddy Inserting the email communications records when inbound emails fails.
            createEmailRec(email);
            
            
            processError = true;
            processErrorDescription = 'Invalid Subject. Object type must be specificed followed by ":" ';
            env.toAddress = orgDefaults.Email_Address_for_Error_Handling__c;    
           
            
        }
        
      /*  //insert the email communication records when list is not empty
        if(Insertemailcomm.size()>0){
         Database.SaveResult[] lcr = Database.Insert(Insertemailcomm,false);
        for(Integer index = 0; index < lcr.size(); index++){
            if(!lcr[index].isSuccess()){
            Insertemailcomm[index].addError('Failed to Insert Email communication records: '+lcr[index].getErrors()[0].getMessage());
                
            }
        }
    } */   
        
        Id TaskOrEmailMessageId;
        
        if (!processError){
            // New Task object to be created
            Task newTask = new Task();           
            
            try {
                // Add a new Task to the record found above.
                newTask.Description =  email.plainTextBody;
                newTask.Priority = 'Normal';
                newTask.Status = 'Completed';
                newTask.Subject = 'Inbound Email: ' + email.subject;
                newTask.Type = 'Email';
                newTask.IsReminderSet = false;
                newTask.WhatId =  ObjectID;
                
                // Insert the new Task 
                insert newTask;    
                TaskOrEmailMessageId = newTask.Id;
                System.debug('New Task Object: ' + newTask );   
            }
            catch (Exception e) {
                processError = true;
                processErrorDescription = 'Error creating Email Activity: ' + e.getMessage();
            }
            
            
            //create a case email message if object is case
            if (!processError && objType == 'case'){
                
                try{
                    EmailMessage em = new EmailMessage();
                    //em.ActivityId = newTask.Id;
                    //02/08/2018 added by krishna as part of US-0003969
                    if (email.ccAddresses!= null && email.ccAddresses.size() >0){
                        em.CcAddress = String.join(email.ccAddresses, ';');
                    }
                    
                    if (email.fromAddress!=null) 
                        em.FromAddress = email.fromAddress;
                    if (email.fromName!=null)
                        em.FromNAme = email.fromName;
                      
                    if (email.headers!=null){
                        for (Messaging.InboundEmail.Header emHeader: email.headers){
                            em.headers =+ emHeader.name + ' ' + emHeader.value + ' ' ;
                        }
                    }
                
                    if (email.htmlbody!=null) 
                        em.htmlbody = email.htmlbody;
                    //em.IsExternallyVisible = false;
                    em.Incoming = true;
                    em.MessageDate = DateTime.now();
                    em.ParentId = ObjectID;
                    
                    if (email.subject !=null)
                        em.subject = email.subject;
                    if (email.plainTextBody !=null)
                        em.TextBody = email.plainTextBody;
                    System.debug('Email to address:'+em.ToAddress);
                    insert em;
                    System.debug('EmailMessage: ' + json.serializePretty(em));
                    TaskOrEmailMessageId = em.Id;
                }catch (Exception e) {
                    processError = true;
                    processErrorDescription = 'Error creating Case Email Record: ' + e.getMessage();
                    System.Debug('Error creating Case Email Record: ' + e.getMessage());
                }
                
            }
            
            //add any attachments to the Task or EmailMessage
            //
            List<Attachment> attachmentList = new List<Attachment>();
            if (!processError){
                try{
                    if (email.textAttachments!=null && email.textAttachments.size()>0){
                        for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                            Attachment attachment = new Attachment();
                            
                            attachment.Name = tAttachment.fileName;
                            attachment.Body = Blob.valueOf(tAttachment.body);
                            attachment.ParentId = TaskOrEmailMessageId;
                            attachmentList.add(attachment);
                            
                            System.debug('New text attachment: ' + attachment );
                        }
                    }
                    if (email.binaryAttachments != null && email.binaryAttachments.size() > 0){
                        for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                            Attachment attachment = new Attachment();
                            
                            attachment.Name = bAttachment.fileName;
                            attachment.Body = bAttachment.body;
                            attachment.ParentId = TaskOrEmailMessageId;
                            attachmentList.add(attachment);
                            
                            System.debug('New binary attachment: ' + attachment );
                        }
                    }
                    
                    if (attachmentList.size()>0){
                        insert attachmentList;
                        
                        System.debug('attachment list: ' + attachmentlist);
                    }
                }
                
                catch (Exception e) {
                    processError = true;
                    processErrorDescription = 'Error creating Email Activity: ' + e.getMessage();
                } 
                
            }
            
        }
        
        
        // Set the result 
        if (!processError){
            result.success = true;  
        }else{
            //result.success = false;
            //result.message = processErrorDescription;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String[] toAddresses = new String[] {orgDefaults.Email_Address_for_Error_Handling__c};
            
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Salesforce Administrator');
            mail.setSubject(email.subject);
            mail.setHtmlBody(processErrorDescription);
            
            if(!Test.isRunningTest())
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            result.success = true; 
        }
        
        // Return the result for the Apex Email Service
        return result;
    }
   //01/04/2018    Kasmoor Reddy Inserting the email communications records when inbound emails fails.
     public void createEmailRec (Messaging.inboundEmail email){
       Email_Communication__c emailcomm =new Email_Communication__c();
            //emailcomm.Email_Body__c=email.plainTextBody;
            emailcomm.Email_Body__c = email.HtmlBody;
            System.debug('Body:'+email.HtmlBody);
            if(emailcomm.Email_Body__c == null && email.plainTextBody != null)
                emailcomm.Email_Body__c=email.plainTextBody;    
            emailcomm.From_Address__c=email.fromAddress;
                        
            //02/08/2018 added by krishna as part of US-0003969
            if(email.ccAddresses!=null&& email.ccAddresses.size() >0) 
             emailcomm.cc_Address__c = String.join(email.ccAddresses, ';');
            emailcomm.From_Name__c=email.fromName;
            emailcomm.Subject__c=email.subject;
            emailcomm.Message_Date__c=DateTime.now();
            
         if(email.Toaddresses!=null){
            emailcomm.To_Address__c = email.Toaddresses[0];
             }
         try{
              System.debug('emailcomm:::before'+emailcomm);
             insert emailcomm;
              System.debug('emailcomm:::after'+emailcomm);
         }
         catch(exception e){
             System.debug('When inserting EmailCommunication Record:'+e.getMessage());
         }

List<Attachment> attachmentList = new List<Attachment>();
   

    if (email.textAttachments!=null && email.textAttachments.size()>0){
        for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
            Attachment attachment = new Attachment();
            
            attachment.Name = tAttachment.fileName;
            attachment.Body = Blob.valueOf(tAttachment.body);
            attachment.ParentId = emailcomm.id;
            attachmentList.add(attachment);
            
            System.debug('New text attachment: ' + attachment );
        }
    }
    if (email.binaryAttachments != null && email.binaryAttachments.size() > 0){
        System.debug('email.binaryAttachments::::: ' + email.binaryAttachments );
        for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
            Attachment attachment = new Attachment();
            
            attachment.Name = bAttachment.fileName;
            attachment.Body = bAttachment.body;
            attachment.ParentId = emailcomm.id;
            attachmentList.add(attachment);
            
            System.debug('New binary attachment: ' + attachment );
        }
    }
    
     if (attachmentList.size()>0){
        insert attachmentList;        
        System.debug('attachment list: ' + attachmentlist);
        String[] stringList = new String[0];
        for (Attachment  attdetals: attachmentList){
            
            stringList.add(String.valueOf(attdetals.id));
        }   
        String result = String.join(stringList, ',');  
        emailcomm.AttacmentIds__c= result ;
        }
        if(emailcomm.AttacmentIds__c!= null && emailcomm.AttacmentIds__c.length()>0){
            update emailcomm;
        }
    
      
    }
    
}