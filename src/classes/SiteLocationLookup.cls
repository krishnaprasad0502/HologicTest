/*--------------------------------------------------------------------------------------------------------------
Author:         Kasmoor Reddy
Description:    Class which supports the VFPage 'SiteLocationLookup' to display the list of siteLocation records and save 
                the selected record will be added to other VFPage 'AccountsandSites'

History:
<Date>          <Authors Name>         <Brief Description of Change>
1/10/2018        Kasmoor Reddy          Initial Creation(US3714) 

----------------------------------------------------------------------------------------------------------------*/
public class SiteLocationLookup {
    //Variable declarations
    private integer totalRecs = 0;
    private integer OffsetSize = 0;
    private integer LimitSize= 10;  
    public List<InnerClass> ShiptositeQuote {set;get;}
    public List<InnerClass> Shiptositeline {set;get;}
    public String searchStringLine {get;set;}
    public String searchStringbill {get;set;}
    public String searchStringdelv {get;set;}
    public String searchStringbillline {get;set;}
    public String searchStringdelvline {get;set;}
    public List<InnerClass> DelvtositeQuote {set;get;}
    public List<InnerClass> Delvtositeline{set;get;}
    public List<InnerClass> BilltositeQuote {set;get;}
    public List<InnerClass> Billtositeline {set;get;}
    public static Id shipToAccount{get;set;}
    public static Id shipToAccountline{get;set;}
    public  static List<Site_Location__c> siterecords{get;set;}
    public String shiptositepopup{get;set;}
    public String shiptositepopupline{get;set;}
    public String billtositepopup{get;set;}
    public String billtositepopupline{get;set;}
    public String devtositepopup{get;set;}
    public String devtositepopupline{get;set;}
    public String shiptositeadd{get;set;}
    //public id billtositeidd {get;set;}
    public String shiptositeaddline{get;set;}
    public String billtositeadd{get;set;}
    public String billtositeaddline{get;set;}
    public String devtositeadd{get;set;}
    public String devtositeaddline{get;set;}
    public Integer a{get;set;}
    public String searchString{get;set;}
    public String shiptositepopupid{get;set;}
    public String shiptositepopuplineid{get;set;}
    public String billtositepopupid{get;set;}
    public String billtositepopuplineid{get;set;}
    public String devtositepopupid{get;set;}
    public String devtositepopuplineid{get;set;}
    public String shiptositeaddid{get;set;}
    public String shiptositeaddlineid{get;set;}
    public String billtositeaddid{get;set;}
    public String billtositeaddlineid{get;set;}
    public String devtositeaddid{get;set;}
    public String devtositeaddlineid{get;set;}
    public static Id BillToAccount{get;set;}
    public static Id BillToAccountline{get;set;}
    public static Id DelvToAccount{get;set;}
    public static Id DelvToAccountline{get;set;}
    public string qlsize {get;set;}
    public Integer linenumber{get;set;}
    public string quotelineid {get;set;}
    private boolean flag=false;
/*-----------------------------------------------------------------------------
Author:      Kasmoor Reddy
Company:     Apps Associates
Description: Constructor for Variable initializion and calling the method which 
fetches Site LOcation records.
Returns:     N/A

History:
<Date>          <Authors Name>             <Brief Description of Change>
1/10/2018        Kasmoor Reddy              Initial Creation(US3714) 

-----------------------------------------------------------------------------------*/
    public SiteLocationLookup(){
        //Inner Class Variable Initilization
        ShiptositeQuote=new List<InnerClass>();
        DelvtositeQuote=new List<InnerClass>();
        BilltositeQuote=new List<InnerClass>();
        Billtositeline=new List<InnerClass>();
        Shiptositeline=new List<InnerClass>();
        Delvtositeline=new List<InnerClass>();
        //Calling a method to display site location records based on certain criteria
        displayRecords();
    }
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Method to Display Records Initially based on the intial criteria 
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    1/10/2018     Kasmoor Reddy        Initial Creation (US3714)
-----------------------------------------------------------------------------------*/   
    public void displayRecords()
    {
        //Variable declarations and intilization,fecthing values from URL(Values passed from other VFPage)
        linenumber=Integer.valueOf(ApexPages.currentPage().getParameters().get('linenum'));
        a=Integer.valueOf(ApexPages.currentPage().getParameters().get('a'));
        id shipid = ApexPages.currentPage().getParameters().get('oN');
        id shipidline = ApexPages.currentPage().getParameters().get('oN1');
        id billid = apexpages.currentPage().getParameters().get('billaccid');
        system.debug(billid);
        id delvid = apexpages.currentPage().getParameters().get('delaccid');
        id delvidline= apexpages.currentPage().getParameters().get('delaccid1');
        system.debug('delvid----'+delvid);
        system.debug('delvidline----'+delvidline);
        id billidline = apexpages.currentPage().getParameters().get('billaccid1');
        system.debug(billidline);
        quotelineid= apexpages.currentPage().getParameters().get('qlineid');
        qlsize = apexpages.currentPage().getParameters().get('qlsize');
        
        if(shipid != null){
            //Fecthing the ParentId from Account Record based on a criteria
            shipToAccount=[select ParentId from Account where id=:shipid ].id;
            system.debug('shipToAccount---'+shipToAccount);
        }
        if(shipidline != null){
            //Fecthing the ParentId from Account Record based on a criteria
            shipToAccountline=[select ParentId from Account where id=:shipidline].id;
            system.debug('shipToAccount---'+shipToAccount);
        }
        
        if(billid != null){
            //Fecthing the ParentId from Account Record based on a criteria
            BillToAccount=[select ParentId from Account where id=:billid ].id;
            system.debug('BillToAccount---'+BillToAccount);
        }
        if(billidline != null){
            //Fecthing the ParentId from Account Record based on a criteria
            BillToAccountline=[select ParentId from Account where id=:billidline ].id;
            system.debug('BillToAccount---'+BillToAccount);
        }
        
        if(delvid != null){
            //Fecthing the ParentId from Account Record based on a criteria
            DelvToAccount=[select ParentId from Account where id=:delvid ].id;
            system.debug('DelvToAccount---'+DelvToAccount);
        }
        if(delvidline != null){
            //Fecthing the ParentId from Account Record based on a criteria
            DelvToAccountline=[select ParentId from Account where id=:delvidline ].id;
            system.debug('DelvToAccount---'+DelvToAccount);
        }
        
        
        
        
        if(shipToAccount != null)//check whether the fetched ParentId is null or not
        {
             
            //If not null then fetch the corresponding records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :shipToAccount and RecordType.Name='Site']);
            system.debug(acc);
            //Based on the fetched Account, get the Site Location record and add to a list.
            totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true];
            system.debug(totalRecs);
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true LIMIT :LimitSize OFFSET :OffsetSize];
            system.debug(siterecords);
            system.debug('siterecords---'+siterecords.size());
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
             
