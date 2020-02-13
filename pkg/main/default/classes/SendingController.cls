// TODO: Add envelope configurations, OCO, settings
// HACK: Deserializing JSON string here because @AuraEnabled methods fail hard with unhelpful server errors on custom types.
public with sharing class SendingController extends Controller {

	public SendingController() {
	}

	//noinspection ApexUnusedDeclaration
	public SendingController(final ApexPages.StandardController c) {
	}

	public class DraftEnvelope {
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
			final Envelope envelope,
			final List<Template> templates,
			final List<Document> documents,
			final List<Recipient> recipients,
			final List<Recipient.Role> defaultRoles,
			final List<Recipient.EmailSettings> emailLocalizations) {

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
	public static DraftEnvelope createDraftEnvelope(
		final Id sourceId,
		final List<Id> files) {

		try {
			Permissions.verifyIsDocuSignUser();

			Set<Id> sourceIds = new Set<Id> { sourceId };
			EnvelopeSettings es = EnvelopeSettings.getInstance();
			// TODO: Check account features for templates. Pull on demand.
			List<Template> templates;
			List<Document> documents;
			if (Collection.isEmpty(files)) {
				try {
					templates = TemplateAPI.getInstance().getTemplates();
				} catch (APIException ex) {
					if (ex.error == APIError.consentRequired) {
						LoggerService.getInstance().error('Failed to retrieve DocuSign templates: user consent required');
						throw ex; // Let frontend deal with consent flow
					}
					LoggerService.getInstance().warn('User does not have access to DocuSign templates');
					templates = new List<Template>();
				} finally {
					Credentials.save();
				}
				documents = DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), sourceIds, false);
			} else {
				templates = new List<Template>();
				documents = DocumentService.getDocuments(ContentVersion.getSObjectType(), new Set<Id>(files));
			}

			List<Recipient> recipients = RecipientService.getRecipients(sourceId.getSobjectType(), sourceIds);

			return new DraftEnvelope(
				EnvelopeService.getEmptyEnvelope(new Entity(sourceId)),
				templates == null ? new List<Template>() : templates,
				documents == null ? new List<Document>() : documents,
				recipients == null ? new List<Recipient>() : recipients,
				es.defaultRoles,
				es.allowRecipientLanguageSelection ? es.emailLocalizations : new List<Recipient.EmailSettings>());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get draft envelope');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> {
				sourceId
			}, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Recipient resolveRecipient(final Id sourceId) {
		try {
			Recipient result = null;
			if (String.isNotBlank(sourceId)) {
				List<Recipient> rs = RecipientService.getRecipients(sourceId.getSobjectType(), new Set<Id> {
					sourceId
				});
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
	public static Envelope sendEnvelope(final String envelopeJson, final Boolean sendNow,
		final Boolean updateNow) {
		if (AccountProducts.getInstance().isESignatureTrialExpired()) {
			AccountProducts.save();
			throw Controller.wrapException(Label.ExpiredTrialAccount);
		}

		try {
			Envelope result = EnvelopeService.sendEnvelope(
				(Envelope)JSON.deserialize(envelopeJson, Envelope.class),
				sendNow,
				updateNow,
				Application.name);
			AccountProducts.save();
			return result;
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
