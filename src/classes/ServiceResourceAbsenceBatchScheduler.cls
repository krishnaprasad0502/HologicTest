global class ServiceResourceAbsenceBatchScheduler implements Schedulable {
	
	global void execute(SchedulableContext ctx){
		ServiceResourceAbsenceBatch batch = new ServiceResourceAbsenceBatch();
		Database.executeBatch(batch, 200);
	}
	
}