                //Add the fetched siterecords to Inner Class Variable 
               if(addrLine3 == ''  && addrLine2 == ''){

                  ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }

              
                
            }
        }
        
        if(shipToAccountline != null) //check whether the fetched ParentId is null or not
        {
             //If not null then fetch the corresdoing records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :shipToAccountline and RecordType.Name='Site']);
             totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true];
             //Based on the fetched Account, get the Site Location record and add to a list 'siterecords'.
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true LIMIT :LimitSize OFFSET :OffsetSize];
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                //Add the fetched siterecords to Inner Class Variable
                 if(addrLine3 == ''  && addrLine2 == ''){

                  Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
             
                
            }
        }
        if(BillToAccount != null)//check whether the fetched ParentId is null or not
        {
            //If not null then fetch the corresponding records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :BillToAccount and RecordType.Name='Site']);
            totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true];
            //Based on the fetched Account, get the Site Location record and add to a list.
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true order by name LIMIT :LimitSize OFFSET :OffsetSize];
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                //Add the fetched siterecords to Inner Class Variable 
                   if(addrLine3 == ''  && addrLine2 == ''){

                  BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }

                
            }
            
        }
        if(BillToAccountline != null) //check whether the fetched ParentId is null or not
        {
            //If not null then fetch the corresponding records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :BillToAccountline and RecordType.Name='Site']);
            totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true];
            //Based on the fetched Account, get the Site Location record and add to a list.
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true order by name LIMIT :LimitSize OFFSET :OffsetSize];
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                //Add the fetched siterecords to Inner Class Variable
                      if(addrLine3 == ''  && addrLine2 == ''){

                  Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
             
                
            }
            
        }
        
        if(DelvToAccount != null) //check whether the fetched ParentId is null or not
        {
            system.debug('DelvToAccount---'+DelvToAccount);
            //If not null then fetch the corresponding records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :DelvToAccount and RecordType.Name='Site']);
            totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true];
            //Based on the fetched Account, get the Site Location record and add to a list
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true order by name LIMIT :LimitSize OFFSET :OffsetSize];
            system.debug('siterecords---'+siterecords.size());
            
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                //Add the fetched siterecords to Inner Class Variable
           if(addrLine3 == ''  && addrLine2 == ''){

                  DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
              
                system.debug('Delvtosite1----'+DelvtositeQuote);
            }
        }
        if(DelvToAccountline != null) //check whether the fetched ParentId is null or not
        {
            system.debug('DelvToAccount---'+DelvToAccount);
            //If not null then fetch the corresponding records from Account where parentId is the fetched Id
            Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :DelvToAccountline and RecordType.Name='Site']);
            totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true];
            //Based on the fetched Account, get the Site Location record and add to a list.
            siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true order by name LIMIT :LimitSize OFFSET :OffsetSize];
            system.debug('siterecords---'+siterecords.size());
            for (Site_Location__c s : siterecords) {
                String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                
                //Add the fetched siterecords to Inner Class Variable
               if(addrLine3 == ''  && addrLine2 == ''){

                  Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
              
                system.debug('Delvtosite1----'+Delvtositeline);
            }
            
        }
    }
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Search method to fetch records based on the user given input in Input Text
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    1/10/2018     Kasmoor Reddy        Initial Creation (US3714)
-----------------------------------------------------------------------------------*/   
    public pagereference Search() //Method is invoked to search records based on the user given input in Search Textbox 
    {
        
        // Clear the already searched records (in displayrecords method) and display based on search criteria
        ShiptositeQuote.clear(); 
        BilltositeQuote.clear(); 
        DelvtositeQuote.clear();
        Delvtositeline.clear();
        Shiptositeline.clear();
        Billtositeline.clear();
        system.debug('in search');
      if(flag==false)
      {
             LimitSize =10;
             OffsetSize =0;
      }
        
        if(searchString!=null&&searchString!='') // If Search String is not null ( User entered the input )
        {
            system.debug(searchString);
            
            
            shipToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('oN') ].id;
            system.debug('shipToAccount---'+shipToAccount);
            
            //check whether the fetched ParentId is null or not
            if(shipToAccount != null){
                
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :shipToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchString+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,
                             Name,
                             Bill_To__c,
                             Ship_To__c,
                             Address_Line_1__c,
                             Address_Line_2__c, 
                             Deliver_To__c, 
                             Account__c, 
                             Account__r.Name, 
                             Address_Line_3__c, City__c, State__c 
                             from Site_Location__c 
                             where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchString+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                system.debug(siterecords);
                system.debug('records size'+siterecords.size());
                if(siterecords.size()==0)
                {
                    //If no records are in siterecords list then clear the Inner Class variable which is used to display in VFPage
                    ShiptositeQuote.clear();
                    
                } 
                else
                {
                    for (Site_Location__c s : siterecords) {
                        String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                        String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                        
                        //Add the fetched siterecords to Inner Class Variable 
                        if(addrLine3 == ''  && addrLine2 == ''){

                  ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  ShiptositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
                        system.debug('ShiptositeQuote----'+ShiptositeQuote);
                    }
                }
                
            }
        }
        else if(searchStringline!=null&&searchStringline!='') // If Search String is not null ( User entered the input )
        {
            shipToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('oN1') ].id;
            system.debug('shipToAccount---'+shipToAccount);
            
            //check whether the fetched ParentId is null or not
            if(shipToAccount != null){
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :shipToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringline+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Ship_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringline+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                for (Site_Location__c s : siterecords) {
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                    String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                    
                    //Add the fetched siterecords to Inner Class Variable 
                 if(addrLine3 == ''  && addrLine2 == ''){

                  Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Shiptositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }

                    
                }
                
            }
        }
        
        else if(searchStringbill!=null&&searchStringbill!='') // If Search String is not null ( User entered the input )
        {
            BillToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('billaccid') ].id;
            system.debug('BillToAccount---'+BillToAccount);
            system.debug(searchStringbill);
            //check whether the fetched ParentId is null or not
            if(BillToAccount != null){
                
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :BillToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringbill+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringbill+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                for (Site_Location__c s : siterecords) {
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                    String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                    
                    //Add the fetched siterecords to Inner Class Variable
                   if(addrLine3 == ''  && addrLine2 == ''){

                  BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  BilltositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
                    system.debug(BilltositeQuote);
                }
                
            }
        }
        else if(searchStringbillline!=null&&searchStringbillline!='') // If Search Input is not null ( User entered the input )
        {
            BillToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('billaccid1') ].id;
            system.debug('BillToAccount---'+BillToAccount);
            //check whether the fetched ParentId is null or not
            if(BillToAccount != null){
                
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :BillToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringbillline+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Bill_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringbillline+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                for (Site_Location__c s : siterecords) {
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                    String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                    
                    //Add the fetched siterecords to Inner Class Variable 
                                         if(addrLine3 == ''  && addrLine2 == ''){

                  Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Billtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
                    system.debug('Billtositeline----'+Billtositeline);
                }
                
            }
        }
        
        else if(searchStringdelv!=null&&searchStringdelv!='')// If Search String is not null ( User entered the input )
        {
            //system.debug('delaccid----'+delaccid);
            DelvToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('delaccid') ].id;
            system.debug('DelvToAccount---'+DelvToAccount);
            
            if(DelvToAccount != null)//check whether the fetched ParentId is null or not
            {
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :DelvToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringdelv+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,Name,Bill_To__c,Ship_To__c, Address_Line_1__c,Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringdelv+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                for (Site_Location__c s : siterecords) {
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                    String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                    
                    //Add the fetched siterecords to Inner Class Variable 
                  if(addrLine3 == ''  && addrLine2 == ''){

                  DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  DelvtositeQuote.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
                    system.debug('DelvtositeQuote----'+DelvtositeQuote);
                }
                
            }
        }
        else if(searchStringdelvline!=null&&searchStringdelvline!='') // If Search String is not null ( User entered the input )
        {
            //system.debug('delaccid1----'+delaccid1);
            DelvToAccount=[select ParentId from Account where id=:apexpages.currentPage().getParameters().get('delaccid1') ].id;
            system.debug('DelvToAccount---'+DelvToAccount);
            //check whether the fetched ParentId is null or not
            if(DelvToAccount != null){
                
                //If not null then fetch the corresponding records from Account where parentId is the fetched Id
                Map<id,Account> acc=new map<id,Account>([Select id, ParentID, Name from Account where ParentID = :DelvToAccount and RecordType.Name='Site']);
                totalRecs=[select count() from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringdelvline+'%'];
                //Get Site Location Records for the Fetched Account id,Address_Line_1 match with the entered search String and other conditions ( Active =true )
                siterecords=[select id,Name,Bill_To__c,Ship_To__c,Address_Line_1__c, Address_Line_2__c, Deliver_To__c, Account__c, Account__r.Name, Address_Line_3__c, City__c, State__c from Site_Location__c where Account__c in:acc.keySet() and Deliver_To__c =:true and Active__c =:true and Address_Line_1__c like: '%'+searchStringdelvline+'%' LIMIT :LimitSize OFFSET :OffsetSize];
                for (Site_Location__c s : siterecords) {
                    String addrLine2=(s.Address_Line_2__c==NULL) ? '' : s.Address_Line_2__c;
                    String addrLine3=(s.Address_Line_3__c==NULL) ? '' : s.Address_Line_3__c;
                    
                    //Add the fetched siterecords to Inner Class Variable 
                    if(addrLine3 == ''  && addrLine2 == ''){

                  Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + s.City__c + ',  ' + s.State__c));      

                }

                else if(addrLine2 == ''){

                     Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 == ''){

                     Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + s.City__c + ',  ' + s.State__c));

                }

                else if(addrLine3 != null && addrLine2 != null){

                  Delvtositeline.add(new InnerClass(s.Id, s.Name + '  |  ' + addrLine2 + '  |  ' + addrLine3 + '  |  ' + s.City__c + ',  ' + s.State__c));       

                }
                    system.debug('Delvtositeline----'+Delvtositeline);
                }
                
            }
        }
        else
        {
            displayRecords(); //if all the Search Input's are empty then call the method which displayed records with initial criteria.
        }
        flag=false;
        return null;
    }
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: When user select's any one of the record from displayed records then store the selected record into a variable
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    1/10/2018     Kasmoor Reddy        Initial Creation (US3714)
-----------------------------------------------------------------------------------*/     
    
    public void onselect()
    {
        //clear the String to store the newly selected record each time
        shiptositeadd='';
        shiptositeaddline='';
        billtositeadd='';
        devtositeadd='';
        devtositeaddline='';
        billtositeaddline='';
        shiptositeaddid='';
        shiptositeaddlineid='';
        billtositeaddid='';
        devtositeaddid='';
        devtositeaddlineid='';
        billtositeaddlineid='';
        
        //get the selected record by fetching valy=ue from the parameter passed from the VFPage
        shiptositeadd =apexpages.currentPage().getParameters().get('shiptositepopup'); 
        shiptositeaddline =apexpages.currentPage().getParameters().get('shiptositepopupline'); 
        shiptositeaddid =apexpages.currentPage().getParameters().get('shiptositepopupid'); 
        shiptositeaddlineid =apexpages.currentPage().getParameters().get('shiptositepopuplineid'); 
        
        billtositeadd =apexpages.currentPage().getParameters().get('billtositepopup'); 
        billtositeaddline =apexpages.currentPage().getParameters().get('billtositepopupline'); 
        billtositeaddid =apexpages.currentPage().getParameters().get('billtositepopupid'); 
        billtositeaddlineid=apexpages.currentPage().getParameters().get('billtositepopuplineid'); 
        
        devtositeadd =apexpages.currentPage().getParameters().get('devtositepopup'); 
        devtositeaddline =apexpages.currentPage().getParameters().get('devtositepopupline'); 
        devtositeaddid =apexpages.currentPage().getParameters().get('devtositepopupid'); 
        
        devtositeaddlineid =apexpages.currentPage().getParameters().get('devtositepopuplineid'); 
        system.debug('shiptositeid'+shiptositeaddid);
        system.debug('shiptositeilined'+shiptositeaddlineid);
        
        
        system.debug('billtositeadd'+billtositeadd);
        system.debug('billtositeaddline'+billtositeaddline);
        system.debug('billtositeaddid'+billtositeaddid);
        system.debug('billtositeaddlineid'+billtositeaddlineid);
        
        
        
    }
