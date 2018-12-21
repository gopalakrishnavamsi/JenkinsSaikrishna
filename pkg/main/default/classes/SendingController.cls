// TODO: Add envelope configurations, OCO, settings
// HACK: Deserializing JSON string here because @AuraEnabled methods fail hard with unhelpful server errors on custom types.
public with sharing class SendingController extends Controller {

	public SendingController() {
	}

	public SendingController(final ApexPages.StandardController c) {
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
			Permissions.verifyIsDocuSignUser();

			Set<Id> sourceIds = new Set<Id> { sourceId };
			EnvelopeSettings es = EnvelopeSettings.getInstance();
			// TODO: Check account features for templates. Pull on demand.
			List<Template> templates;
			try {
				templates = TemplateAPI.getInstance().getTemplates();
			} catch (APIException ex) {
				// TODO: Handle only USER_LACKS_PERMISSIONS error here. Cache response.
				LoggerService.getInstance().warn('User does not have access to DocuSign templates');
				templates = new List<Template>();
			} finally {
				Credentials.save();
			}
			return new DraftEnvelope(
				AccountFeatures.getInstance(),
				EnvelopeService.getEmptyEnvelope(new Entity(sourceId)),
				templates,
				DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), sourceIds, false),
				RecipientService.getRecipients(sourceId.getSobjectType(), sourceIds),
				es.defaultRoles,
				es.allowRecipientLanguageSelection ? es.emailLocalizations : new List<Recipient.EmailSettings>());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get draft envelope');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}

	@AuraEnabled(Cacheable = true)
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
			throw Controller.wrapException(ex, 'Failed to resolve recipients');
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
						r = r.withHost(UserInfo.getName(), UserInfo.getUserEmail(), true);
					}
				}
			}
			return EnvelopeService.updateEnvelope(envelope);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to update envelope');
		}
	}

	@AuraEnabled
	public static Envelope sendEnvelope(final String envelopeJson) {
		try {
			return EnvelopeService.sendEnvelope((Envelope)JSON.deserialize(envelopeJson, Envelope.class), false, true);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send envelope');
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

			throw Controller.wrapException(Label.InvalidEnvelope);
		}

		try {
			return EnvelopeService.getSenderViewUrl(
				envelope.docuSignId,
				getReturnUrl(envelope.source.id, envelope.id))
				.toExternalForm();
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get tagger URL');
		}
	}

	@AuraEnabled
	public static void deleteEnvelope(final Id envelopeId) {
		try {
			EnvelopeService.deleteEnvelope(envelopeId);
		} catch (Exception ex) {
			if (!(ex instanceof DocuSignException && ex.getMessage() == Label.EnvelopeNotFound)) {
				throw Controller.wrapException(ex, 'Failed to delete envelope');
			}
		}
	}
}
