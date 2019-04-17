/**
* @author Salesforce.com
* @date 2016
*
* @description Apex class used in the Process Builder to create Work Orders for Preventive Maintenance
*/
public with sharing class CreatePMWorkOrders {
 
	/*******************************************************************************************************
	* @description Creates an Event for each Work Order passed in the argument from the Process Builder
	* @param infos List of Info class instances containing the information required to create Events
	*/
	@InvocableMethod(label='Create Work Orders' description='Creates Work Orders for Preventive Maintenance') 
	public static Void CreateWorkOrderEvents(List<Info> infos) {

		Set<Id> pmIDs = new Set<Id>();
		
		for (Info info : infos) {
			pmIDs.add(info.planID);
		}

		if (!pmIDs.isEmpty()) {
			Set<Id> productIds = new Set<Id>();

			List<FSO__PreventiveMaintenancePlan__c> pmList = [SELECT FSO__Status__c,
																	 FSO__Account__c,
																	 FSO__Auto_Create_Work_Orders__c,
																	 FSO__Contact__c,
																	 FSO__Work_Order_Type__c,
																	 FSO__Location__c,
																	 FSO__Location__Latitude__s,
																	 FSO__Location__Longitude__s,
																	 FSO__Work_Order_Priority__c,
																	 FSO__Street_Address__c,
																	 FSO__City__c,
																	 FSO__State__c,
																	 FSO__PostalCode__c,
																	 FSO__Country__c,
                                                              		 FSO__Work_Order_Last_Completed_Date__c,
                                                                     FSO__Start_Date__c,
                                                                     FSO__End_Date__c,
                                                                     FSO__Schedule_Total_Count__c,
                                                              		 FSO__Schedule_Duration__c,
                                                              		 FSO__Schedule_Frequency__c, 
                                                                     Service_Type__c,
                                                              		 Service_Type__r.CKSW_BASE__Duration__c,
                                                                     Service_Type__r.CKSW_BASE__Duration_Type__c,
																	 (SELECT Id,
																			 FSO__Work_Plan__c,
																			 FSO__Asset__c,
																			 FSO__Asset__r.Product2Id
																	  FROM FSO__Preventive_Maintenance_Assets__r),
																	 (SELECT FSO__Skill__c
																	  FROM FSO__RequiredSkills__r)
															  FROM FSO__PreventiveMaintenancePlan__c
															  WHERE Id IN :pmIDs AND 
															  FSO__Status__c <> 'Complete'];

			Set<Id> workPlanIds = new Set<Id>();

			for (FSO__PreventiveMaintenancePlan__c plan : pmList) {
				for (FSO__PreventiveMaintenanceAsset__c asset : plan.FSO__Preventive_Maintenance_Assets__r) {
					workPlanIds.add(asset.FSO__Work_Plan__c);
					productIds.add(asset.FSO__Asset__r.Product2Id);
				}
			}

			Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, 
																		(SELECT FSO__Skill__c
																		 FROM FSO__RequiredSkills__r)
																  FROM Product2
																  WHERE Id in :productIds]);

			List<FSO__WorkPlan__c> wpList = [SELECT Id,
											  (SELECT Name,
													  FSO__Description__c,
													  FSO__ExpectedDurationMinutes__c,
													  FSO__Order__c,
													  FSO__IsRequired__c,
													  FSO__WorkPlan__c
											   FROM FSO__Items__r)
											FROM  FSO__WorkPlan__c
											WHERE Id in :workPlanIds];

			Map<Id, FSO__WorkPlan__c> wpMap = new Map<Id, FSO__WorkPlan__c>(wpList);
			List<WorkOrder> wosToInsert = new List<WorkOrder>();
			List<Case> casesToInsert = new List<Case>();
			Map<WorkOrder, Case> woMap = new Map<WorkOrder, Case>();
			List<WorkOrderWrapper> woWrappers = new List<WorkOrderWrapper>();
			Map<WorkOrderLineItem, WorkOrder> itemMap = new Map<WorkOrderLineItem, WorkOrder>();
			List<WorkOrderLineItem> workOrderItems = new List<WorkOrderLineItem>();

			for (FSO__PreventiveMaintenancePlan__c plan : pmList) {

				if (plan.FSO__Auto_Create_Work_Orders__c) {
					WorkOrder wo = new WorkOrder();
					wo.Subject = 'Preventive Maintenance';
					if (plan.FSO__Location__c != null) {
						wo.FSO__Geolocation__Latitude__s = plan.FSO__Location__Latitude__s;
						wo.FSO__Geolocation__Longitude__s = plan.FSO__Location__Longitude__s;
					} else {
						wo.FSO__Geolocation__Latitude__s = 0.0;
						wo.FSO__Geolocation__Longitude__s = 0.0;
					}
					wo.AccountId = plan.FSO__Account__c;
					wo.ContactId = plan.FSO__Contact__c;
					wo.FSO__Type__c = plan.FSO__Work_Order_Type__c;
					wo.FSO__Preventive_Maintenance_Plan__c = plan.Id;
					wo.Priority = plan.FSO__Work_Order_Priority__c;
					wo.Street = plan.FSO__Street_Address__c;
					wo.City = plan.FSO__City__c;
					wo.State = plan.FSO__State__c;
					wo.PostalCode = plan.FSO__PostalCode__c;
					wo.Country = plan.FSO__Country__c;
                    wo.Appointment_Start__c = setWorkOrderTimeframe(plan).startDate;
                    wo.Appointment_Finish__c = setWorkOrderTimeframe(plan).endDate;
					wosToInsert.add(wo);

					Case c = new Case();
					c.AccountId = plan.FSO__Account__c;
					c.Subject = 'Preventive Maintenance';
					c.Origin = 'Phone';
					casesToInsert.add(c);

					List<FSO__RequiredSkill__c> skillsToCreate = new List<FSO__RequiredSkill__c>();

					for (FSO__RequiredSkill__c s : plan.FSO__RequiredSkills__r) {
						skillsToCreate.add(new FSO__RequiredSkill__c(FSO__Skill__c=s.FSO__Skill__c));
					}

					if (plan.FSO__Preventive_Maintenance_Assets__r.size() > 0) {
						for (FSO__PreventiveMaintenanceAsset__c asset : plan.FSO__Preventive_Maintenance_Assets__r) {

							List<FSO__WorkPlanItem__c> items;

							if (wpMap.get(asset.FSO__Work_Plan__c) != null) {
								items = wpMap.get(asset.FSO__Work_Plan__c).FSO__Items__r;
							}

							if (items != null && !items.isEmpty()) {
								for (FSO__WorkPlanItem__c pi : items) { 
									WorkOrderLineItem oi = new WorkOrderLineItem();
									oi.Description = pi.FSO__Description__c;
									oi.FSO__Expected_Duration_Mins__c = pi.FSO__ExpectedDurationMinutes__c;
									oi.FSO__Order__c = pi.FSO__Order__c;
									oi.FSO__IsRequired__c = pi.FSO__IsRequired__c;
									oi.AssetId = asset.FSO__Asset__c;
									
									workOrderItems.add(oi);
									itemMap.put(oi, wo);
								}
							}

							if (asset.FSO__Asset__c != null &&
								asset.FSO__Asset__r.Product2Id != null &&
								productMap.containsKey(asset.FSO__Asset__r.Product2Id) &&
								productMap.get(asset.FSO__Asset__r.Product2Id) != null) {

								for (FSO__RequiredSkill__c s : productMap.get(asset.FSO__Asset__r.Product2Id).FSO__RequiredSkills__r) {
									skillsToCreate.add(new FSO__RequiredSkill__c(FSO__Skill__c=s.FSO__Skill__c));
								}
							}
						}
					}

					woWrappers.add(new WorkOrderWrapper(wo, skillsToCreate, c));
				}
			}

			if (!casesToInsert.isEmpty()) {
				DBUtility.doInsert(casesToInsert);

				for (WorkOrderWrapper w : woWrappers) {
					if (w.cs != null) {
						w.wo.CaseId = w.cs.Id;
					}
				}

				DBUtility.doInsert(wosToInsert);

				List<WorkOrderLineItem> workOrderItemsToInsert = new List<WorkOrderLineItem>();

				for (WorkOrderLineItem i : workOrderItems) {
					WorkOrder wo = itemMap.get(i);
					WorkOrderLineItem newItem = i.clone();
					newItem.WorkOrderId = wo.Id;
					workOrderItemsToInsert.add(newItem);
				}

				DBUtility.doInsert(workOrderItemsToInsert);
			}

			List<FSO__RequiredSkill__c> skillsToInsert = new List<FSO__RequiredSkill__c>();

			for (WorkOrderWrapper w : woWrappers) {
				if (w.skills != null) {
					for (FSO__RequiredSkill__c s : w.skills) {
						s.FSO__Work_Order__c = w.wo.Id;
						skillsToInsert.add(s);
					}
				}
			}

			DBUtility.doInsert(skillsToInsert);
		}
	}
    
    // Calculate the Work Order Start datetime based on the PM plan
    private static WorkOrderTimeframe setWorkOrderTimeframe(FSO__PreventiveMaintenancePlan__c plan){
        WorkOrderTimeframe timeframe = new WorkOrderTimeframe();
        	timeframe.startDate = Datetime.now();
        	timeframe.endDate = Datetime.now().addHours(1);
        Date baseDate = Date.today();
        Integer workOrderGap = 0;
        
        //Set the base date
        System.debug('Last work order completed date: ' + plan.FSO__Work_Order_Last_Completed_Date__c);
        System.debug('Plan start date: ' + plan.FSO__Start_Date__c);
        System.debug('Total Count: ' + plan.FSO__Schedule_Total_Count__c);
        System.debug('Plan end date: ' + plan.FSO__End_Date__c);
        
        
        if(plan.FSO__Schedule_Total_Count__c == null){
        	plan.FSO__Schedule_Total_Count__c = calculateTotalScheduleCount(plan.FSO__Schedule_Duration__c, plan.FSO__Schedule_Frequency__c);
            System.debug('Total count updated from null to ' + plan.FSO__Schedule_Total_Count__c);
        }
        
        if(plan.FSO__Work_Order_Last_Completed_Date__c != null){
            
            baseDate = plan.FSO__Work_Order_Last_Completed_Date__c;
            System.debug('Setting the base date to the last completed date: ' + baseDate);
            
        }
        else if(plan.FSO__Start_Date__c != null){
            
            baseDate = plan.FSO__Start_Date__c;
            System.debug('Setting the base date to the start date: ' + baseDate);
            
        }
        
        //Set the total Work Order count and calculate gap between the PMs
        if(plan.FSO__Schedule_Total_Count__c != null && plan.FSO__Start_Date__c != null && plan.FSO__End_Date__c != null){
            
            Integer pmTimeframe = plan.FSO__Start_Date__c.daysBetween(plan.FSO__End_Date__c);
            System.debug('The PM timeframe is: ' + pmTimeframe);
            //check for negatives. If negative gap, just return the current start value
            if(pmTimeframe < 0){
               return timeframe;
            }
            
            Integer totalWorkOrderCount = 1; //There will be at least 1 Work Order per PM record.
            
            //Check for zero since we'll be dividing later!
            if(plan.FSO__Schedule_Total_Count__c > 0){
                
                totalWorkOrderCount = (Integer)plan.FSO__Schedule_Total_Count__c; //the total count is stored as a decimal, but there's no such thing as a fraction of a record so we're casting this value as an integer
                
            }
            
            workOrderGap = (pmTimeframe / totalWorkOrderCount);
			System.debug('The work order gap is: ' +workOrderGap);
            
        }
        
        //Calculate the start date and time
        if(workOrderGap > 0){
            
            timeframe.startDate = baseDate.addDays(workOrderGap);
            
        }
        
        //calculate the end date using the service type info
        if(plan.Service_Type__c != null && plan.Service_Type__r.CKSW_BASE__Duration__c != null && plan.Service_Type__r.CKSW_BASE__Duration_Type__c != null){
            
            if(plan.Service_Type__r.CKSW_BASE__Duration_Type__c.toLowerCase() == 'hours'){
                
                Integer hours = (Integer)plan.Service_Type__r.CKSW_BASE__Duration__c;
                Integer minutes = (Integer)((plan.Service_Type__r.CKSW_BASE__Duration__c - hours) * 60);
                timeframe.endDate = timeframe.startDate.addHours(hours);
                timeframe.endDate = timeframe.endDate.addMinutes(minutes);
                
            }
            else if(plan.Service_Type__r.CKSW_BASE__Duration_Type__c.toLowerCase() == 'minutes'){
                
                Integer minutes = (Integer)plan.Service_Type__r.CKSW_BASE__Duration__c;
                Integer seconds = (Integer)((plan.Service_Type__r.CKSW_BASE__Duration__c - minutes) * 60);
                timeframe.endDate = timeframe.startDate.addMinutes(minutes);
                timeframe.endDate = timeframe.endDate.addSeconds(seconds);
                
            }
            else if(plan.Service_Type__r.CKSW_BASE__Duration_Type__c.toLowerCase() == 'days'){
                
                Integer days = (Integer)plan.Service_Type__r.CKSW_BASE__Duration__c;
                Integer hours = (Integer)((plan.Service_Type__r.CKSW_BASE__Duration__c - days) * 24);
                timeframe.endDate = timeframe.startDate.addDays(days);
                timeframe.endDate = timeframe.endDate.addHours(hours);
                
            }
            
        }
        
        System.debug('The calculated start date for the next work order is: ' + timeframe.startDate);
        System.debug('The calculated end date for the next work order is: ' + timeframe.endDate);
        
        return timeframe;
    }
    
    private static Integer calculateTotalScheduleCount(String duration, String frequency){
        
        Integer totalCount = 1;
        Map<String,Integer> durationMap = new Map<String,Integer> {'1 Year' => 1,'2 Years' => 2,'3 Years' => 3,'4 Years' => 4,'5 Years' => 5,'6 Years' => 6,'7 Years' => 7,'8 Years' => 8,'9 Years' => 9,'10 Years' => 10,'11 Years' => 11,'12 Years' => 12};
        final String MONTHLY = 'Monthly';
        final Integer MONTHLY_MULTIPLIER = 12;
        final String QUARTERLY = 'Quarterly';
        final Integer QUARTERLY_MULTIPLIER = 4;
        final String YEARLY = 'Yearly';
        final Integer YEARLY_MULTIPLIER = 1;
        final String BIANNUAL = 'Biannual';
        final Integer BIANNNUAL_MULTIPLIER = 2;
        final String EIGHTEEN_MONTH = '18-Month';
        
        //Define the 18-month multiplier
        Integer monthsInDuration = durationMap.containsKey(duration) ? durationMap.get(duration) * 12 : 0;
        Decimal adjustedMonthsInDuration = monthsInDuration / 18.0; //adjust for an 18-month duration
        //if the adjusted months divides evenly by the months in the duration, use the result; otherwise, round up to the nearest integer
        Decimal eighteenMonth = Math.mod(monthsInDuration,18) > 0 ? adjustedMonthsInDuration.round(System.RoundingMode.UP) : adjustedMonthsInDuration; 
       	Integer eighteenMonthMultiplier = eighteenMonth.intValue(); //convert back to integer
        
        //Determine the total schedule count using the duration and duration multiplier
        if(frequency == QUARTERLY && durationMap.containsKey(duration)){
            totalCount = durationMap.get(duration) * QUARTERLY_MULTIPLIER;
        }
        
        else if(frequency == MONTHLY && durationMap.containsKey(duration)){
            totalCount = durationMap.get(duration) * MONTHLY_MULTIPLIER;
        }
        
        else if(frequency == YEARLY && durationMap.containsKey(duration)){
            totalCount = durationMap.get(duration) * YEARLY_MULTIPLIER;
        }
        
        else if(frequency == BIANNUAL && durationMap.containsKey(duration)){
            totalCount = durationMap.get(duration) * BIANNNUAL_MULTIPLIER;
        }
        
        else if(frequency == EIGHTEEN_MONTH && durationMap.containsKey(duration)){
            totalCount = durationMap.get(duration) * eighteenMonthMultiplier;
        }
        
        else totalCount = 1;
        
        return totalCount;
    }

	private class WorkOrderWrapper {
		public Case cs {get;set;}
		public WorkOrder wo {get;set;}
		public List<FSO__RequiredSkill__c> skills {get;set;}

		public WorkOrderWrapper(WorkOrder w, List<FSO__RequiredSkill__c> s, Case c) {
			this.wo = w;
			this.skills = s;
			this.cs = c;
		}

		public void addSkill(FSO__RequiredSkill__c s) {
			if (this.skills == null) {
				this.skills = new List<FSO__RequiredSkill__c>();
			}
			this.skills.add(s);
		}
	}
	
	/**
	* @author Salesforce.com
	* @date 2016
	*
	* @description Inner class used as a wrapper that contains variables passed in from the Process Builder
	*/
	public class Info {
		@InvocableVariable(label='Preventive Maintenance Plan ID' required='true')
		public Id planID;
	}
    
    /**
	* @author Salesforce.com
	* @date 2016
	*
	* @description Inner class used as a wrapper that contains a start and end date
	*/
    private class WorkOrderTimeframe{
        
        public Datetime startDate {get;set;}
        public Datetime endDate {get;set;}
        
    }
}