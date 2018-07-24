// TODO: Add envelope configurations, OCO, settings
// HACK: Deserializing JSON string here because @AuraEnabled methods fail hard with unhelpful server errors on custom types.
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
		public List<Recipient.Role> defaultRoles { get; private set; }
		@AuraEnabled
		public List<Recipient.EmailSettings> emailLocalizations { get; private set; }

		private DraftEnvelope(
			final AccountFeatures accountFeatures,
			final Envelope envelope,
			final List<Template> templates,
			final List<Document> documents,
			final List<Recipient> recipients,
			final List<Recipient.Role> defaultRoles,
			final List<Recipient.EmailSettings> emailLocalizations) {

			this.accountFeatures = accountFeatures;
			this.envelope = envelope;
			this.templates = templates;
			this.documents = documents;
			this.recipients = recipients;
			this.defaultRoles = defaultRoles;
			this.emailLocalizations = emailLocalizations;
		}
	}

	@TestVisible
	private static Url getReturnUrl(final Id sourceId, final Id envelopeId) {
		PageReference pg = Page.ReturnFromDocuSign;
		pg.setRedirect(true);
		Map<String, String> params = pg.getParameters();
		params.put(QueryString.PARAM_SOURCE_ID, sourceId);
		params.put(QueryString.PARAM_ENVELOPE_ID, envelopeId);
		params.put(QueryString.PARAM_DOCUSIGN_ACTION, 'tag');
		return new Url(Salesforce.baseUrl, pg.getUrl());
	}

	@AuraEnabled
	public static DraftEnvelope createDraftEnvelope(final Id sourceId) {
		try {
			Set<Id> sourceIds = new Set<Id> { sourceId };
			// TODO: Check account features for templates. Pull on demand.
			List<Template> templates = TemplateAPI.getInstance().getTemplates();
			return new DraftEnvelope(
				AccountFeatures.getInstance(),
				EnvelopeService.createEnvelope(
					EnvelopeService.getEmptyEnvelope(new Entity(sourceId)),
					null, // envelope configuration
					false),
				templates,
				DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), sourceIds, false),
				RecipientService.getRecipients(sourceId.getSobjectType(), sourceIds),
				EnvelopeSettings.getDefaultRoles(),
				Localization.isEmailLocalizationEnabled() ? Localization.getEmailSettings()
					: new List<Recipient.EmailSettings>());
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
	public static Recipient resolveRecipient(final Id sourceId) {
		try {
			Recipient result = null;
			if (String.isNotBlank(sourceId)) {
				List<Recipient> rs = RecipientService.getRecipients(sourceId.getSobjectType(), new Set<Id> { sourceId });
				if (Collection.isNotEmpty(rs)) {
					result = rs[0];
				}
			}
			return result;
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to resolve recipients');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static Envelope updateEnvelope(final String envelopeJson) {
		try {
			Envelope envelope = (Envelope)JSON.deserialize(envelopeJson, Envelope.class);
			if (envelope != null && Collection.isNotEmpty(envelope.recipients)) {
				// Set host for in person signers
				for (Recipient r : envelope.recipients) {
					if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
						r = r.withHost(UserInfo.getName(), UserInfo.getUserEmail());
					}
				}
			}
			return EnvelopeService.updateEnvelope(envelope);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to update envelope');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static Envelope sendEnvelope(final String envelopeJson) {
		try {
			return EnvelopeService.sendEnvelope((Envelope)JSON.deserialize(envelopeJson, Envelope.class), false, true);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to send envelope');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static String getTaggerUrl(final String envelopeJson) {
		Envelope envelope = (Envelope)JSON.deserialize(envelopeJson, Envelope.class);
		if (envelope == null
			|| envelope.id == null
			|| envelope.source == null
			|| envelope.source.id == null
			|| envelope.docuSignId == null) {

			throw new AuraHandledException(Label.InvalidEnvelope);
		}

		try {
			return EnvelopeService.getSenderViewUrl(
				envelope.docuSignId,
				getReturnUrl(envelope.source.id, envelope.id))
				.toExternalForm();
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to get tagger URL');
			throw new AuraHandledException(ex.getMessage());
		}
	}

	@AuraEnabled
	public static void deleteEnvelope(final Id envelopeId) {
		try {
			EnvelopeService.deleteEnvelope(envelopeId);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to delete envelope');
			if (!(ex instanceof DocuSignException && ex.getMessage() == Label.EnvelopeNotFound)) {
				throw new AuraHandledException(ex.getMessage());
			}
		}
	}
}