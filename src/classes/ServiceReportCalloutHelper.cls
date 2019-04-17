global class ServiceReportCalloutHelper {

	webservice static List<String> generateServiceReports(WorkOrder wo){
		HttpRequest req = new HttpRequest();
		String endpointURL = Configuration_Settings__c.getInstance().Service_Report_Generation_URL__c;
		req.setEndpoint(endpointURL);
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setHeader('Content-Type', 'application/json');
		req.setMethod('POST');
		
		DataWrapper wrapper = new DataWrapper();
		DataWrapperLine line = new DataWrapperLine(wo);
		wrapper.inputs.add(line);
			
		req.setBody(JSON.serialize(wrapper));
		
		HttpResponse resp = new Http().send(req);
		
		System.debug('If you get 302 error, change custom setting value to: ' + resp.getHeader('Location'));
		
		List<DataResponseLine> respLineArray = (List<DataResponseLine>)JSON.deserialize(resp.getBody(), List<DataResponseLine>.class);
		List<String> idKeyList = new List<String>();
		idKeyList.add(respLineArray[0].outputValues.serviceReportId);
		idKeyList.add(respLineArray[0].outputValues.contentVersionId);
		idKeyList.add(respLineArray[0].outputValues.entityId);
			
		return idKeyList;
	}

	private class DataWrapper {
		List<DataWrapperLine> inputs		{get;set;}
		
		private DataWrapper(){
			inputs = new List<DataWrapperLine>();
		}
	}
	
	private class DataWrapperLine {
		Id entityId							{get;set;}
		Id templateId						{get;set;}
		
		private DataWrapperLine(WorkOrder wo){
			entityId 		= wo.Id;
			templateId 		= wo.WorkType.ServiceReportTemplateId;
		}
	}
	
	private class DataResponseLine {
		DataResponseValues outputValues		{get;set;}
	}
	
	private class DataResponseValues {
		String serviceReportId				{get;set;}
		String contentVersionId				{get;set;}
		String entityId						{get;set;}
	}

}