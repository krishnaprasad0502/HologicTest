public with sharing class CreatePaymentScheduleController {

    public SBQQ__Quote__c theQuote {get; private set; }
    public class PaymentScheduleWrapper {
        public integer counter {get; private set;}
        public Payment_Schedule__c payment {get; set;}
    }
    public List<PaymentScheduleWrapper> payments {get; set;}
    private List<Payment_Schedule__c> pmtsToDelete;

    public CreatePaymentScheduleController(ApexPages.StandardController stdController) {
        this.theQuote = [select Id,SBQQ__TargetCustomerAmount__c,SBQQ__NetAmount__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, Payment_Frequency__c from SBQQ__Quote__c 
                            where Id=:stdController.getId()];
        payments = new List<PaymentScheduleWrapper>();
        pmtsToDelete = new List<Payment_Schedule__c>();
    }

    public integer index {get; set;}

    private integer getDefaultNumberOfPayments() {
        integer numberOfMonths=1;
        system.debug(theQuote.SBQQ__SubscriptionTerm__c);
        if(theQuote.SBQQ__SubscriptionTerm__c != null)
            numberOfMonths = (integer)theQuote.SBQQ__SubscriptionTerm__c;
        else if(theQuote.SBQQ__StartDate__c == null ) 
            return numberOfMonths;
        else if(theQuote.SBQQ__EndDate__c != null)
            numberOfMonths = theQuote.SBQQ__StartDate__c.monthsBetween(theQuote.SBQQ__EndDate__c.addDays(1));
        
        if(numberOfMonths < 1)
            numberOfMonths = 1;
        
        integer termMonths = 1;
        if(theQuote.Payment_Frequency__c == 'Annual')
            termMonths = 12;
        else if(theQuote.Payment_Frequency__c == 'Semi-Annual')
            termMonths = 6;
        else if(theQuote.Payment_Frequency__c == 'Quarterly')
            termMonths = 3;
            
               
                        
        integer numPmts = numberOfMonths/termMonths ;
        
   
        
        
        if(math.mod(numberOfMonths,termMonths)!=0)
            ++numPmts; 
            
          
    /* Added by Rich Varga Apps Associates */
    /* if prepayment number of payments should be 1*/
    /* HD-3263 */    
        
        if(theQuote.Payment_Frequency__c == 'Prepayment')
            numPmts = 1;
            
        system.debug('numonths: '+ numberOfMonths+ ' term:'+termMonths+' numpmts: '+numPmts);
        return numPmts;
    }

    public void deleteLine() {
        if(index == null) {
            return;
        }
        if(payments[index].payment.Id != null)
            pmtsToDelete.add(payments[index].payment);
        payments.remove(index);
        for(PaymentScheduleWrapper pw : payments)
            if(pw.counter > index)
                pw.counter = pw.counter-1;
        updateTotals();
        return;
    }

    public void load() {
       PaymentScheduleWrapper  pw;
       payments.clear();
       integer i=0;
       /* Added Print Sequence to select */
       /* Changesd order by print sequence */
       /* Rich Varga Apps Associates */
       /* HD-2858 */
      
       for(Payment_Schedule__c p : [select Id, Payment_Start_Date__c, Payment_Frequency__c,Number_of_Payments__c, Payment_Amount__c, Payment_Total__c,  
       Payment_Notes__c, Print_Sequence__c from 
                        Payment_Schedule__c where Quote__c = :theQuote.Id order by Print_Sequence__c asc]) {
            pw = new PaymentScheduleWrapper();
            pw.counter = i;
            pw.payment=p;
            payments.add(pw);
            ++i;
        }
        if(payments.size() == 0) {
            Payment_Schedule__c ps = new Payment_Schedule__c();
            ps.Quote__c = theQuote.Id;
            ps.Payment_Start_Date__c = theQuote.SBQQ__StartDate__c;
            ps.Payment_Frequency__c = theQuote.Payment_Frequency__c;
            ps.Number_of_Payments__c = getDefaultNumberOfPayments();
            ps.Payment_Amount__c = theQuote.SBQQ__NetAmount__c / ps.Number_of_Payments__c;
            ps.Payment_Total__c = theQuote.SBQQ__NetAmount__c;
            pw = new PaymentScheduleWrapper();
            pw.counter = 0;
            pw.payment=ps;
            payments.add(pw);
        } 
        theQuote.SBQQ__TargetCustomerAmount__c = getPaymentTotal();

    }  

    private Decimal getPaymentTotal() {
        Decimal total = 0;
        for(PaymentScheduleWrapper ps : payments) {
            if(ps.payment.Payment_Amount__c != null) {
                total+=ps.payment.Payment_Total__c;
                if(ps.payment.Number_of_Payments__c < 1 || ps.payment.Number_of_Payments__c == null)
                    ps.payment.Number_of_Payments__c = 1;
                ps.payment.Payment_Amount__c = ps.payment.Payment_Total__c / ps.payment.Number_of_Payments__c;
            }
        }
        return total;
    }

    public PageReference updateTotals() {
        theQuote.SBQQ__TargetCustomerAmount__c = this.getPaymentTotal();
        return null;
    }
    public PageReference addPayment() {
        Payment_Schedule__c ps = new Payment_Schedule__c();
        ps.Quote__c = theQuote.Id;
        ps.Payment_Start_Date__c = theQuote.SBQQ__StartDate__c;
        ps.Payment_Frequency__c = theQuote.Payment_Frequency__c;
        ps.Number_of_Payments__c = getDefaultNumberOfPayments();
        if(ps.Number_of_Payments__c < 1 || ps.Number_of_Payments__c == null)
            ps.Number_of_Payments__c = 1;
        ps.Payment_Amount__c = (theQuote.SBQQ__NetAmount__c - getPaymentTotal()) / ps.Number_of_Payments__c;
        ps.Payment_Total__c = theQuote.SBQQ__NetAmount__c - getPaymentTotal();
        PaymentScheduleWrapper pw = new PaymentScheduleWrapper();
        pw.counter = payments.size();
        pw.payment=ps;
        payments.add(pw);
        theQuote.SBQQ__TargetCustomerAmount__c = this.getPaymentTotal();
        return null;
    }

    public PageReference save() {
        //US-0004942 - Removed Validation due to multicurrency CAD issue where payment total isn't matching up with net amount
        /*if(getPaymentTotal() != theQuote.SBQQ__NetAmount__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Payment total does not match quote total'));
            return null;
        }*/
        List<Payment_Schedule__c> pmts = new List<Payment_Schedule__c>();
        for(PaymentScheduleWrapper pw : payments)
            pmts.add(pw.payment);
        upsert pmts;
        if(pmtsToDelete.size() > 0)
            delete pmtsToDelete;
       
        SBQQ__Quote__c q = new SBQQ__Quote__c(Id=theQuote.Id);
        q.Show_Payment_Schedule__c = payments.size() > 0;
        update q;
        return new PageReference('/'+theQuote.Id);
    }

    public PageReference cancel() {
       return new PageReference('/'+theQuote.Id);
    }
}