public class StatusController extends Controller {

	private static final LoggerService LOG = LoggerService.getInstance();

	@AuraEnabled
	public static List<Envelope.Status> getStatus(final Id sourceId) {
		try {
			return StatusService.getStatus(new Set<Id> { sourceId }, 5);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to retrieve status');
			throw new AuraHandledException(ex.getMessage());
		}
	}

//	@AuraEnabled
//	public static String getEnvelopeListView() {
//		responseData rd = new responseData();
//
//		try {
//			List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Envelope__c' LIMIT 1];
//			rd.results.put('listView', listViews);
//		} catch (Exception e) {
//			rd.addError(e.getMessage());
//		}
//		return rd.getJsonString();
//	}
//
//	private static Boolean checkAccessForListViews() {
//		return dmlManager.checkAccess(new Map<String, Map<String, List<String>>> {
//			'ListView' => new Map<String, List<String>> {
//				'Read' => new List<String> {
//					'Id',
//					'Name',
//					'SobjectType'
//				}
//			}
//		});
//	}
}
