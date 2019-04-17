public class opportunitySiteContact {

    public Opportunity oppty {get;set;}
    String opptyId;
    public Id accId;
    public List<AccountContactRelation> contactList = new List<AccountContactRelation>();
    
    public List<SelectOption> contactOptions { get;set; }
    
    public Boolean isLightning {get;set;}
    public String redirectUrl {get; set;}
    
   
    public opportunitySiteContact(ApexPages.StandardController controller) {
        this.oppty = (Opportunity)controller.getRecord();
        
        if(UserInfo.getUiTheme() == 'Theme4d')
            isLightning = True;
        else
            isLightning = False;
        
        
        if(oppty != null)
            accId = [SELECT AccountId from Opportunity where Id = :oppty.Id].AccountId;
            
        getContactList();
        
    }
    
   
    public void getContactList(){
        if(accId != null)
            contactList = [SELECT ContactId, Contact.Name from AccountContactRelation where AccountId = :accId and IsActive = true];
        
        System.debug('contactList:'+contactList);
        
        if(contactList.size() > 0){
            contactOptions = new List<SelectOption>();
            contactOptions.add(new SelectOption('','--None--'));
            for(AccountContactRelation con : contactList){
                contactOptions.add(new SelectOption(con.ContactId,con.Contact.Name));
            }
        }
            
        
    }
    
    
    public PageReference saveSiteContact(){
    
        PageReference pageRef = new PageReference('/'+oppty.Id);
        //pageRef.setRedirect(true);
    
        System.debug('Hello World');
        
        update oppty;
        
        //Redirect = true;
        
        if(UserInfo.getUiTheme() == 'Theme4d'){
            redirectUrl = '/one/one.app?source=aloha#/sObject/'+oppty.Id+'/view';
            //isLightning = true;
        }
        else
            redirectUrl = '/'+oppty.Id;
            
        System.debug('redirectURL:'+redirectUrl);
        
        return pageRef;    
    }
    
    
    public PageReference cancelSiteContact(){
    
        PageReference pageRef = new PageReference('/'+oppty.Id);
        return pageRef;
    }

}