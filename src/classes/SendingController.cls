// TODO: Add envelope configurations, OCO, settings
public with sharing class SendingController extends Controller {

	private static final LoggerService LOG = LoggerService.getInstance();

	public Entity source { get; private set; }

	public SendingController(final ApexPages.StandardController c) {
		this.source = new Entity((Id)c.getId());
	}

	public class DraftEnvelope {
		@AuraEnabled
		public AccountFeatures accountFeatures { get; private set; }
		@AuraEnabled
		public Envelope envelope { get; private set; }
		@AuraEnabled
		public List<Template> templates { get; private set; }
		@AuraEnabled
		public List<Document> documents { get; private set; }
		@AuraEnabled
		public List<Recipient> recipients { get; private set; }
		@AuraEnabled
		public List<Recipient.EmailSettings> emailSettings { get; private set; }

		private DraftEnvelope(
			final AccountFeatures accountFeatures,
			final Envelope envelope,
			final List<Template> templates,
			final List<Document> documents,
			final List<Recipient> recipients,
			final List<Recipient.EmailSettings> emailSettings) {

			this.accountFeatures = accountFeatures;
			this.envelope = envelope;
			this.templates = templates;
			this.documents = documents;
			this.recipients = recipients;
			this.emailSettings = emailSettings;
		}
	}

	@AuraEnabled
	public static DraftEnvelope createDraftEnvelope(final Id sourceId) {
		try {
			Set<Id> sourceIds = new Set<Id> { sourceId };
			// TODO: Check account features for templates. Pull on demand.
			List<Template> templates = TemplateAPI.getInstance().getTemplates();
			return new DraftEnvelope(
				AccountFeatures.getInstance(),
				null,
//				EnvelopeService.createEnvelope(
//					EnvelopeService.getEmptyEnvelope(new Entity(sourceId)),
//					null, // envelope configuration
//					false),
				templates,
				DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), sourceIds, false),
				RecipientService.getRecipients(sourceId.getSobjectType(), sourceIds),
				Localization.getEmailSettings());
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to get draft envelope');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to get linked documents');
			throw new AuraHandledException(ex.getMessage());
		}
	}


	@AuraEnabled
	public static void deleteEnvelope(final Id envelopeId) {
		try {
			EnvelopeService.deleteEnvelope(envelopeId);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to delete envelope');
			throw new AuraHandledException(ex.getMessage());
		}
	}
}
