public class WorkOrderServiceReportController {
	
	public WorkOrder wo				{get;set;}
	
	public WorkOrderServiceReportController(ApexPages.StandardController stc){
		//Query for extended field values on WO record
		wo = [
			SELECT Id
				  ,WorkOrderNumber
				  ,WorkType.ServiceReportTemplateId
				  ,OwnerId
				  ,Owner.Name
				  ,Owner.Email
				  ,ContactId
				  ,Contact.Email
				  ,CaseId
				  ,Customer_Name__c
				  ,Account.Name
				  ,Asset.Name
				  ,Case.CaseNumber
				  ,Entitlement.Name
			  FROM WorkOrder
			 WHERE Id = :stc.getId()
		];
	}
	
	public void generateReport(){
		//Set mock response generator, if in a unit test
		if(Test.isRunningTest()){
			//Test.setmock(HttpCalloutMock.class, new ServiceReportCalloutHelperMockGenerator(woIds));
		}
		
		List<CaseContactRole> contactRoles = new List<CaseContactRole>();
		if(wo.CaseId != null){
			for(CaseContactRole ccr : [
				SELECT Id
					  ,CasesId
					  ,Contact.Email
				  FROM CaseContactRole
				 WHERE CasesId = :wo.CaseId
				   AND Role = 'FSR Recipient'
			]){
				contactRoles.add(ccr);
			}
		}
		
		//Generate service reports
		List<String> serviceReportIdList = ServiceReportCalloutHelper.generateServiceReports(wo);
		String serviceReportId		= serviceReportIdList[0];
		String contentVersionId		= serviceReportIdList[1];
		String workOrderId			= serviceReportIdList[2];
		
		//Rename service report file
		ContentDocument cd  = [
			SELECT Id
			  FROM ContentDocument
			 WHERE Id IN (SELECT ContentDocumentId
			 				FROM ContentVersion
			 			   WHERE Id = :contentVersionId
			 			 )
		];
		cd.Title = ''
			+ 'Hologic Service Report Case #' + wo.Case.CaseNumber
			+ ' | ' + wo.Customer_Name__c
			+ ' | ' + wo.Asset.Name
			;
		update cd;
		
		//Create and send email
		List<String> toAddresses = new List<String>();
		toAddresses.add(wo.Owner.Email);
		if(wo.ContactId != null){
			toAddresses.add(wo.Contact.Email);
		}
		if(wo.CaseId != null){
			for(CaseContactRole ccr : contactRoles){
				toAddresses.add(ccr.Contact.Email);
			}
		}
		
		String subject = 'Service Report Generated for WorkOrder #' + wo.WorkOrderNumber;
		
		String emailBody = '<html><body><b>Your Service Report for ' + wo.WorkOrderNumber + ' is attached.</b><br/><br/>' +
			'<b>Customer Name:</b> '	+ (wo.Customer_Name__c != null ? wo.Customer_Name__c : '') 	+ '<br/>' +
			'<b>Account Name:</b> '		+ (wo.Account.Name != null ? wo.Account.Name : '') 			+ '<br/>' +
			'<b>Asset Name:</b> '		+ (wo.Asset.Name != null ? wo.Asset.Name : '')				+ '<br/>' +
			'<b>Case:</b> '				+ (wo.Case.CaseNumber != null ? wo.Case.CaseNumber : '') 	+ '<br/>' +
			'<b>Entitlement:</b> '		+ (wo.Entitlement.Name != null ? wo.Entitlement.Name : '') + '</body></html>';
			
		List<String> attachmentIds = new List<String>();
		attachmentIds.add(contentVersionId);
		
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(toAddresses);
		email.setReplyTo(wo.Owner.Email);
		email.setSenderDisplayName(wo.Owner.Name);
		email.setSubject(subject);
		email.setHtmlBody(emailBody);
		email.setEntityAttachments(attachmentIds);
		email.setSaveAsActivity(false);
		
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		emails.add(email);
		Messaging.sendEmail(emails, false);
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
			'The service report was generated and sent to the following email addresses: '
			+ String.join(toAddresses, ', ')
		));
	}

}