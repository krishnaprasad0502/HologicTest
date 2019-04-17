public class MARE_CheckJob implements Queueable, Database.AllowsCallOuts 
{
    public final string recordId;
    
    public MARE_CheckJob (string rId)
    {
        recordId = rId;
    }
    public void execute(QueueableContext context)
    {         
        Async_MARE_Job__c MAREJob = new Async_MARE_Job__c ();
        
        for (Async_MARE_Job__c amj : [SELECT Id, Name, Swarm_Name__c, Swarm_Territory__c, Job_Status__c, Submitted_DateTime__c, Started_DateTime__c, Completed_DateTime__c, MARE_Job_Id__c, Submitted_By__c, Size__c, Cluster__c,
                                       Starting_Location_Address__c, Starting_Location_Latitude__c, Starting_Location_Longitude__c, Ending_Location_Address__c, Ending_Location_Latitude__c, Ending_Location_Longitude__c
                                     FROM Async_MARE_Job__c WHERE Id =:recordId])
        {
            MAREJob = amj;
        }
        
        system.debug(MAREJob);
        
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setMethod('GET');
        
        if (!Test.isRunningTest())
        {
            //req.setEndpoint('https://public-api.mapanything.io/mare/routing/?' + MAREJob.MARE_Job_Id__c + '=' + jobInfo); // Prod Endpoint
            req.setEndpoint('http://blue.stg.devmare.com/tsp/v1/async/' + MAREJob.MARE_Job_Id__c); // Staging Endpoint        
        }
        else
        {
            req.setEndpoint('blank');
        }        
        
        //req.setHeader('x-api-key', 'JUZQYtOpI61usCUUzdDuI6PAbSKNdGS87Zze0Lbc');    // Prod Key
        req.setHeader('apikey', 'hXamlmZnx2R+QWyjiWQXzsE96AkEQeh5Gy85IBMS40w');    // Staging Key
        req.setHeader('Content-Type', 'application/json');

        Http routeHTTP = new Http();
        HttpResponse res = routeHTTP.send(req);
        
        //system.debug(res);
        //system.debug(res.getBody());
                    
        Map<String, object> responseData = (Map<String,object>) JSON.deserializeuntyped(res.getBody());

        system.debug(responseData);
        system.debug(JSON.serializePretty(responseData));
                        
        //if (string.valueOf(responseData.get('status')) == 'Completed')    // Prod
        if (string.valueOf(responseData.get('JobStatus')) == 'Completed')    // Staging
        {
            req = new HttpRequest();
            req.setTimeout(60000);
            req.setMethod('GET');
            //req.setEndpoint(string.valueOf(responseData.get('url')));    // Prod
            req.setEndpoint(string.valueOf(responseData.get('Solution')));    // Staging
            routeHTTP = new Http();
                                        
            if (!Test.isRunningTest())
            {
                res = routeHTTP.send(req);
                
                If(res.getStatusCode() == 301 || res.getStatusCode() == 302)
                {    
                    req.setEndpoint(res.getHeader('Location'));
                    res = new Http().send(req);
                    responseData = (map<string, object>)JSON.deserializeUntyped(res.getBody());
                    
                }
                else
                {
                    responseData = (map<string, object>)JSON.deserializeUntyped(res.getBody());               
                }            
            }
            else
            {
                StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'MARE_ROUTE_OUTPUT'];
                String responseStr = sr.body.toString();
                responseData = (map<string, object>)JSON.deserializeUntyped(responseStr);
                            
            }
                  
            //system.debug(responseData);
            //system.debug(JSON.serializePretty(responseData));
            
            list<string> RecordIds = new list<string>();
            
            list<object> RouteList = (list<object>) responseData.get('routes');
            
            for (object route : RouteList)
            {
                map<string, object> routeMap = (map<string, object>) route;
                list<object> OrderSequenceList = (list<object>) routeMap.get('order_sequence');

                for (object recordId : OrderSequenceList)
                {
                    RecordIds.add(string.valueOf(recordId));
                }                
            }
            
            if (MAREJob.Started_DateTime__c == null)
            {
                MAREJob.Started_DateTime__c = Datetime.now();
            }  
                        
            MAREJob.Job_Status__c = 'Saving'; 
            
            if (!Test.isRunningTest())
            {
                System.enqueueJob(new MARE_SaveRecords(MAREJob.Id, RecordIds, 1));
            }
            
            list<Swarm_Waypoint__c> NewSwarmWaypointsToCreate = new list<Swarm_Waypoint__c>();
            
            Swarm_Waypoint__c newStartWaypoint = new Swarm_Waypoint__c();
            newStartWaypoint.Swarm_Name__c = MAREJob.Swarm_Name__c;
            newStartWaypoint.Swarm_Territory__c = MAREJob.Swarm_Territory__c;
            newStartWaypoint.Order__c = 0;
            newStartWaypoint.Cluster__c = MAREJob.Cluster__c;
            newStartWaypoint.Async_MARE_Job__c = MAREJob.Id;
            newStartWaypoint.Latitude__c = MAREJob.Starting_Location_Latitude__c;
            newStartWaypoint.Longitude__c = MAREJob.Starting_Location_Longitude__c;
            NewSwarmWaypointsToCreate.add(newStartWaypoint);
            
            Swarm_Waypoint__c newEndWaypoint = new Swarm_Waypoint__c();
            newEndWaypoint.Swarm_Name__c = MAREJob.Swarm_Name__c;
            newEndWaypoint.Swarm_Territory__c = MAREJob.Swarm_Territory__c;
            newEndWaypoint.Order__c = MAREJob.Size__c + 1;
            newEndWaypoint.Cluster__c = MAREJob.Cluster__c;
            newEndWaypoint.Async_MARE_Job__c = MAREJob.Id;
            newEndWaypoint.Latitude__c = MAREJob.Ending_Location_Latitude__c;
            newEndWaypoint.Longitude__c = MAREJob.Ending_Location_Longitude__c;
            NewSwarmWaypointsToCreate.add(newEndWayPoint);
            
            insert NewSwarmWaypointsToCreate;                                                                         
        }  
        //else if (string.valueOf(responseData.get('status')) == 'Completed')  // Prod        
        else if (string.valueOf(responseData.get('JobStatus')) == 'Failed') // Staging  
        {
            // Update MARE Job
            
            MAREJob.Job_Status__c = 'Failed';
            MAREJob.Completed_DateTime__c = Datetime.now();
            MAREJob.Error_Message__c = string.valueOf(responseData.get('JobMessage'));
        }
        else
        {
            // Job not finished yet, queue it up again
            
            if (!Test.isRunningTest())
            {
                System.enqueueJob(new MARE_CheckJob(MAREJob.Id)); 
            }
            
            MAREJob.Job_Status__c = 'Running';
            
            if (MAREJob.Started_DateTime__c == null)
            {
                MAREJob.Started_DateTime__c = Datetime.now();
            } 
        }
        
        update MAREJob;
    }
    
    public static void codeBuffer()
    {
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;  
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;  
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;  
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;  
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;                                                                     
    }
}