public void previous()
{
OffsetSize = OffsetSize-LimitSize;
   
    Search();
    
}
public void next()
{
OffsetSize = OffsetSize + LimitSize;
   flag=true;
    Search();
    
}
public boolean getprev()
{
if(OffsetSize == 0)
return true;
else
return false;
}
public boolean getnxt()
{
if((OffsetSize + LimitSize) > totalRecs)
return true;
else
return false;
}
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Inner Class to store the records which need to be displayed in VFPage
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    1/10/2018     Kasmoor Reddy        Initial Creation (US3714)
-----------------------------------------------------------------------------------*/ 
    public class InnerClass{
        //Variable Declarations for Inner Class
        public ID Site_id {set;get;}
        public String Site_Address {set;get;}
       
/*-----------------------------------------------------------------------------
    Author:      Kasmoor Reddy
    Company:     Apps Associates
    Description: Inner Class Constructor to get records from other method (in Outer Class - SiteLocationLookup)
    Returns:     N/A
      
    History:
    <Date>         <Authors Name>      <Brief Description of Change>
    1/10/2018     Kasmoor Reddy        Initial Creation (US3714)
-----------------------------------------------------------------------------------*/ 
        public Innerclass(ID Site_id,String Site_Address)
        {
            //Initialization of variables and storing the values passed from other methods.
            this.Site_id=Site_id;
            this.Site_Address=Site_Address;
            
        }
    }
}