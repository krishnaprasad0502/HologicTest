/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Extension Class to SearchBeforeCreate_CDM VF page. Sends out the lead address to CDM to validate the addresses
Test Class:    CDMExtension_Test

History:
<Date>      <Authors Name>    <Brief Description of Change>
04/01/2018   Mani Sundaresan    Initial Creation (US-4246)
----------------------------------------------------------------------------------------------------------------------*/
public class CDMExtension {
    
    //Variable Declaration
    private Lead leadVal;
    public List<wrapDataQualityOrg> wrapDataQualityOrgList {get; set;}
    
    //Constructor to fetch the lead details
    public CDMExtension(ApexPages.StandardController controller) {
    
        Lead leadId = (Lead)controller.getRecord();
        this.leadVal = [SELECT Id, Name, Street, CountryCode, PostalCode, City, StateCode, FirstName, LastName from Lead where Id = :leadId.Id]; 
        
        System.debug('leadVal:'+leadVal); 
    }
    
    //Method invoked from the VF page to send out the RESTful request to CDM via Mulesoft
    public void searchCDM(){
    
        CDMJSONDeserialize responseDeserializer;
    
        JSONGenerator gen = JSON.createGenerator(true);    
        gen.writeStartObject();
        if(leadVal.Name != null)
            gen.writeStringField('MasterNameForMatching_c',leadVal.Name);
        if(leadVal.Street != null)
            gen.writeStringField('AddressLine1', leadVal.Street);
        if(leadVal.CountryCode != null)
            gen.writeStringField('Country',leadVal.CountryCode);
        if(leadVal.PostalCode != null)
            gen.writeStringField('PostalCode',leadVal.PostalCode);
        if(leadVal.City != null)
            gen.writeStringField('City',leadVal.City);
        if(leadVal.StateCode != null)
            gen.writeStringField('CountrySubEntity',leadVal.StateCode);
        
        gen.writeStringField('OrganizationName','');
        gen.writeEndObject();    
        String jsonS = gen.getAsString();
        System.debug('jsonMaterials:'+jsonS);
        String namedCreds = 'SearchBeforeCreate_CDM';
        

        // Sending the http body with JSON 
        HttpRequest req = new HttpRequest();
        
        String url = Test.isRunningTest() ? 'http://callout.' + namedCreds + '.com' : 'callout:' + namedCreds;
        
        //req.setEndpoint('https://muletst.hologic.com/sfdc-cdm/matchOrganization');
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setbody(jsonS);
        Http http = new Http();
        HTTPResponse response = http.send(req);
        System.debug(response.getBody());
        
        if(response != null && (response.getStatusCode() == 200 || response.getStatusCode() == 0)){
            System.debug('Integration successful');
            responseDeserializer = CDMJSONDeserialize.parse(response.getBody());
            System.debug('Deserializer:'+responseDeserializer);
            System.debug('Deserializer.DQO:'+responseDeserializer.DataQualityOrg[0]);
            wrapDataQualityOrgList = new List<wrapDataQualityOrg>();
            for(Integer i=0; i<responseDeserializer.DataQualityOrg.size(); i++){
                wrapDataQualityOrgList.add(new wrapDataQualityOrg(responseDeserializer.DataQualityOrg[i]));
                System.debug('AddressLine1:'+responseDeserializer.DataQualityOrg[i].AddressLine1);    
            }
            
            System.debug(wrapDataQualityOrgList.size());
            
        }
        
        else{
            System.debug('Unsuccessful Integration:'+'Status received is - '+response.getStatusCode()+'. Please check with Mule and CDM team.'); 
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Integration failed!!. Kindly create a Help Me related to this issue.'));   
        }
    }
    
    
    
    //Wrapper class to hold the parsed values
    public class wrapDataQualityOrg{
        public CDMJSONDeserialize.cls_DataQualityOrg dataQualityOrg{get; set;}
        public Boolean selected {get; set;}
        public String address {get; set;}
        public String orgIdentifier {get; set;}
        public String partySiteId {get; set;}
        public String partyName {get; set;}
        public String regId {get; set;}
        
        
        public wrapDataQualityOrg(CDMJSONDeserialize.cls_DataQualityOrg dqo){
            dataQualityOrg = dqo;
            selected = false;
            address = '';
            if(dqo.AddressLine1 != null)
                address += dqo.AddressLine1 + '\n';
            if(dqo.AddressLine2 != null)
                address += dqo.AddressLine2 + '\n';
            if(dqo.AddressLine3 != null)
                address += dqo.AddressLine3 + '\n';
            if(dqo.AddressLine4 != null)
                address += dqo.AddressLine4 + '\n';
            if(dqo.City != null)
                address += dqo.City +', '+ dqo.CountrySubEntity +' ' + dqo.PostalCode +'\n';
            if(dqo.Country != null)
                address += dqo.Country;
            System.debug('dataQualityOrg:'+address); 
            orgIdentifier = dqo.OrganizationIdentifier;
            partySiteId = dqo.PartySiteId;
            partyName = dqo.PartyName;
            regId = dqo.RegistrationId;   
            
        }
        
    }
    
   


}