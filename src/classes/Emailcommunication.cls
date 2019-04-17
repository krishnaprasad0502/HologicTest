/*------------------------------------------------------------
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    EMAIL COMMUNICATION SEARCH PAGE
Class Name:     Emailcommunication          
Test Class:     Emailcommunication_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
21/2/2018       KASMOOR REDDY           Changes to Search Criteria (US-3997)
11/10/2018      Krishna                 Modified the query for sorting the message date (US-5783)
------------------------------------------------------------*/
public class Emailcommunication
{
    
    @auraEnabled public  integer countselectedPage {get; set;}
    @auraEnabled public  integer countsearch {get; set;}
    @auraEnabled public  integer totalsearch {get; set;}
   
    @auraEnabled public list<Email_Communication__c> lstemailcommunication{get;set;}
/*------------------------------------------------------------
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    EMAIL COMMUNICATION SEARCH PAGE
Class Name:     Emailcommunication          
Test Class:     Emailcommunication_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
21/2/2018       KASMOOR REDDY           Changes to Search Criteria (US-3997)
------------------------------------------------------------*/

    @AuraEnabled
    public static  Emailcommunication searchkeyword(string enterdate ,string fromdate,string searchcase, string searchname,Integer Pagination,String toaddress)
    {
        Emailcommunication obj = new Emailcommunication();
       //system.debug(toaddress);
        string soql;
        string soqlcount;
        Integer month;
        Integer day;
        Integer year;
        Integer Page=Integer.valueOf(Pagination);
         //system.debug(enterdate);
         //system.debug(fromdate);
        if(enterdate==null)
        {
            String dateFormatString = 'yyyy-MM-dd';
            Date d = Date.today();
            Datetime dt = Datetime.newInstance(d.year(), d.month(),d.day());
            enterdate = dt.format(dateFormatString);
           // System.debug(enterdate); 
        }
       //system.debug(enterdate);
       
        list<Email_Communication__c>returnEmailcommunication=new list<Email_Communication__c>();
        boolean flag=false;
        if(searchcase==''||searchcase==null)
        {
         searchcase='Unassigned';
        }

        soql = 'SELECT id,name,CurrencyIsoCode,Subject__c,To_Address__c,Email_Body__c,From_Address__c,From_Name__c,Message_Date__c,status__c,Case__r.CaseNumber,cc_Address__c,Bcc_Address__c from Email_Communication__c where id!=null';
        soqlcount = 'SELECT count() from Email_Communication__c where id!=null';
        /*Kasmoor Reddy Apps Associates*/
        /*US-3997*/
        /*Search Criteria enhanced (search even based on ccAddress)*/
        if (!string.isEmpty(toaddress))        
        {
       
         soql += ' and ( To_Address__c LIKE \''+'%'+String.escapeSingleQuotes(toaddress)+'%\'';
         soql += ' or  cc_Address__c LIKE \''+'%'+String.escapeSingleQuotes(toaddress)+'%\')';
        }
        if(!string.isEmpty(fromdate)&&!string.isEmpty(enterdate))
        {                     
            Date dtfrom = date.valueOf(fromdate);
            date enterdatedt = date.valueOf(enterdate);            
            Datetime dtconfrom = Datetime.newInstance(dtfrom.year(), dtfrom.month(),dtfrom.day(),0,0,0);
            Datetime enterdatecondt = Datetime.newInstance(enterdatedt.year(),enterdatedt.month(),enterdatedt.day(),23,59,59);
            string dtconfromstring = dtconfrom.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');
            string enterdatecondtstring = enterdatecondt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');  
            soql+= ' and Message_Date__c >='+dtconfromstring ;
            soql+= ' and Message_Date__c <='+enterdatecondtstring ;
           //system.debug(soql);
        }
        if(!string.isEmpty(searchcase))
        {
         if(searchcase=='Assigned')
        {
         soql+=' and Case__r.CaseNumber !=null';
        }
         if(searchcase=='Unassigned')
        {
         soql+=' and Case__r.CaseNumber =null';
        }
        }
        if (!string.isEmpty(searchname))     
        {
            soql += ' and ( From_Name__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\'';
            //soql += ' or To_Address__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\'';
            soql += ' or From_Address__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\'';
            soql += ' or cc_Address__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\'';
            //soql += ' or Bcc_Address__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\'';
            soql += ' or  Subject__c LIKE \''+'%'+String.escapeSingleQuotes(searchname)+'%\')';
        }
       //system.debug('soql:::'+soqlcount);
        //system.debug('soql:11::'+soql );
       //Modified by krishna as part of US-5783
       soql += ' Order by Message_Date__c desc ';
        //system.debug('soql:22::'+soql );
        integer countEmailcommunication=Database.countquery(soqlcount);
       list<Email_Communication__c> eclist= Database.query(soql);
        obj.totalsearch = eclist.size();
        //system.debug('countEmailcommunication:::'+countEmailcommunication);
        obj.countselectedPage = countEmailcommunication;
         //system.debug('countselectedPage:::'+obj.countselectedPage);
        obj.lstemailcommunication=Database.query(soql+'  limit 20 OFFSET  ' +page);
       obj.countsearch = obj.lstemailcommunication.size();
       //system.debug('obj:::'+obj);
        return obj;
     }
/*------------------------------------------------------------
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    EMAIL COMMUNICATION SEARCH PAGE
Class Name:     Emailcommunication          
Test Class:     Emailcommunication_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
------------------------------------------------------------*/
    //DELETE EMAIL COMMUNICATION RECORD
    @AuraEnabled  
    public static void deleteRecords(List < String > lstRecordId) {
        List < String > oErrorMsg = new List < String > ();
        String attids;
        String contentids;
        list<id> attId =new list<id> ();
        list<id> contentId=new list<id>();
        list<id> ContentDoclidtid =new list<id>();
        List < Email_Communication__c > lstDeleteRec = [select Id,AttacmentIds__c from Email_Communication__c where id IN: lstRecordId];
            system.debug('lstDeleteRec'+lstDeleteRec);
        if(lstDeleteRec.size()>0){
        if(lstDeleteRec[0].AttacmentIds__c!= null ){
            attids=lstDeleteRec[0].AttacmentIds__c;
        }
        }
        if( attids!= null ){
            for(String key : attids.split(','))
            {
            attId.add(id.valueof(key));
            }
        }

       if(attId.size()>0){
            List <Attachment> listAtt =[select id from Attachment where id in:attId ];
        if(attId.size()>0){
              system.debug('attachments'+listAtt);
            try{
                    system.debug('try');
                    delete listAtt;
            }
                
               catch(Exception e){
                    system.debug('catch');
                    System.debug('Exception occured when deleting Attachment:'+e.getMessage());
               }
           }
      }
     
        Database.DeleteResult[] DR_Dels = Database.delete(lstDeleteRec, false);
        // Iterate through each returned result
        for (Database.DeleteResult dr: DR_Dels) {
            if (dr.isSuccess()) {
                system.debug('successful delete contact');
                // Operation was successful
            } else {
                // Operation failed, so get all errors   
                oErrorMsg.add('');
                for (Database.Error err: dr.getErrors()) {
                    // add Error message to oErrorMsg list and return the list
                    oErrorMsg.add(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
       // return oErrorMsg;
    
    }
        
    /*------------------------------------------------------------
Author:         KRISHNA PRASAD
Company:        APPS ASSOCIATES 
Description:    EMAIL COMMUNICATION SEARCH PAGE
Class Name:     Emailcommunication          
Test Class:     Emailcommunication_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
20/1/2018       KRISHNA PRASAD          Initial Creation(US-0003622)
------------------------------------------------------------*/ 
//RETRIVES EMAIL FILTER FROM META DATA
    @AuraEnabled
    public static list<String> extractPicklistValues()
    {
        list<string> emailstring = new list<string> ();        
        list<Email_Communication_filters__mdt> EmailFilter = [Select DeveloperName,MasterLabel, EmailFilter__c from Email_Communication_filters__mdt];
        
        if(EmailFilter.size()>0){            
            for(Email_Communication_filters__mdt ecdetails : EmailFilter){                
                emailstring.add(ecdetails.EmailFilter__c);                
            }            
        }       
        return emailstring;
    }    
}