public class StatusController extends Controller {

	@AuraEnabled
	public static List<Envelope.Status> getStatus(final Id sourceId, final Integer recordLimit) {
		try {
			Permissions.verifyIsDocuSignUser();
			return StatusService.getStatus(new Set<Id> { sourceId }, Integer.valueOf(recordLimit));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve status');
		}
	}

	@AuraEnabled(Cacheable = true)
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
			throw Controller.wrapException(ex, 'Failed to retrieve status list views');
		}
	}
}
