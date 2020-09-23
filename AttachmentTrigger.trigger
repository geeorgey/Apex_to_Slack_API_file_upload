trigger AttachmentTrigger on Attachment (after insert) {
    if (Trigger.isAfter) {
        AttachmentTriggerHandler handler = new AttachmentTriggerHandler();
        if(Trigger.isInsert){
            handler.onAfterInsert(Trigger.new);
        }
    }
}
