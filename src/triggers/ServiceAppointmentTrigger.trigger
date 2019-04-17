trigger ServiceAppointmentTrigger on ServiceAppointment (after delete,
														 after insert,
														 after undelete,
														 after update,
														 before delete,
														 before insert,
														 before update) {
														 	
	private static Boolean isActive = GlobalUtility.isTriggerActive('ServiceAppointmentTrigger');
	
	System.debug('***[SA already ran pre] ' + ServiceAppointmentTriggerHandler.alreadyRan);
	if(ServiceAppointmentTriggerHandler.alreadyRan == null){
		ServiceAppointmentTriggerHandler.alreadyRan = false;
	} else {
		ServiceAppointmentTriggerHandler.alreadyRan = true;
	}
	System.debug('***[SA already ran post] ' + ServiceAppointmentTriggerHandler.alreadyRan);
	
	if(isActive){// && !ServiceAppointmentTriggerHandler.alreadyRan){
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				ServiceAppointmentTriggerHandler.updateFieldValues(trigger.new);
			}
			if (Trigger.isUpdate) {
				ServiceAppointmentTriggerHandler.updateFieldValues(trigger.new);
				ServiceAppointmentTriggerHandler.checkToReassignAndNotify(trigger.new, trigger.oldMap);
			}
			if (Trigger.isDelete) {}
		}
	
		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				ServiceAppointmentTriggerHandler.setWODateValues(trigger.new);
			}
			if (Trigger.isUpdate) {
				ServiceAppointmentTriggerHandler.updateWorkOrders(trigger.new, trigger.oldMap);
				ServiceAppointmentTriggerHandler.checkToSetWODateValues(trigger.new, trigger.oldMap);
			}
			if (Trigger.isDelete) {}
			if (Trigger.isUndelete) {}
		}
	}
}