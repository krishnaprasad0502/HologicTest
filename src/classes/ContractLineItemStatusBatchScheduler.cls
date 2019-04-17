global class ContractLineItemStatusBatchScheduler implements Schedulable {
	
	global void execute(SchedulableContext ctx){
		ContractLineItemStatusBatch batch = new ContractLineItemStatusBatch();
		Database.executeBatch(batch, 200);
	}
	
}