public class MARE_Sort 
{
    public map<string,string> PageParameters = ApexPages.currentPage().getParameters();
    public set<string> RecordIds {get; set;}
    public string RecordIdsJSON {get; set;}
    
    public MARE_Sort()
    {   
        RecordIds = new set<string>();

        if (PageParameters.containsKey('RecordIds'))
        {
            RecordIds.addAll(PageParameters.get('RecordIds').split(','));
            RecordIdsJSON = JSON.serialize(RecordIds);
        }
    }

    @RemoteAction
    public static JSONData getBaseObjectId()
    {
        JSONData returnData = new JSONData();
        
        map<string, object> dataMap = new map<string, object>();
        
        for (sma__MABaseObject__c baseObject : [SELECT Id FROM sma__MABaseObject__c WHERE Name = 'Swarm_Waypoint__c'])
        {
            dataMap.put(baseObject.Id, baseObject);    
        }   
        
        returnData.responseData = dataMap;
        return returnData;    
    }

    @RemoteAction
    public static JSONData getSalesforceRecords(string recordIds, string qryString)
    {
        JSONData returnData = new JSONData();
        
        list<string> recordIdList = recordIds.split(',');
      
        list<sObject> recordResults = Database.query(qryString + ' WHERE Id IN :recordIdList');
        
        map<string, object> recordMap = new map<string, object>();
        
        for (sObject record : recordResults)
        {
            recordMap.put(record.Id, record);
        }
        
        returnData.responseData = recordMap;
        return returnData;      
    }

/*
    @RemoteAction
    public static JSONData sendDistanceMatrixRequest(string inputJSON)
    {
        JSONData returnData = new JSONData();
        
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        if (!Test.isRunningTest())
        {
            req.setEndpoint('http://api.devmare.com/v1/matrix/async');         
        }
        else
        {
            req.setEndpoint('blank');
        }
        
        req.setBody(inputJSON);
        Http routeHTTP = new Http();
        HttpResponse res = routeHTTP.send(req);
        returnData.responseData = (Map<String,object>) JSON.deserializeuntyped(res.getBody());
        returnData.jobComplete = true; 
        
        return returnData;        
    }

    @RemoteAction
    public static JSONData getDistanceMatrixResults(string jobInfo)
    {
        JSONData returnData = new JSONData();
        
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setMethod('GET');
        
        if (!Test.isRunningTest())
        {
            req.setEndpoint('http://api.devmare.com/v1/matrix/async/' + jobInfo); // Staging Endpoint        
        }
        else
        {
            req.setEndpoint('blank');
        }        

        req.setHeader('Content-Type', 'application/json');

        Http routeHTTP = new Http();
        HttpResponse res = routeHTTP.send(req);
        
        system.debug(res);
        system.debug(res.getBody());
        
        returnData.responseData = (Map<String,object>) JSON.deserializeuntyped(res.getBody());

        //if (string.valueOf(returnData.responseData.get('status')) == 'Completed')    // Prod
        if (string.valueOf(returnData.responseData.get('JobStatus')) == 'Completed')    // Staging
        {
            req = new HttpRequest();
            req.setTimeout(60000);
            req.setMethod('GET');
            //req.setEndpoint(string.valueOf(returnData.responseData.get('url')));    // Prod
            req.setEndpoint(string.valueOf(returnData.responseData.get('Solution')));    // Staging
            routeHTTP = new Http();
            res = routeHTTP.send(req);
            
            If(res.getStatusCode() == 301 || res.getStatusCode() == 302)
            {    
                req.setEndpoint(res.getHeader('Location'));
                res = new Http().send(req);
                returnData.responseData = (map<string, object>)JSON.deserializeUntyped(res.getBody());
                returnData.jobComplete = true;
            }
            else
            {
                returnData.responseData = (map<string, object>)JSON.deserializeUntyped(res.getBody());
                returnData.jobComplete = true;                
            }            
        }
        else if (string.valueOf(returnData.responseData.get('status')) == 'Failed')
        {
            returnData.jobComplete = true;
        }
        
        return returnData;
    }
*/    
    @RemoteAction
    public static JSONData sendMARERequest(string inputJSON, integer requestSize)
    {
        JSONData returnData = new JSONData();
        
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('x-api-key', 'JUZQYtOpI61usCUUzdDuI6PAbSKNdGS87Zze0Lbc');    // Prod Key
        req.setHeader('apikey', 'hXamlmZnx2R+QWyjiWQXzsE96AkEQeh5Gy85IBMS40w');    // Staging Key
        
        
        if (!Test.isRunningTest())
        {
            //req.setEndpoint('https://public-api.mapanything.io/mare/routing/async'); // Prod Endpoint
            req.setEndpoint('http://blue.stg.devmare.com/v1/tsp/async/');       // Staging Endpoint          
        }
        else
        {
            req.setEndpoint('blank');
        }
        
        req.setBody(inputJSON);
        Http routeHTTP = new Http();
        HttpResponse res = routeHTTP.send(req);
        returnData.responseData = (Map<String,object>) JSON.deserializeuntyped(res.getBody());
        returnData.jobComplete = true; 
        
        return returnData;        
    }

    @RemoteAction
    public static JSONData saveMAREJobInfo(string jobId, string swarmName, string swarmTerritory, integer requestSize, string startAddress, decimal startLat, decimal startLng, string endAddress, decimal endLat, decimal endLng, integer clusterNumber)
    {
        JSONData returnData = new JSONData();
        
        Async_MARE_Job__c newJob = new Async_MARE_Job__c();
        newJob.Swarm_Name__c = swarmName + ' - Cluster ' + clusterNumber;
        newJob.Swarm_Territory__c = swarmTerritory;
        newJob.Job_Status__c = 'Accepted';
        newJob.Size__c = requestSize;
        newJob.MARE_Job_Id__c = jobId;     
        newJob.Submitted_By__c = UserInfo.getUserId();
        newJob.Submitted_DateTime__c = Datetime.now();
        newJob.Starting_Location_Address__c = startAddress;
        newJob.Starting_Location_Latitude__c = startLat;
        newJob.Starting_Location_Longitude__c = startLng;
        newJob.Ending_Location_Address__c = endAddress;
        newJob.Ending_Location_Latitude__c = endLat;
        newJob.Ending_Location_Longitude__c = endLng;
        newJob.Cluster__c = clusterNumber;
        
        insert newJob;
        
        if (!Test.isRunningTest())
        {
            System.enqueueJob(new MARE_CheckJob(newJob.Id)); 
        }
        
        returnData.jobComplete = true;
        return returnData;        
    }
    
    public class JSONData
    {
        Map<String, object> responseData;
        boolean jobComplete;

        public JSONData()
        {
            this.responseData = new Map<String, object>();
            this.jobComplete = false;
        }        
    } 
    
    public List<SelectOption> getSwarmTerritoryOptions() {
        List<SelectOption> SwarmTerritoryOptions = new List<SelectOption>();
        
        SwarmTerritoryOptions.add(new SelectOption('','--Select Territory--'));

        for (Swarm_Territory__c st : [select id, name from swarm_territory__c order by name]) {
            SwarmTerritoryOptions.add(new SelectOption(st.Id, st.Name));
        }

        return SwarmTerritoryOptions;
        
    }

}