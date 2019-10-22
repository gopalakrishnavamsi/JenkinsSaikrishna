/* Batch job to delete all the AgreementConfiguration custom object records.*/
/* This will be invoked during logout to ensure stale SpringCM Folder Ids from the old account are cleared*/
public class ClearFolderConfiguration implements Database.Batchable<SObject> {

    private static final LoggerService LOG = LoggerService.getInstance();

    public Database.QueryLocator start(final Database.BatchableContext context) {
        Permissions.verifyIsQueryable(AgreementConfiguration__c.getSObjectType(), new List<String> { 'Id' });
        return Database.getQueryLocator('SELECT Id FROM AgreementConfiguration__c');              
    }

    public void execute(final Database.BatchableContext context, final List<AgreementConfiguration__c> scope) {
        Permissions.verifyIsDeletable(AgreementConfiguration__c.getSObjectType());
        if (Collection.isNotEmpty(scope)) {
            delete scope;
        }
    }

    public void finish(final Database.BatchableContext context) {
        LOG.info('Successfully completed cleaning up Folder configuration records');
    }

}
