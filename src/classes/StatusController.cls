public class StatusController {

	private static final LoggerService LOG = LoggerService.getInstance();

	@AuraEnabled
	public static List<Envelope.Status> getStatus(final Id sourceId) {
		try {
			// TODO: Return empty list for UnauthorizedException
			return StatusService.getStatus(new Set<Id> { sourceId }, 5);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to retrieve status');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static List<ListView> getStatusListViews() {
		try {
			Permissions.verifyIsQueryable(ListView.getSObjectType(), new List<String> {
				'Id', 'Name', 'SobjectType'
			});

			return [
				SELECT Id, Name, SobjectType
				FROM ListView
				WHERE SobjectType = :(Application.namespacePrefix + 'EnvelopeStatus__c')
			];
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to retrieve status list views');
			throw new AuraHandledException(ex.getMessage());
		}
	}
}
