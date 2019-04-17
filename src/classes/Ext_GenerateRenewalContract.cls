public with sharing class Ext_GenerateRenewalContract {

	private final Opportunity opp;
    public Boolean showButton{get;set;}
    public String quoteId{get;set;}
    public String oppType{get;set;}

    public Ext_GenerateRenewalContract(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
    }

    public void RunThat()
    {
    	try
    	{
    		List<Agreed_Price__c> lst_AP = new List<Agreed_Price__c>();
    		Map<String, Agreed_Price__c> map_AP = new Map<String, Agreed_Price__c>();
    		if(opp.Renew_Contract_Option__c == 'Don\'t Renew Contract')
	    	{
	    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Renew Contract option set to do not renew.  ');
	            ApexPages.addMessage(myMsg);
	    	}
	    	else if(opp.SBQQ__PrimaryQuote__c != null)
	    	{
	    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Renewal Quote already exists. ');
	            ApexPages.addMessage(myMsg);
	    	}
	    	else if(opp.Renew_Contract_Option__c == null)
	    	{
	    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Renewed Contract option field needs to be populated.  ');
	            ApexPages.addMessage(myMsg);
	    	}
	    	else if(opp.SBQQ__RenewedContract__c == null)
	    	{
	    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Can not generate a renewal quote on a non-renewal Opportunity.  ');
	            ApexPages.addMessage(myMsg);
	    	}
	    	else
	    	{
		        opp.Renewal_Quote_Creation__c = true;
		       	update opp;
		       	System.debug('=== '+opp);
		       	oppType = ApexPages.currentPage().getParameters().get('type');
		       	System.debug('=== '+oppType);
		        String successmessage = 'New '+oppType+' Quote has been created.';
		        showButton = true;
		        quoteId = [SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE id =: this.opp.Id].SBQQ__PrimaryQuote__c;
		        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,successmessage);
	            ApexPages.addMessage(myMsg);
	    	}
    	}
    	catch (Exception e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            ApexPages.addMessage(myMsg);
            system.debug('Opp Failure:' + e.getMessage());
        }
       
    }
    public PageReference returnToPrevious()
    {
        PageReference returnPage = new PageReference('/'+opp.id);  
        return returnPage;
    }

     public PageReference gotoQuote()
    {
        PageReference returntoQuote = new PageReference('/'+ quoteId);  
        return returntoQuote;
    }
}