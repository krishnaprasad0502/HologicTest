/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    HTTPMockResponse to be used by paymentauthorization to validate the authorization from paymetrics.

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/19/2018      Mani Sundaresan      Initial Creation (US-0004314)
-------------------------------------------------------------*/
@isTest
global class paymetricsAuthMockHttpResponseGenerator implements HttpCalloutMock {

    //Interface method
    global HTTPResponse respond(HTTPRequest req) {
    
        
        
        String body = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><s:Header><o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><u:Timestamp u:Id="_0"><u:Created>2018-07-22T22:01:16.438Z</u:Created><u:Expires>2018-07-22T22:06:16.438Z</u:Expires></u:Timestamp></o:Security></s:Header><s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><SoapOpResponse xmlns="http://Paymetric/XiPaySoap30/message/"><SoapOpResult><count>1</count><xipayvbresult>true</xipayvbresult><packets><ITransactionHeader><AVSAddress/><AVSCode>X</AVSCode><AVSZipCode/><AccountingDocNumber/><ActionCode/><AdditionalInfo/><Amount>11.0000</Amount><AuthorizationCode>XI00</AuthorizationCode><AuthorizationDate>2018-07-22T17:01:16</AuthorizationDate><AuthorizationReferenceCode>180722170116391</AuthorizationReferenceCode><AuthorizationTime>17:01:0016</AuthorizationTime><AuthorizedThroughCartridge>XiPayCartridge.XiPayCartridge.1</AuthorizedThroughCartridge><BankBatchID/><BankSubBatchID/><BankTransactionID>0</BankTransactionID><BatchID/><BillingDate>1899-12-30T00:00:00</BillingDate><BillingPlanItem/><CaptureDate>1899-12-30T00:00:00</CaptureDate><CaptureReferenceCode/><CardCVV2/><CardDataSource>E</CardDataSource><CardExpirationDate>04/21</CardExpirationDate><CardFollowOnNumber/><CardHolderAddress1>null</CardHolderAddress1><CardHolderAddress2>null</CardHolderAddress2><CardHolderCity>null</CardHolderCity><CardHolderCountry>nul</CardHolderCountry><CardHolderDistrict/><CardHolderName1/><CardHolderName2/><CardHolderName>test</CardHolderName><CardHolderState>nul</CardHolderState><CardHolderZip>null</CardHolderZip><CardNumber>8417834292451111</CardNumber><CardPresent>0</CardPresent><CardType>vi</CardType><CardValidFrom/><ChargeAmount>0.0000</ChargeAmount><Client/><CompanyCode/><CreationDate>2018-07-22T17:01:16</CreationDate><CurrencyKey>USD</CurrencyKey><CustTXN>0</CustTXN><CustomerNumber/><FiscalYear/><GLAccount/><LastModificationDate>2018-07-22T17:01:16</LastModificationDate><LocationID/><MerchantID>177506</MerchantID><MerchantTXN/><MerchantTransactionID/><Message>[XiPay Null] Approved</Message><ModifiedStatus>1</ModifiedStatus><OrderDate>1899-12-30T00:00:00</OrderDate><OrderID/><Origin>XiPay</Origin><PONumber>WEB DEPOSIT - 87510</PONumber><PacketOperation>1</PacketOperation><Preauthorized/><ReferenceCode/><ReferenceLineItem/><ResponseCode/><SalesDocNumber/><SettlementAmount>11.0000</SettlementAmount><SettlementDate>1899-12-30T00:00:00</SettlementDate><SettlementReferenceCode/><ShippingCaptureDate>1899-12-30T00:00:00</ShippingCaptureDate><ShippingLocationID/><ShippingMethod/><StatusCode>100</StatusCode><StatusTXN>Authorized</StatusTXN><TaxLevel1>0.0000</TaxLevel1><TaxLevel2>0.0000</TaxLevel2><TaxLevel3>0.0000</TaxLevel3><TaxLevel4>0.0000</TaxLevel4><TerminalID/><TransactionID>119244782</TransactionID><TransactionType>Authorization</TransactionType><VATNumberCustomer/><VATNumberMerchant/><XIID>43067</XIID><InfoItems><InfoItem><Key>HOST_AUTH</Key><Value>LiiTON0iAAF4uneuAUqnvGRy6Zg=</Value></InfoItem></InfoItems></ITransactionHeader></packets></SoapOpResult></SoapOpResponse></s:Body></s:Envelope>';
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody(body);
        res.setStatusCode(200);
        return res;
    }
}