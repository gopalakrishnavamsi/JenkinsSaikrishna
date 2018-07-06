public class StatusController extends Controller {

	private static final LoggerService LOG = LoggerService.getInstance();
	private static final Map<String, String> STATUS_LABELS = new Map<String, String> {
		'EnvelopeStatus' => Label.EnvelopeStatus,
		'NoEnvelopesSent' => Label.NoEnvelopesSent,
		'Expand' => Label.Expand,
		'Sent' => Label.Sent,
		'Delivered' => Label.Delivered,
		'Completed' => Label.Completed,
		'Declined' => Label.Declined,
		'Voided' => Label.Voided,
		'Signed' => Label.Signed,
		'SentAnEnvelope_2' => Label.SentAnEnvelope_2,
		'LastStatusUpdate' => Label.LastStatusUpdate,
		'Status' => Label.Status,
		'Reason' => Label.Reason,
		'Expires' => Label.Expires,
		'ShowMore' => Label.ShowMore,
		'ShowLess' => Label.ShowLess,
		'IsQueued_2' => Label.IsQueued_2,
		'WillReceive_2' => Label.WillReceive_2,
		'NoAction_2' => Label.NoAction_2,
		'HasDeclined_2' => Label.HasDeclined_2,
		'HasViewed_2' => Label.HasViewed_2,
		'HasSigned_2' => Label.HasSigned_2,
		'ViewAll' => Label.ViewAll
	};

	private StatusController() {
		super();
		this.labels = STATUS_LABELS;
	}

	@AuraEnabled
	public static StatusController newController() {
		return new StatusController();
	}

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
