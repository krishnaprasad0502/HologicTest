public with sharing class PaymentScheduleController {
    public List<Payment_Schedule__c> payments {get; private set;}

    public PaymentScheduleController() {
        Id quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');        
        payments = [select Id, Payment_Start_Date__c, Payment_Frequency__c,Number_of_Payments__c, Payment_Amount__c, Payment_Notes__c from 
                        Payment_Schedule__c where Quote__c = :quoteId order by Print_Sequence__c asc];
    }
}
/* Modified order by to use Print Sequence */
/* Rich Varga Apps Associates 3-14 */
/* HD-2858 */