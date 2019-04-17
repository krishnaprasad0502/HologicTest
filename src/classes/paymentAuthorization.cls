/*------------------------------------------------------------
Author:        Mani Sundaresan
Description:   Controller class for PaymentLightning vf page used to integrate with paymetrics.
Test Class:    paymentAuthorization_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
07/24/2018     Mani Sundaresan   Initial Creation (US-0004314)
11/01/2018     Krishna           Fixed issue with billToSiteId (US-0005957)
------------------------------------------------------------*/
public without sharing class paymentAuthorization{

    //Variable Declaration section    
    private static String m_strURL;
    private static String m_strGUID;
    private static String m_strPSK;
    public String iFrameUrl {get; set;}
    public String accessToken {get; set;}
    public String signature {get; set;}
    public static Boolean storeCC {get; set;}
    public String ccToken {get; set;}
    public String ccName {get; set;}
    public String ccType {get; set;}
    public String ccCVV {get; set;}
    public String ccExpMonth {get; set;}
    public String ccExpYear {get; set;}
    public String ccStatusCode {get; set;}
    public Decimal ccAmount {get; set;}
    public String paymetricmsg {get; set;}
    public Id paymentCardId;
    public Boolean isTokenGenerated{set; get;}
    public static String ccAuthCode{get; set;}
    public static String txId{get; set;}
    public static String avsCode{get; set;}
    public static Boolean isAuthorized{get; set;}
    public static Paymetrics_Creds__mdt paymentInfo = new Paymetrics_Creds__mdt();
    public static string orgName;
    public Payment_Card__c pc;
    List<Payment_Card__c> pcList;
    public Payment__c payment;
    public List<Payment__c> paymentList = new List<Payment__c>();
    public PageReference retURL;
    public static Map<String, String> cardTypes = new Map<String, String> {
            'vi' => 'Visa',
            'mc' => 'Mastercard',
            'ax' => 'Amex',
            'di' => 'Discover',
            'Visa' => 'Visa',
            'Mastercard' => 'Mastercard',
            'Amex' => 'Amex',
            'Discover' => 'Discover'
            
        };
    public String amount{get; set;}    
    public Account acc{get; set;}
    public Id recId{get; set;}
    public sObject obj{get; set;}
    public Id recordId;
    public Id recAccId;
    public Order ord;
    public WorkOrder wo;
    public ServiceContract svc;
    public SBQQ__Quote__c quote;
    public List<Payment_Card__c> selectedCards {get; set;}
    public List<Payment_Card__c> removeCards {get; set;}
    public List<existingCardsWrapper> existingCardsList{get; set;}
    public Boolean existingCard{get; set;}
    public String siteLocRec{get; set;}
    public List<Account> siteLocRecList{get; set;}
    public Boolean isAccount{get; set;}
    public Decimal recAmt{get; set;}
    public String merchId = '';
    public String currencyKey {get; set;}
    public Schema.SObjectType objType{get; set;}
    Integer currentMonth = Date.Today().month();
    Integer currentYear = Date.Today().year();
    String poNumber = '';
    public Boolean newCardSec{get; set;}
    Map<String, Customer_Relationship__x> CustRelMap = new Map<String, Customer_Relationship__x>();
    List<Account>  Acclist = new List<Account> ();
    public string index {get; set;}
    public String billToAcct {get;set;}
    public Id billToSiteId {get; set;}
    public String billToSite {get;set;}
    Map<String,Payment_Card__c> allPaymentCardsMap = new Map<String,Payment_Card__c>();
    public Boolean isPaymentCreated {get; set;}
    public Boolean isPaymentExceeded {get; set;}
    public Decimal totalPayment = 0;
    public Boolean isPaymentExists {get; set;}
    public Configuration_Settings__c configSetting = Configuration_Settings__c.getOrgDefaults();
    public Site_Location__c siteLoc = new Site_Location__c();
    
    public Configuration_Settings__c getconfigSetting(){
        return configSetting;
    }

    //Fetch paymetric creds from custom metadata types
    static{
        
        String instanceName = [select Id from Organization limit 1].Id;
        System.debug('instanceName:'+instanceName);
        List<Paymetrics_Creds__mdt> paymentCreds = [SELECT MasterLabel, iFrame_URL__c, GUID__c, Shared_Key__c, UserName__c, Password__c, Organization_Id__c from  Paymetrics_Creds__mdt];
        System.debug('paymentCreds:'+paymentCreds);
        if(paymentCreds.size() > 0){
            for(Paymetrics_Creds__mdt payment : paymentCreds){
                if(instanceName.equalsIgnoreCase(payment.Organization_Id__c)){
                    m_strURL = payment.iFrame_URL__c;
                    m_strGUID = payment.GUID__c;
                    m_strPSK = payment.Shared_Key__c; 
                    paymentInfo = payment;
                    orgName = payment.MasterLabel;   
                }
                else if(!instanceName.containsIgnoreCase('NA') && payment.MasterLabel.containsIgnoreCase('sandbox') && m_strURL == null){
                    m_strURL = payment.iFrame_URL__c;
                    m_strGUID = payment.GUID__c;
                    m_strPSK = payment.Shared_Key__c;    
                    paymentInfo = payment;
                    orgName = payment.MasterLabel;
                }
            }
        }
        else
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Paymetric iFrame credentials not available!!!'));    
        
    }
    
    //Constructor to determine the object on which the payment is being initiated
    //11/01/2018     Krishna           Fixed issue with billToSiteId (US-0005957)
                                       // implented error messages (US-0005957)
  
    
    public paymentAuthorization() {
        
 
        System.debug('Id:'+ApexPages.currentPage().getParameters().get('Id'));
        System.debug('recId:'+recId);
        if(ApexPages.currentPage().getParameters().get('Id') == null)
            recId = (Id)ApexPages.currentPage().getParameters().get('retURL').substring(1,16);
        else 
            recId = (Id)ApexPages.currentPage().getParameters().get('Id').substring(0,15);
        objType = recId.getsobjecttype();
        System.debug('objType:'+objType);
        
        String query = '';
        if(recId.getsobjecttype() == Order.sObjectType)
            query = 'SELECT Id, AccountId, CurrencyIsoCode, TotalAmount, Name, Payment__c, Bill_To_Site_Location__r.Id FROM ' + objType +' WHERE Id = \'' + recId+'\'';
        else if(recId.getsobjecttype() == WorkOrder.sObjectType)
            query = 'SELECT Id, AccountId, CurrencyIsoCode, SYS_Total_Price__c, Payment__c, WorkOrderNumber, WorkType.Name, Estimate_Final_Amount__c, Asset.Bill_To_Location__r.Id FROM ' + objType +' WHERE Id = \'' + recId+'\'';
        else if(recId.getsobjecttype() == ServiceContract.sObjectType)
            query = 'SELECT Id, AccountId, CurrencyIsoCode, GrandTotal, Name, Payment__c, Bill_To_Site_Location__r.Id FROM ' + objType +' WHERE Id = \'' + recId+'\'';
        else if(recId.getsobjecttype() == SBQQ__Quote__c.sObjectType)
            query = 'SELECT Id, SBQQ__Account__c, CurrencyIsoCode, Name, SBQQ__CustomerAmount__c, BillTo_Site__r.Id FROM ' + objType + ' WHERE Id = \'' + recId + '\'';
        System.debug('query:'+query);
        existingCardsList = new List<existingCardsWrapper>();
        existingCard = false; 
        newCardSec = false;
        isPaymentCreated = false;
        isPaymentExceeded = false;
        isPaymentExists = false;
        
        if(String.valueOf(recId).startswith('001')){
            isAccount = true;
            acc = [SELECT Id, Name, Oracle_Party_Id__c, Oracle_Customer_Number__c, CurrencyIsoCode,AccountNumber, (SELECT Id, Name, Bill_To_Site_Location__r.Id, Credit_Card_Type__c, Credit_Card_Last_4__c, Credit_Card_Name_on_Card__c, Credit_Card_Expiration_Month__c, Credit_Card_Expiration_Year__c, Credit_Card_Token__c, Account__c from Payment_Card__r) from Account where Id = :recId];
            for(Payment_Card__c pc : acc.Payment_Card__r){
                System.debug('Inside Card:'+pc);
                existingCardsList.add(new existingCardsWrapper(pc));
            }
            System.debug('Alert:'+acc.Oracle_Party_Id__c);
            if(acc != null && acc.Oracle_Party_Id__c != null){
                for (Customer_Relationship__x c : [select PartyId__c, Bill_To__c,Customer_Account_ID__c,Operating_Unit__c,Relationship_ID__c,Ship_To__c,Status__c,Status_Code__c 
                                                   from Customer_Relationship__x where (PartyId__c =:acc.Oracle_Party_Id__c or Related_Oracle_Party_ID__c = :acc.Oracle_Party_Id__c) AND Status__c = 'Active']) {
                                                       CustRelMap.put(c.PartyId__c, c);
                                                   }
               if(CustRelMap.size() > 0){
                     siteLocRecList = [SELECT Id, Name, Oracle_Party_Id__c, Oracle_Customer_Number__c from Account where Oracle_Party_ID__c in :CustRelMap.keyset() Order By Name];
                     System.debug('Acclist:'+siteLocRecList.size());
                     System.debug('Acclist:'+siteLocRecList);
               }                                    
            }
        }else
            obj = Database.query(query);
        
        if(recId.getsobjecttype() == Order.sObjectType){
            ord = (Order)obj;
            recordId = ord.id;
            recAccId = ord.AccountId;
            if(configSetting.Uplift_Percentage__c != null)
                recAmt = ord.TotalAmount + (ord.TotalAmount * configSetting.Uplift_Percentage__c/100);
            else
                recAmt = ord.TotalAmount;
            poNumber = 'SvO '+ord.Name;
            SYSTEM.DEBUG('billToSiteId::::1'+ord.Bill_To_Site_Location__r.Id);
            billToSiteId = ord.Bill_To_Site_Location__r.Id;
            billToAcct = ord.AccountId;
            if(ord.Payment__c != null)
                isPaymentExists = true;
            if(ord.CurrencyIsoCode == 'USD'){
                merchId = '177506';
                currencyKey = 'USD';
            }
            else if(ord.CurrencyIsoCode == 'CAD'){
                merchId = 'CAD_VMAD_FDMSN';
                currencyKey = 'CAD';
            }
            
            for(Payment__c pay : [SELECT Id, Amount__c, Account__c from Payment__c where Order__c = :recordId]){
                totalPayment += pay.Amount__c;
                paymentList.add(pay);
                System.debug('Total Pay:'+totalPayment);
            }
            
        }
        else if(recId.getsobjecttype() == ServiceContract.sObjectType){
            svc = (ServiceContract)obj;
            recordId = svc.id;
            recAccId = svc.AccountId;
            if(configSetting.Uplift_Percentage__c != null)
                recAmt = svc.GrandTotal + (svc.GrandTotal * configSetting.Uplift_Percentage__c/100);
            else
                recAmt = svc.GrandTotal; 
           
            poNumber = 'SvC '+svc.Name;
            SYSTEM.DEBUG('billToSiteId::::2'+svc.Bill_To_Site_Location__r.Id);
            billToSiteId = svc.Bill_To_Site_Location__r.Id;
            billToAcct = svc.AccountId;
            if(svc.Payment__c != null)
                isPaymentExists = true;
            if(svc.CurrencyIsoCode == 'USD'){
                merchId = '177506';
                currencyKey = 'USD';
            }
            else if(svc.CurrencyIsoCode == 'CAD'){
                merchId = 'CAD_VMAD_FDMSN';
                currencyKey = 'CAD';
            }
            for(Payment__c pay : [SELECT Id, Amount__c, Account__c from Payment__c where Service_Contract__c = :recordId]){
                totalPayment += pay.Amount__c;
                paymentList.add(pay);
                System.debug('Total Pay:'+totalPayment);
            }
        }
        else if(recId.getsobjecttype() == WorkOrder.sObjectType){
            wo = (WorkOrder)obj;
            recordId = wo.id;
            if(wo.WorkType != null){
                if(wo.WorkType.Name.containsIgnoreCase('estimate'))
                    recAmt = wo.Estimate_Final_Amount__c + (wo.Estimate_Final_Amount__c * configSetting.Uplift_Percentage__c/100);
                else
                    recAmt = wo.SYS_Total_Price__c + (wo.SYS_Total_Price__c * configSetting.Uplift_Percentage__c/100);
            }
            poNumber = 'SvW '+wo.WorkOrderNumber;
            SYSTEM.DEBUG('billToSiteId::::3'+wo.Asset.Bill_To_Location__r.Id);
            billToSiteId = wo.Asset.Bill_To_Location__r.Id;
            
            if(wo.Payment__c != null)
                isPaymentExists = true;
            
            if(wo.CurrencyIsoCode == 'USD'){
                merchId = '177506';
                currencyKey = 'USD';
            }
            else if(wo.CurrencyIsoCode == 'CAD'){
                merchId = 'CAD_VMAD_FDMSN';
                currencyKey = 'CAD';
            }
            
            recAccId = [SELECT ParentId from Account where Id = :wo.AccountId limit 1].ParentId;
            billToAcct = recAccId;
            for(Payment__c pay : [SELECT Id, Amount__c, Account__c from Payment__c where Work_Order__c = :recordId]){
                totalPayment += pay.Amount__c;
                paymentList.add(pay);
                System.debug('Total Pay:'+totalPayment);
            } 
            
        }
        else if(acc != null){
            poNumber = 'Dep '+acc.AccountNumber;
            
            currencyKey = UserInfo.getDefaultCurrency();
            if(currencyKey == 'USD'){
                merchId = '177506';
                
            }
            else if(currencyKey == 'CAD'){
                merchId = 'CAD_VMAD_FDMSN';
                
            }
        }
        else if(recId.getsobjecttype() == SBQQ__Quote__c.sObjectType){
            quote = (SBQQ__Quote__c)obj;
            recordId = quote.id;
            if(configSetting.Uplift_Percentage__c != null)
                recAmt = quote.SBQQ__CustomerAmount__c + (quote.SBQQ__CustomerAmount__c * configSetting.Uplift_Percentage__c/100);
            else
                recAmt = quote.SBQQ__CustomerAmount__c;
            poNumber = 'SvQ '+quote.Name;
            SYSTEM.DEBUG('billToSiteId::::4'+quote.BillTo_Site__r.Id);
            billToSiteId = quote.BillTo_Site__r.Id;
            if(quote.CurrencyIsoCode == 'USD'){
                merchId = '177506';
                currencyKey = 'USD';
            }
            else if(quote.CurrencyIsoCode == 'CAD'){
                merchId = 'CAD_VMAD_FDMSN';
                currencyKey = 'CAD';
            }
            recAccId = quote.SBQQ__Account__c;
            billToAcct = recAccId;
            for(Payment__c pay : [SELECT Id, Amount__c, Account__c from Payment__c where Quote__c = :recordId]){
                totalPayment += pay.Amount__c;
                paymentList.add(pay);
                System.debug('Total Pay:'+totalPayment);
            } 
        
        }
        
        //Fetch existing payment card details to be displayed on the existing card section
        if(recAccId != null){
            for(Payment_Card__c pc : [SELECT Id, Name, Bill_To_Site_Location__r.Id, Credit_Card_Type__c, Credit_Card_Last_4__c, Credit_Card_Name_on_Card__c, Credit_Card_Expiration_Month__c, Credit_Card_Expiration_Year__c, Credit_Card_Token__c, Account__c from Payment_Card__c where Account__c = :recAccId and Credit_Card_Status__c = 'Active']){
                if(Integer.valueOf(pc.Credit_Card_Expiration_Year__c) > currentYear){
                    existingCardsList.add(new existingCardsWrapper(pc));
                    allPaymentCardsMap.put(pc.Id, pc);
                }
                else if(Integer.valueOf(pc.Credit_Card_Expiration_Year__c) == currentYear && Integer.valueOf(pc.Credit_Card_Expiration_Month__c) >= currentMonth){
                    existingCardsList.add(new existingCardsWrapper(pc));
                    allPaymentCardsMap.put(pc.Id, pc);
                }
            }
        }
            
            
        System.debug('Payment Cards:'+existingCardsList.size());
        System.debug('Payment Cards:'+existingCardsList);    
        /*******************************************Get the token from paymetrics to display the iFrame****************************************/
        System.debug('obj:'+obj);
        isTokenGenerated = false;
        storeCC = false;
        accessToken = getAccessToken();
        System.debug('accessToken:'+accessToken);
        iFrameUrl = m_strURL + '/view/iframe/' + m_strGUID + '/' + accessToken + '/true';
        System.debug('iFrameUrl:'+iFrameUrl); 
        /**************************************************************************************************************************************/   
    
    }
    
    
    
    public String getXiInterceptURL()
    {
        return m_strURL; 
    }
    public String getXiInterceptGUID()
    {
        return m_strGUID; 
    }
    
    public String getXiInterceptPSK()
    {
        return m_strPSK; 
    }
    
    public String getAccessToken()
    {
        String strWhere = 'getAccessToken';
        String strAT = '';
        String strResponse = '';
        String strPostXml = getSignedXML();
        String strURL = m_strURL + '/AccessToken';
        Dom.Document hDoc = null;
        Dom.XmlNode hRoot = null;
        Dom.XmlNode hResponse = null;
        Dom.XmlNode hAT = null;
        
        System.debug('strURL:'+strURL);
        System.debug('strPostXml:'+strPostXml);
        
        hDoc = executeHttpRequest(strURL, strPostXml, 'POST');
        hRoot = hDoc.getRootElement();
        if(hRoot != null)
        {
            hResponse = hRoot.getChildElement('ResponsePacket', null);
            if(hResponse != null)
            {
                hAT = hResponse.getChildElement('AccessToken', null);
                if(hAT != null)
                    strAT = hAT.getText();
            }
        }
        System.debug('Inside access token:'+strAT);
        return strAT; 
    }
    
    private String getSignedXML()
    {
        String strWhere = 'getSignedXML';
        String strXml = getXmlRequest();
        String strPostXml = EncodingUtil.urlEncode(strXml, 'UTF-8');
        String strSignature = EncodingUtil.urlEncode(getDigitalSignature(strXml), 'UTF-8');
        signature = strSignature;
        //st_accessToken = signature;
        String strSigned = 'MerchantGuid=' + m_strGUID + '&' +
                    'SessionRequestType=1&' + 
                    'Packet=' + strPostXml + '&' + 
                    'Signature=' + strSignature + '&' + 
                    'MerchantDevelopmentEnvironment=SalesForce';
        System.debug('strXml:'+strXml);
        System.debug('strPostXml:'+strPostXml);
        System.debug('strSignature:'+strSignature);
        System.debug('strSigned:'+strSigned);
        
        return strSigned;
    }
    
    private static String getDigitalSignature(String strData) 
    {
        String strWhere = 'getDigitalSignature';
        String strSignature = '';
        System.debug('strData:'+strData);
        System.debug('m_strPSK:'+m_strPSK);
        strSignature = EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA256', Blob.valueOf(strData), Blob.valueOf(m_strPSK)));
        
        System.debug('strData:'+strData);
        System.debug('strSignature:'+strSignature);
        
        return strSignature;
    }
    
    private static Dom.Document executeHttpRequest(String targetURL, String urlParameters, String requestType)
    {
        String strWhere = 'executeHttpRequest';
        Dom.Document hDoc = null;
        Http myHttp = new Http();
        HttpRequest httpRQ = new HttpRequest();
        HttpResponse httpRS = null;
        
        System.debug('targetURL:'+targetURL);
        System.debug('requestType:'+requestType);
        System.debug('urlParameters:'+urlParameters);
        
        
        httpRQ.setEndpoint(targetURL);
        httpRQ.setMethod(requestType);
        if(requestType.equalsIgnoreCase('POST'))
        {
            httpRQ.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            httpRQ.setHeader('Content-Length', String.valueOf(urlParameters.Length()));
            httpRQ.setHeader('Content-Language', 'en-US');
            httpRQ.setHeader('Cache-Control', 'no-cache, no-store, max-age=0, must-revalidate');
            httpRQ.setHeader('Pragma', 'no-cache');
            httpRQ.setBody(urlParameters);
        }
        
        httpRS = myHttp.send(httpRQ);
        if(httpRS != null)
        {
            System.debug('httpRS.getBody():'+httpRS.getBody());
            hDoc = httpRS.getBodyDocument();
        }
        else
        {
            hDoc = new Dom.Document();
        }
        
        return hDoc;
    }
    
    public String getXmlRequest()
    {
        String xmlRequest = '';
          xmlRequest += '<cardDropdownSection> ';
          //xmlRequest += '<tag name="div" class="PaymentDetailHeader">Enter your credit card information</tag>';
          xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="cardType" text="Card type: "/>';
          xmlRequest += '<ddlCardType id="cd">';
          xmlRequest += '<items>';
          xmlRequest += '<item for="visa"/>';
          xmlRequest += '<item for="american express"/>';
          xmlRequest += '<item for="mastercard"/>';
          //xmlRequest += '<item for="discover"/>';
          xmlRequest += '</items>';
          xmlRequest += '</ddlCardType>';
          xmlRequest += '</tag>';
          xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="cardNumber" text="Card number: "/>';
          xmlRequest += '<tboxCardNumber tokenize="true"/>';
          xmlRequest += '<validationMsg for="cardNumber" class="valmsg"/>';
          xmlRequest += '</tag>';
          xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="cardholderName" text="Name on card: "/>';
          xmlRequest += '<tboxCardHolderName/>';
          xmlRequest += '<validationMsg for="cardholderName" class="valmsg"/>';
          xmlRequest += '</tag>';
          xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="startMonth" text="start date"/>';
          xmlRequest += '<ddlStartMonth default-text="month" display-format="MMM" class="merchant_combos" required="false"/>';
          xmlRequest += '<ddlStartYear default-text="year" class="merchant_combos" years-to-display="10" required="false" start-date="true"/>';
          xmlRequest += '<validationMsg for="startYear" class="valmsg"/>';
          xmlRequest += '</tag>';
          xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="expMonth" text="Expiration date: "/>';
          xmlRequest += '<ddlExpMonth default-text="month" class="merchant_combos" required="false"/>';
          xmlRequest += '<ddlExpYear default-text="year" class="merchant_combos" years-to-display="10" required="false" exp-date="true"/>';
          xmlRequest += '<validationMsg for="expYear" class="valmsg"/>';
          xmlRequest += '</tag>';
          /*xmlRequest += '<tag name="div">';
          xmlRequest += '<label for="cvv" text="Card CVV: "/>';
          xmlRequest += '<tboxCvv/>';-->
          xmlRequest +='<validationMsg for="cvv" class="valmsg"/>';
          xmlRequest += '<htmlCvvHelp name="div" raise-click="1"></htmlCvvHelp>';
          xmlRequest += '</tag>';*/
          xmlRequest += '</cardDropdownSection>' ;

          String baseUrl = String.valueOf(System.URL.getSalesforceBaseUrl().toExternalForm());
         
          String iframePacketXml = '';
          iframePacketXml += '<?xml version="1.0" encoding="UTF-8"?><merchantHtmlPacketModel xmlns="Paymetric:XiIntercept:MerchantHtmlPacketModel">';
          iframePacketXml += '<iFramePacket>';
          iframePacketXml += '<hostUri>' + baseUrl + '/' + '</hostUri>';
          iframePacketXml += '<cssUri>https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css</cssUri>';
          iframePacketXml += '</iFramePacket>';
          iframePacketXml += '<merchantHtml>';
          iframePacketXml += '<htmlSection class="merchant_paycontent">  ' +   xmlRequest + '</htmlSection>';
          iframePacketXml += '</merchantHtml> </merchantHtmlPacketModel> ';

          return iframePacketXml;
    }
    
    //Method to tokenize the credit card from paymetrics
    public void getCreditCardToken()
    {
        Decimal enteredAmt = 0;
        if(ApexPages.currentPage().getParameters().get('Id') == null)
            recId = (Id)ApexPages.currentPage().getParameters().get('retURL').substring(1,16);
        else 
            recId = (Id)ApexPages.currentPage().getParameters().get('Id').substring(0,15);
        if(recId.getsobjecttype() == Order.sObjectType){
            ord = (Order)obj;
            recordId = ord.id;
            
            recAccId = ord.AccountId;
            
        }
        else if(recId.getsobjecttype() == ServiceContract.sObjectType){
            svc = (ServiceContract)obj;
            recordId = svc.id;
            
            recAccId = svc.AccountId;

        }
        else if(recId.getsobjecttype() == SBQQ__Quote__c.sObjectType){
            quote = (SBQQ__Quote__c)obj;
            recordId = quote.id;
            recAccId = quote.SBQQ__Account__c;

        }
        else if(recId.getsobjecttype() == WorkOrder.sObjectType){
            wo = (WorkOrder)obj;
            recordId = wo.id;
            
            recAccId = [SELECT ParentId from Account where Id = :wo.AccountId limit 1].ParentId; 

        }
        else if(recId.getsobjecttype() == Account.sObjectType)
            recAccId = recId;
         
        if(amount == null || amount == '')
            enteredAmt = 0;
        else
            enteredAmt = Decimal.valueOf(amount);
        
        if(totalPayment == null)
            totalpayment = 0;
        if(recAmt == null)
            recAmt = 0;
            
        
        if(recId.getsobjecttype() != Account.sObjectType && recId.getsobjecttype() != SBQQ__Quote__c.sObjectType && recId.getsobjecttype() != WorkOrder.sObjectType && (enteredAmt + totalPayment > (recAmt + (recAmt * configSetting.Uplift_Percentage__c/100)))){
            isPaymentExceeded = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Authorization amount exceeds the total amount on the record!!!')); 
            
        }
                
        System.debug('AccessToken:'+Apexpages.currentPage().getParameters().get('accessToken'));
        System.debug('signedToken:'+Apexpages.currentPage().getParameters().get('signedToken'));
        String strWhere = 'getCreditCardToken';
        String strStatus = '' + Apexpages.currentpage().getparameters().get('status');
        System.debug('ccAmount:'+ccAmount);
        //ccAmount = Decimal.valueOf(Apexpages.currentpage().getparameters().get('amt'));
        ccAmount = enteredAmt;
        System.debug('ccAmountURL:'+ccAmount);
        String strAccessToken = '';
        String strToken = '';
        Dom.Document hDoc = null;
        Dom.XmlNode hRoot = null;
        Dom.XmlNode hNode = null;

        strAccessToken = Apexpages.currentpage().getparameters().get('accessToken');
        System.debug('strAccessToken:'+strAccessToken);
        
        hDoc = getResponsePacket(strAccessToken);
        /*****mock response*****
            <?xml version="1.0" encoding="utf-8"?>
            <PaymetricResponse xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <Fields>
                    <FormField>
                        <Name>PaymentCreditCard</Name>
                        <Value>-E803-1111-ZRKEN00000000A</Value>
                        <IsToTokenize>true</IsToTokenize>
                    </FormField>
                </Fields>
            </PaymetricResponse>
        */
        hRoot = hDoc.getRootElement(); // <PaymetricResponse>
        
        if(hRoot != null){
            hNode = hRoot.getChildElement('Fields', null);
            if(hNode != null)
            {
                for(Dom.XMLNode child : hNode.getChildElements()){
                    if(child != null && child.getChildElement('Name',null) != null){
                        System.debug('cmon:'+child.getChildElement('Name',null).getText());
                        if(child.getChildElement('Name',null).getText() == 'Card Number')
                            ccToken = child.getChildElement('Value',null).getText();
                        else if(child.getChildElement('Name',null).getText() == 'Card Type')
                            ccType = child.getChildElement('Value',null).getText();
                        else if(child.getChildElement('Name',null).getText() == 'Expiration Month')
                            ccExpMonth = child.getChildElement('Value',null).getText();
                        else if(child.getChildElement('Name',null).getText() == 'Expiration Year')
                            ccExpYear = child.getChildElement('Value',null).getText();
                        else if(child.getChildElement('Name',null).getText() == 'Card Holder Name')
                            ccName = child.getChildElement('Value',null).getText();
                        else if(child.getChildElement('Name',null).getText() == 'Card Security Code')
                            ccCVV = child.getChildElement('Value',null).getText();
                    }
                }
            }    
        }
        
        System.debug('Tokenization response:'+hRoot);
        
        System.debug('Generated Token:'+ccToken);
        System.debug('CCName:'+ccName);
        System.debug('ccType:'+ccType);
        System.debug('ccExpMonth:'+ccExpMonth);
        System.debug('ccExpYear:'+ccExpYear);
        System.debug('ccCVV:'+ccCVV);
        
        if(ccToken != null){
            isTokenGenerated = true;
            System.debug('isTokenGenerated:'+isTokenGenerated);
            System.debug('recId:'+recId);
            
        }else
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Tokenization Failed!!!'));
            
        
        SYstem.debug('paymentCardId:'+paymentCardId);
        
        
    }
    
    private Dom.Document getResponsePacket(String strAccessToken)
    {
        String strWhere = 'getResponsePacket';
        System.debug('str1:'+strAccessToken);
        String strSignature = getDigitalSignature(strAccessToken);
        String strUrlParams = m_strURL + '/ResponsePacket';
        Dom.Document hDoc = null;
        
        strUrlParams += '?MerchantGUID=' + m_strGUID;
        strUrlParams += '&Signature=' + EncodingUtil.urlEncode(strSignature, 'UTF-8');
        strUrlParams += '&AccessToken=' + strAccessToken;
        
        System.debug('strUrlParams:'+strUrlParams);
        hDoc = executeHttpRequest(strUrlParams, '', 'GET');
        System.debug('hDoc.toXmlString():'+hDoc.toXmlString());
        return hDoc;
    }
    
    //Method to authorize payment on the card by Paymetrics
    public PageReference authorizePayment(){
        
        System.debug('ccToken:'+ccToken);
        System.debug('card type:'+ccType);
        System.debug('exp month:'+ccExpMonth);
        System.debug('Exp Year:'+ccExpYear);
        System.debug('card name:'+ccName);
        System.debug('card cvv:'+ccCVV);
        System.debug('amount:'+ccAmount);
        System.debug('existingCard:'+existingCard);
        System.debug('recAccId:'+recAccId);
        System.debug('pc:'+pc);
        System.debug('currencyKey:'+currencyKey);
        System.debug('merchId:'+merchId);
        System.debug('Amtval:'+amount);
        if(amount != null && amount != '')
            ccAmount = Decimal.valueOf(amount);
        else 
            ccAmount = 0;
        System.debug('ccAmount:'+ccAmount);
        
        System.debug('BillToSiteId:'+String.valueOf(billToSiteId));
        System.debug('BillToAccount:'+String.valueOf(billToAcct));
        
        if(String.valueOf(billToSiteId) != null && String.valueOf(billToSiteId) != ''){
            System.debug('billToSiteId:'+billToSiteId);
            siteLoc = [SELECT Id, Name, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Address_Line_4__c, City__c, Country__c, State__c, Zip_Code__c from Site_Location__c where Id = :billToSiteId];
        }
        
        //Get details from the existing card if selected
        selectedCards = new List<Payment_Card__c>();
        if(existingCardsList.size() > 0){
            for(existingCardsWrapper cardWrapObj : existingCardsList){
                System.debug('cardWrapObj:'+cardWrapObj);
                System.debug('selected:'+cardWrapObj.selected);
                if(ccAmount  != null && ccAmount != 0 && cardWrapObj.selected == true){
                    System.debug('selected Card:'+cardWrapObj.payCard);
                    selectedCards.add(cardWrapObj.payCard);
                    System.debug('Selected Card:'+cardWrapObj.payCard.Credit_Card_Name_on_Card__c);
                    ccToken = cardWrapObj.payCard.Credit_Card_Token__c;
                    ccType = cardWrapObj.payCard.Credit_Card_Type__c;
                    ccExpMonth = String.valueOf(cardWrapObj.payCard.Credit_Card_Expiration_Month__c);
                    ccExpYear = String.valueOf(cardWrapObj.payCard.Credit_Card_Expiration_Year__c);
                    ccName = cardWrapObj.payCard.Credit_Card_Name_on_Card__c;
                    ccCVV = '';
                    ccAmount = ccAmount;
                    acc = new Account(Id=cardWrapObj.payCard.Account__c);
                    pc = cardWrapObj.payCard;
                    billToSiteId = cardWrapObj.payCard.Bill_To_Site_Location__c;
                    System.debug('selectedCardsSize:'+selectedCards.size());
                }
            }
        }
        System.debug('selectedCards:'+selectedCards.size());
        System.debug('ccToken:'+ccToken);
        System.debug('ccAmount:'+ccAmount);
        System.debug('newCardSec:'+newCardSec);
        
        if(ccAmount == 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Enter an amount to authorize the payment.'));
            return null;
        }
        else if(selectedCards.size() == 0 && (ccToken == '' || ccToken == null)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Choose an option provided on the page to authorize the payment.'));
            return null;
        }
        if(isPaymentExceeded){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Authorization request amount exceeds the total amount on the record!!!')); 
            return null;
        }
        
        String sObjName = recId.getSObjectType().getDescribe().getName();
        
        if(sObjName== 'Account' && billToAcct != null && (billToSiteId == null || String.valueOf(billToSiteId) == '')){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a Bill To Site to process the payment card.')); 
            return null;
        }
        else if(sObjName== 'WorkOrder' && billToSiteId == null){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Card cannot be processed missing billing information on Asset related to '+ recId.getsobjecttype() )); 
             return null;
        }
        else if(billToSiteId == null || billToAcct == null){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Card cannot be processed missing billing information on '+ recId.getsobjecttype())); 
             return null;
        }
        
        System.debug('ccExpMonth:'+ccExpMonth);
        SYstem.debug('ccExpYear:'+ccExpYear);
        String auth1 = 'http://schemas.xmlsoap.org/soap/envelope/';
        String auth2 = 'http://Paymetric/XiPaySoap30/message/';
        
        if(ApexPages.currentPage().getParameters().get('Id') == null)
            recId = (Id)ApexPages.currentPage().getParameters().get('retURL').substring(1,16);
        else 
            recId = (Id)ApexPages.currentPage().getParameters().get('Id').substring(0,15);
        
        System.debug('paymentInfo.UserName__c:'+paymentInfo.UserName__c);
        System.debug('paymentInfo.Password__c:'+paymentInfo.Password__c);
        
        poNumber = poNumber.length() <= 17 ? poNumber : poNumber.substring(0,17);
        
        /***************************************XML request to be sent to paymetrics************************************************/
        String authXMLRequest = '<soapenv:Envelope xmlns:mes="http://Paymetric/XiPaySoap30/message/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">';
        authXMLRequest += '<soapenv:Header>';
        authXMLRequest += '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">';
        authXMLRequest += '<wsse:UsernameToken wsu:Id="UsernameToken-AE9C8EEAAF31B6FDAF15260941602431">';
        authXMLRequest += '<wsse:Username>Paymetric\\'+paymentInfo.UserName__c+'</wsse:Username>';
        authXMLRequest += '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'+paymentInfo.Password__c+'</wsse:Password>';
        authXMLRequest += '</wsse:UsernameToken></wsse:Security></soapenv:Header>';
        authXMLRequest += '<soapenv:Body>';
        authXMLRequest += '<mes:SoapOp>';
        authXMLRequest += '<mes:pPacketsIn>';
        authXMLRequest += '<mes:count>1</mes:count>';
        authXMLRequest += '<mes:xipayvbresult>false</mes:xipayvbresult>';
        authXMLRequest += '<mes:packets>';
        authXMLRequest += '<mes:ITransactionHeader>';
        authXMLRequest += '<mes:Amount>'+ccAmount+'</mes:Amount>'; 
        authXMLRequest += '<mes:CardExpirationDate>'+ccExpMonth+'/'+ccExpYear.substring(2)+'</mes:CardExpirationDate>';
        authXMLRequest += '<mes:CardHolderName>'+ccName+'</mes:CardHolderName>';
        authXMLRequest += '<mes:CardNumber>'+ccToken+'</mes:CardNumber>';
        authXMLRequest += '<mes:CardType>'+ccType+'</mes:CardType>';
        authXMLRequest += '<mes:PacketOperation>1</mes:PacketOperation>';
        authXMLRequest += '<mes:MerchantID>'+merchId+'</mes:MerchantID>';
        //authXMLRequest += '<mes:CardDataSource>E</mes:CardDataSource>';
        authXMLRequest += '<mes:CurrencyKey>'+currencyKey+'</mes:CurrencyKey>';
        authXMLRequest += '<mes:PONumber>'+poNumber+'</mes:PONumber>';
        authXMLRequest += '<mes:CardHolderAddress1>'+siteLoc.Address_Line_1__c+'</mes:CardHolderAddress1>';
        authXMLRequest += '<mes:CardHolderAddress2>'+siteLoc.Address_Line_2__c+'</mes:CardHolderAddress2>';
        authXMLRequest += '<mes:CardHolderAddress3>'+siteLoc.Address_Line_3__c+'</mes:CardHolderAddress3>';
        authXMLRequest += '<mes:CardHolderAddress4>'+siteLoc.Address_Line_4__c+'</mes:CardHolderAddress4>';
        authXMLRequest += '<mes:CardHolderCity>'+siteLoc.City__c+'</mes:CardHolderCity>';
        authXMLRequest += '<mes:CardHolderCountry>'+siteLoc.Country__c+'</mes:CardHolderCountry>';
        authXMLRequest += '<mes:CardHolderState>'+siteLoc.State__c+'</mes:CardHolderState>';
        authXMLRequest += '<mes:CardHolderZip>'+siteLoc.Zip_Code__c+'</mes:CardHolderZip>';      
        authXMLRequest += '</mes:ITransactionHeader>';
        authXMLRequest += '</mes:packets>';
        authXMLRequest += '</mes:pPacketsIn>';
        authXMLRequest += '</mes:SoapOp>';
        authXMLRequest += '</soapenv:Body>';
        authXMLRequest += '</soapenv:Envelope>';
        
        System.debug('XMLRequest:'+authXMLRequest);
        
        HttpClient httpObj = new HttpClient('paymetric\\'+paymentInfo.UserName__c,paymentInfo.Password__c,True);
        HttpRequest req = new HttpRequest();
        req.setBody(authXMLRequest);
        req.setMethod('POST');
        
        System.debug('orgName:'+orgName);
        if(orgName.containsIgnoreCase('DEV'))
            req.setEndpoint('callout:Paymetric_Sandbox');
        else if(orgName.containsIgnoreCase('UAT'))
            req.setEndpoint('callout:Paymetric_UAT');
        else
            req.setEndpoint('callout:Paymetric_Production');
            
        Map<String,String> headerMap = new Map<String,String>();
        headerMap.put('Content-Type','text/xml;charset=UTF-8');
        headerMap.put('SOAPAction', 'Paymetric/XiPaySoap30/action/XiGGE.SoapOp');
        
        HttpResponse res = httpObj.send(req,headerMap);
        System.debug('Response**:' + res);
        System.debug('Response**:' + res.getBody());
        
        if(res.getStatusCode() != 200){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Authorization Failed!!!')); 
            return null;    
        }else{
        
            Dom.Document doc = res.getBodyDocument();
            System.debug('doc:'+doc);
            Dom.XMLNode hNode = doc.getRootElement();
            Dom.XMLNode hNode1 = hNode.getChildElement('Body',auth1);
            Dom.XmlNode hNode2 = hNode1.getChildElement('SoapOpResponse',auth2);
            Dom.XmlNode hNode3 = hNode2.getChildElement('SoapOpResult', auth2);
            Dom.XmlNode hNode4 = hNode3.getChildElement('packets',auth2);
            Dom.XmlNode hNode5 = hNode4.getChildElement('ITransactionHeader',auth2);
            
            for(Dom.XMLNode child : hNode5.getChildren()) {
                if(child.getName().contains('AuthorizationCode'))
                    ccAuthCode = child.getText();
                if(child.getName().contains('TransactionID'))
                    txId = child.getText();
                if(child.getName().contains('AVSCode'))
                    avsCode = child.getText();
                if(child.getName().contains('Message'))
                    paymetricmsg = child.getText();
                if(child.getName().contains('StatusCode'))
                    ccStatusCode = child.getText();
            }
            
            System.debug('authCode:'+ccAuthCode);
            System.debug('txId:'+txId);
            System.debug('storecc:'+storeCC);
            System.debug('avsCode:'+avsCode);
            System.debug('ccStatusTxn:'+ccStatusCode);
            System.debug('ccToken:'+ccToken);
            System.debug('card type:'+ccType);
            System.debug('exp month:'+ccExpMonth);
            System.debug('Exp Year:'+ccExpYear);
            System.debug('card name:'+ccName);
            System.debug('card cvv:'+ccCVV);
            System.debug('amount:'+ccAmount);
            System.debug('billToAcct:'+billToAcct);
            
            if(ccAuthCode != null && ccAuthCode != '' && ccStatusCode != '-101'){
                isAuthorized = true;
                if(ccExpMonth.length() == 1)
                    ccExpMonth = '0'+ccExpMonth;
                    
                    System.debug('ccToken:'+ccToken);
                    
                    //Creation of payment card
                    if(selectedCards.size() == 0){
                    if(ccExpMonth.length() == 1)
                        ccExpMonth = '0'+ccExpMonth;
                
                    if(billToAcct == null)
                        billToAcct = '';
                    else if(billToSite == null)
                        billToSite = '';
            
                
                    System.debug('acc:'+recAccId);
                    System.debug('billToSiteId:'+billToSiteId);
                    
                    pc = new Payment_Card__c(Name = ccName+'-'+ccToken.right(4), Account__c = (Id)billToAcct, Credit_Card_Type__c = cardTypes.get(ccType),  Credit_Card_Expiration_Month__c = ccExpMonth, Credit_Card_Expiration_Year__c = ccExpYear, Credit_Card_Name_on_Card__c = ccName,  Credit_Card_Token__c=ccToken, Credit_Card_Status__c='Active', Bill_To_Site_Location__c = billToSiteId);
                    system.debug('pc::::::'+pc);
                    //11/01/2018     Krishna           Fixed issue with billToSiteId (US-0005957)
                                       // implented error messages (US-0005957)
                    /*if(recId.getSObjectType().getDescribe().getName() == 'Account' && (billToSiteId == null || String.valueOf(billToSiteId) == '')){
                         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a Bill To Site to process the payment card.')); 
                         return null;
                    }
                    else if(billToSiteId != null && billToAcct != null){
                        pc = new Payment_Card__c(Name = ccName+'-'+ccToken.right(4), Account__c = (Id)billToAcct, Credit_Card_Type__c = cardTypes.get(ccType),  Credit_Card_Expiration_Month__c = ccExpMonth, Credit_Card_Expiration_Year__c = ccExpYear, Credit_Card_Name_on_Card__c = ccName,  Credit_Card_Token__c=ccToken, Credit_Card_Status__c='Active', Bill_To_Site_Location__c = billToSiteId);
                        system.debug('pc::::::'+pc);
                    }else {
                        
                           String sObjName = recId.getSObjectType().getDescribe().getName();
 
                           if(sObjName== 'WorkOrder'){
                                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Card cannot be processed missing billing information on Asset related to '+ recId.getsobjecttype() )); 
                                                    return null;
                                                       
                           }else{
                               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Card cannot be processed missing billing information on '+ recId.getsobjecttype() )); 
                                                    return null;
                           }
                         
                     }*/
                    try{
                        insert pc;
                        paymentCardId = pc.Id;    
                    }
                    catch(Exception e){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Card creation Failed!!! '+e.getMessage())); 
                        return null;
                    }
                    
                    
                   } 
                    
                    
                   //Creation of payment record 
                   if(String.valueOf(recId).startswith('001')){
                        if(pc != null){
                            if(billToAcct == null)
                                billToAcct = '';
                            else if(billToSite == null)
                                billToSite = '';
                            if(avsCode == null)
                                avsCode = '';
                                
                            System.debug('billToSiteId:'+billToSiteId);
                            Id paymentRecTypeId = GlobalUtility.getRecordTypeId('Payment__c','Account_Payment');   
                            payment = new Payment__c(Account__c = (Id)billToAcct, Payment_Card__c=pc.id ,Amount__c = Integer.valueOf(ccAmount), Credit_Card_Authorization_Code__c = ccAuthCode, 
                                         Credit_Card_Transaction_ID__c = txId, RecordTypeId = paymentRecTypeId, Bill_To_Site_Location__c = billToSiteId, Credit_Card_AVS_Code__c = avsCode, CurrencyIsoCode = currencyKey);
                        }
                   }
                   else{
                       if(ord != null){
                           Id paymentRecTypeId = GlobalUtility.getRecordTypeId('Payment__c','Order_Payment');
                       
                           payment = new Payment__c(Account__c = recAccId, Payment_Card__c=pc.id ,Amount__c = Integer.valueOf(ccAmount), Credit_Card_Authorization_Code__c = ccAuthCode, 
                                              Credit_Card_Transaction_ID__c = txId, RecordTypeId=paymentRecTypeId, Order__c=ord.Id, Credit_Card_AVS_Code__c = avsCode, CurrencyIsoCode = currencyKey);
                           }
                       else if(svc != null){
                           
                           System.debug('recAccId:'+recAccId);
                           System.debug('pc:'+pc);
                           Id paymentRecTypeId = GlobalUtility.getRecordTypeId('Payment__c','ServiceContract_Payment');
                       
                           payment = new Payment__c(Account__c = recAccId, Payment_Card__c=pc.id ,Amount__c = ccAmount, Credit_Card_Authorization_Code__c = ccAuthCode, 
                                             Credit_Card_Transaction_ID__c = txId, RecordTypeId=paymentRecTypeId, Service_Contract__c=svc.Id, Credit_Card_AVS_Code__c = avsCode, CurrencyIsoCode = currencyKey);
                       }
                       else if(wo != null){
                       
                           Id paymentRecTypeId = GlobalUtility.getRecordTypeId('Payment__c','Order_Payment');
                       
                           payment = new Payment__c(Account__c = recAccId, Payment_Card__c=pc.id ,Amount__c = ccAmount, Credit_Card_Authorization_Code__c = ccAuthCode, 
                                              Credit_Card_Transaction_ID__c = txId, RecordTypeId=paymentRecTypeId, Work_Order__c = wo.Id, Credit_Card_AVS_Code__c = avsCode, CurrencyIsoCode = currencyKey);
                       }
                       else if(quote != null){
                           System.debug('recAccId:'+recAccId);
                           System.debug('pc:'+pc);
                           Id paymentRecTypeId = GlobalUtility.getRecordTypeId('Payment__c','ServiceContract_Payment');
                       
                           payment = new Payment__c(Account__c = recAccId, Payment_Card__c=pc.id ,Amount__c = ccAmount, Credit_Card_Authorization_Code__c = ccAuthCode, 
                                             Credit_Card_Transaction_ID__c = txId, RecordTypeId=paymentRecTypeId, Quote__c=quote.Id, Credit_Card_AVS_Code__c = avsCode, CurrencyIsoCode = currencyKey);
                           
                       }
                       
                  }
                  if(payment != null){
                      try{
                          insert payment;
                          
                          if(svc != null){
                              svc.Payment__c = payment.Id;
                              update svc;
                          }
                          else if(ord != null){
                              ord.Payment__c = payment.Id;
                              update ord;
                          }
                          else if(wo != null){
                              wo.Payment__c = payment.Id;
                              update wo;
                          }
                          else if(quote != null){
                              quote.Payment__c = payment.Id;
                              update quote;
                          }
                          isPaymentCreated = true;
                      }
                      catch(Exception e){
                          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment creation Failed!!! '+e.getMessage())); 
                      }
                  }
          }
          else{
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Authorization Failed!!! - '+paymetricmsg));
          }
        }
        return null;
    }
    
    public class existingCardsWrapper{
        public Payment_Card__c payCard{get; set;}
        public Boolean selected{get; set;}
        public Integer amount{get; set;}
        
        public existingCardsWrapper(Payment_Card__c pc){
            payCard = pc;
            amount = null;
            selected = false;
        }     
    }
    
    public pageReference cancel(){
        Pagereference pageref;
        
        if(ApexPages.currentPage().getParameters().get('Id') == null)
            pageref = new PageReference('/'+(Id)ApexPages.currentPage().getParameters().get('retURL').substring(1,16));
        else 
            pageref = new PageReference('/'+(Id)ApexPages.currentPage().getParameters().get('Id').substring(0,15));
        pageref.setRedirect(true);
        return pageref;
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        if(acc != null){
            options.add(new SelectOption(acc.Id,acc.Name +  ' (' + acc.Oracle_Customer_Number__c + ')'));    
        }
        if(siteLocRecList != null){
            for(Account sl : siteLocRecList)
                if(sl.Id != acc.Id)
                    options.add(new SelectOption(sl.Id,sl.Name +  ' (' + sl.Oracle_Customer_Number__c + ')'));
        }
        
        return options;
   }
   
   //Displays the new card section on the VF page
   public pageReference showNewCardSection(){
       newCardSec = true;
       existingCard = false;
       System.debug('newCardSec:'+newCardSec);
       return null;
   }
   
   public PageReference BillToAcctChanged(){
       billToSite=null;
        billToSiteId=null;
       return null;
   }
   
    public PageReference removeCard(){
        System.debug('Inside Remove Card');
        
        removeCards = new List<Payment_Card__c>();
        
        if(existingCardsList.size() > 0)
            for(Integer i=0; i<existingCardsList.size();i++){
                existingCardsWrapper ecw = existingCardsList[i];
                if(ecw.selected == true){
                    ecw.payCard.Credit_Card_Status__c = 'Inactive';
                    removeCards.add(ecw.payCard);
                    existingCardsList.remove(i);
                }   
            }
        System.debug('removeCards:'+removeCards);    
        if(removeCards.size() > 0)
            update removeCards;
            
        return null;
    }
    
    public void selectcon() {
    
        String selpcid = System.currentPagereference().getParameters().get('conid');                //Get the ID of the selected contact
        integer indexVal = Integer.valueof(system.currentpagereference().getparameters().get('index'));  //Get the index (row number) of the selected contact
        Payment_Card__c pc1 = allPaymentCardsMap.get(selpcid);
        pcList =  new List<Payment_Card__c>();
        pcList.add(pc1);
        System.debug('indexVal:'+indexVal);
        //Using the index, set the boolean flag on the wrapper class variable to TRUE, all other rows are set to FALSE
        for(integer i=0; i < existingCardsList.size(); i++){
            if(i == indexVal - 1){
                existingCardsList[i].selected = true;
                existingCard = true;
            }else
                existingCardsList[i].selected = false;
            System.debug('existingCardsList[i].selected:'+existingCardsList[i].selected);
        }
        
    }

}