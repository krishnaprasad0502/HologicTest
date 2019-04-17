/*******************************************************************************
Author:         KASMOOR REDDY
Company:        APPS ASSOCIATES 
Description:    Display Approval records based on criteria
Test Class:     test_DisplayApprovalRecordsClass

History:
<Date>          <Authors Name>          <Brief Description of Change>
10/8/2018        KASMOOR REDDY              Initial Creation
*******************************************************************************/
public class DisplayApprovalRecordsClass {
    @auraEnabled public integer totalsearch {get; set;}
    @auraEnabled public List<sbaa__Approval__c> approvalRecords{get;set;}
    @auraEnabled public List<sbaa__Approval__c> approvalsOfQuote{get;set;}
    @auraEnabled public List<SBQQ__QuoteLine__c> quoteLineRecords{get;set;}
    @auraEnabled public sbaa__Approval__c ApprovalDetails{get;set;}
    @auraEnabled public List<String> fieldNames {get;set;}
    @auraEnabled public List<String> fieldAPINames {get;set;}
      @auraEnabled public List<String> fieldNamesQuoteLine {get;set;}
    @auraEnabled public List<String> fieldAPINamesQuoteLine {get;set;}
    
    public DisplayApprovalRecordsClass()
    {
        totalsearch=[select count() from sbaa__Approval__c where sbaa__Status__c='Requested' and sbaa__AssignedTo__c=:userInfo.getUserId()];
        
    }
    
    @AuraEnabled
    public static DisplayApprovalRecordsClass DisplayApprovalRecords(Integer Pagination)
        
    {
        DisplayApprovalRecordsClass obj=new DisplayApprovalRecordsClass();
        // totalsearch=[select count() from sbaa__Approval__c where sbaa__Status__c='Requested' and sbaa__AssignedTo__c=:userInfo.getUserId()];
        
        Integer Page=Integer.valueOf(Pagination);
        system.debug('in method!!!');
        
        obj.approvalRecords=[select id,sbaa__Status__c,sbaa__AssignedTo__c,sbaa__Opportunity__c,sbaa__Opportunity__r.Name, Quote__c, Quote__r.name, Name, Account_Name__c,sbaa__AssignedTo__r.name,sbaa__AssignedTo__r.Lastname from sbaa__Approval__c where sbaa__Status__c='Requested' and sbaa__AssignedTo__c=:userInfo.getUserId() limit 10 OFFSET: page];
        obj.totalsearch=[select count() from sbaa__Approval__c where sbaa__Status__c='Requested' and sbaa__AssignedTo__c=:userInfo.getUserId()];
        return obj;
    }
    
    @AuraEnabled
    public static DisplayApprovalRecordsClass DisplayDetailsForOneRecord(Id ApprovalId)
    {
        
        DisplayApprovalRecordsClass obj=new DisplayApprovalRecordsClass();
        obj.fieldNames=new List<String>();
        obj.fieldAPINames=new List<String>();
        obj.fieldNamesQuoteLine=new List<String>();
        obj.fieldAPINamesQuoteLine=new List<String>();
        obj.approvalsOfQuote=new List<sbaa__Approval__c>();
        obj.quoteLineRecords=new List<SBQQ__QuoteLine__c>();
        Schema.FieldSet fs1 = Schema.SObjectType.sbaa__Approval__c.fieldSets.getMap().get('Email_Fields');
        system.debug(fs1);
        for(Schema.FieldSetMember f:fs1.getFields())
        {
            obj.fieldNames.add(f.getLabel());
            obj.fieldAPINames.add(f.getFieldPath());
        }
        
        obj.ApprovalDetails=[select id,sbaa__Status__c,sbaa__AssignedTo__c,sbaa__Opportunity__c,sbaa__Opportunity__r.Name, Quote__c, Quote__r.name,Quote__r.Account_Name__c,Quote__r.SBQQ__Opportunity2__r.Owner.Name,Quote__r.Price_Agreement__r.Account.Name,Quote__r.Price_Agreement__r.Name,Quote__r.Marketing_Program__c,Quote__r.Margin__c,Quote__r.SBQQ__CustomerAmount__c,Quote__r.FOB__c,Quote__r.SBQQ__PaymentTerms__c,Quote__r.Payment_Terms_Freight__c,Quote__r.Created_Date__c,Quote__r.Expiration_Date__c,Quote__r.SBQQ__Notes__c,Quote__r.External_Notes__c,Quote__r.Loaner_Eval_Period__c,Quote__r.Buyout_Price__c,Quote__r.Rental_Fee__c,Quote__r.Contract_Language_Edit_Request__c,Name, Account_Name__c,sbaa__AssignedTo__r.name,sbaa__AssignedTo__r.Lastname from sbaa__Approval__c where id=:ApprovalId];
        Id quoteid=obj.ApprovalDetails.Quote__c;
        String recordSOQL = 'SELECT Quote__c,' + String.join(obj.fieldAPINames, ',')+
            '  FROM ' + 'sbaa__Approval__c' 
            +' where Quote__c =: quoteid';
        system.debug(recordSOQL);
        obj.approvalsOfQuote = Database.query(recordSOQL);
        Schema.FieldSet fs2 = Schema.SObjectType.SBQQ__QuoteLine__c.fieldSets.getMap().get('ApprovalRequest');
        system.debug(fs2);
        for(Schema.FieldSetMember f:fs2.getFields())
        {
            obj.fieldNamesQuoteLine.add(f.getLabel());
            obj.fieldAPINamesQuoteLine.add(f.getFieldPath());
        }
        String recordSOQL1 = 'SELECT SBQQ__Quote__c,' + String.join(obj.fieldAPINamesQuoteLine, ',')+
            '  FROM ' + 'SBQQ__QuoteLine__c' 
            +' where SBQQ__Quote__c =: quoteid';
        system.debug(recordSOQL1); 
        obj.quoteLineRecords=Database.query(recordSOQL1);
        system.debug('obj.approvalsOfQuote::::::::'+obj.approvalsOfQuote);
        /* obj.approvalsOfQuote=new List<sbaa__Approval__c>([select name,sbaa__Approver__r.name,sbaa__Status__c,sbaa__AssignedTo__c,Quote__c,Approval_Chain__c,sbaa__ApprovalStep__c,Approval_Rule__c,Assigned_To__c,sbaa__Approver__c,sbaa__CommentsLong__c from sbaa__Approval__c where Quote__c=:obj.ApprovalDetails.Quote__c]);
        obj.quoteLineRecords=new List<SBQQ__QuoteLine__c>([ select SBQQ__Quote__c,SBQQ__ProductName__c,Covered_Product_Number__c,SBQQ__Description__c,List_Price__c,Contract_Price__c,Customer_Unit_Price_Output__c,Customer_Total_Quote_Document__c,Line_Margin__c,SBQQ__Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=:obj.ApprovalDetails.Quote__c]); 
        */ system.debug('obj.ApprovalDetails::::::::'+obj.ApprovalDetails);
        return obj;
    }
    
}