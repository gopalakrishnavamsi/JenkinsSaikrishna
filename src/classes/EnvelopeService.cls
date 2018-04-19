public with sharing class EnvelopeService {

	@TestVisible
	private static final EnvelopeService.Database DB = new EnvelopeService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();

	@TestVisible
	private static ValidationResult validate(final Envelope envelope, final Boolean sendNow) {
		if (envelope == null) {
			return new ValidationResult(Label.UndefinedEnvelope);
		}

		ValidationResult result = new ValidationResult();

		if (sendNow || Collection.isNotEmpty(envelope.documents)) {
			result.add(DocumentService.validate(envelope.documents));
		}

		if (sendNow || Collection.isNotEmpty(envelope.recipients)) {
			result.add(RecipientService.validate(envelope.recipients, sendNow));
		}

		if (envelope.customFields != null) {
			for (CustomField cf : envelope.customFields) {
				if (cf.isList) {
					if (cf.required && cf.show) {
						if (Collection.isEmpty(cf.items)) {
							result.add(Label.RequiredEmptyList);
							break;
						} else if (String.isBlank(cf.value)) {
							result.add(Label.RequiredCustomFieldsMissing);
							break;
						}
					}
				} else if (cf.required && cf.show && String.isBlank(cf.value)) {
					result.add(Label.RequiredCustomFieldsMissing);
					break;
				}
			}
		}

		if (String.isBlank(envelope.emailSubject) || envelope.emailSubject.length() > 100) {
			result.add(Label.EmailSubjectRequired);
		}

		if (String.isNotBlank(envelope.emailMessage) && envelope.emailMessage.length() > 2000) {
			result.add(Label.EmailMessageTooLarge);
		}

		if (envelope.notifications != null &&
			(envelope.notifications.remindAfterDays < 0 || envelope.notifications.remindFrequencyDays < 0
				|| envelope.notifications.expireAfterDays < 0 || envelope.notifications.expireWarnDays < 0)) {

			result.add(Label.InvalidNotificationSettings);
		}

		return result;
	}

	@TestVisible
	private with sharing class Database {

		@TestVisible
		private Envelope convert(final Envelope__c e) {
			if (e == null) return null;

			return new Envelope(
				e.Id,
				e.Name,
				UUID.tryParse(e.DocuSignId__c),
				e.EnvelopeConfiguration__c,
				DocumentService.convert(e.Documents__r),
				RecipientService.convert(e.Recipients__r),
				null, // custom fields not stored in SFDC
				new Envelope.Notifications(
					e.Remind__c,
					Integer.valueOf(e.RemindAfterDays__c),
					Integer.valueOf(e.RemindFrequencyDays__c),
					e.Expires__c,
					Integer.valueOf(e.ExpireAfterDays__c),
					Integer.valueOf(e.ExpireWarnDays__c),
					e.UpdateChatter__c),
				e.EmailSubject__c,
				e.EmailMessage__c,
				e.SourceId__c == null ? null : new Entity(e.SourceId__c),
				e.Sent__c);
		}

		@TestVisible
		private Envelope__c convert(final Envelope e) {
			if (e == null) return null;

			return new Envelope__c(
				Id = e.id,
				DocuSignId__c = UUID.toString(e.docuSignId),
				EnvelopeConfiguration__c = e.envelopeConfigurationId,
				Remind__c = e.notifications == null ? null : e.notifications.remind,
				RemindAfterDays__c = e.notifications == null ? null : e.notifications.remindAfterDays,
				RemindFrequencyDays__c = e.notifications == null ? null : e.notifications.remindFrequencyDays,
				Expires__c = e.notifications == null ? null : e.notifications.expires,
				ExpireAfterDays__c = e.notifications == null ? null : e.notifications.expireAfterDays,
				ExpireWarnDays__c = e.notifications == null ? null : e.notifications.expireWarnDays,
				UpdateChatter__c = e.notifications == null ? null : e.notifications.updateChatter,
				EmailSubject__c = e.emailSubject,
				EmailMessage__c = e.emailMessage,
				SourceId__c = e.source == null || e.source.id == null ? null : e.source.id);
		}

		public Envelope queryEnvelope(final Id envelopeId) {
			Permissions.verifyIsQueryable('Envelope__c', new List<String> {
				'Id', 'Name', 'DocuSignId__c', 'EnvelopeConfiguration__c', 'Remind__c', 'RemindAfterDays__c',
				'RemindFrequencyDays__c', 'Expires__c', 'ExpireAfterDays__c', 'ExpireWarnDays__c', 'UpdateChatter__c',
				'EmailSubject__c', 'EmailMessage__c', 'SourceId__c', 'Sent__c'
			});
			Permissions.verifyIsQueryable('Document__c', new List<String> {
				'Id', 'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
			});
			Permissions.verifyIsQueryable('Recipient__c', new List<String> {
				'Id', 'Sequence__c', 'Name', 'Email__c', 'RoutingOrder__c', 'Type__c', 'Role__c', 'AccessCode__c',
				'IdCheckRequired__c', 'SmsPhoneNumber__c', 'Note__c', 'Language__c', 'EmailSubject__c', 'EmailMessage__c',
				'HostName__c', 'HostEmail__c', 'SignNow__c', 'SigningGroupId__c', 'SigningGroupName__c', 'SourceId__c'
			});

			List<Envelope__c> dses = [
				SELECT Id,
					Name,
					DocuSignId__c,
					EnvelopeConfiguration__c,
					Remind__c,
					RemindAfterDays__c,
					RemindFrequencyDays__c,
					Expires__c,
					ExpireAfterDays__c,
					ExpireWarnDays__c,
					UpdateChatter__c,
					EmailSubject__c,
					EmailMessage__c,
					SourceId__c,
					Sent__c,
					Owner.Id, (
					SELECT Id,
						Type__c,
						Sequence__c,
						Name,
						Extension__c,
						Size__c,
						SourceId__c
					FROM Documents__r
					ORDER BY Sequence__c
				), (
					SELECT Id,
						Sequence__c,
						Name,
						Email__c,
						RoutingOrder__c,
						Type__c,
						Role__c,
						AccessCode__c,
						IdCheckRequired__c,
						SmsPhoneNumber__c,
						Note__c,
						Language__c,
						EmailSubject__c,
						EmailMessage__c,
						HostName__c,
						HostEmail__c,
						SignNow__c,
						SigningGroupId__c,
						SigningGroupName__c,
						SourceId__c
					FROM Recipients__r
					ORDER BY Sequence__c
				)
				FROM Envelope__c
				WHERE Id = :envelopeId
				LIMIT 1
			];

			Envelope e = null;
			if (Collection.isNotEmpty(dses)) {
				// DFS-4283: Ensure current user owns the requested envelope.
				if (dses[0].OwnerId != UserInfo.getUserId()) throw UnauthorizedException.notEnvelopeOwner();
				e = convert(dses[0]);
			}
			return e;
		}

		public Envelope insertEnvelope(final Envelope envelope) {
			Permissions.verifyIsCreateable('Envelope__c', new List<String> {
				'DocuSignId__c', 'EnvelopeConfiguration__c', 'Remind__c', 'RemindAfterDays__c',
				'RemindFrequencyDays__c', 'Expires__c', 'ExpireAfterDays__c', 'ExpireWarnDays__c', 'UpdateChatter__c',
				'EmailSubject__c', 'EmailMessage__c', 'SourceId__c', 'Sent__c'
			});

			if (envelope == null) return envelope;

			Envelope__c e = convert(envelope);
			upsert e;

			return convert(e)
				.withDocuments(envelope.documents)
				.withRecipients(envelope.recipients)
				.withCustomFields(envelope.customFields);
		}

		public Envelope updateEnvelope2(final Envelope envelope, final Boolean sendNow) {
			Permissions.verifyIsUpdateable('Envelope__c', new List<String> {
				'DocuSignId__c', 'EnvelopeConfiguration__c', 'Remind__c', 'RemindAfterDays__c',
				'RemindFrequencyDays__c', 'Expires__c', 'ExpireAfterDays__c', 'ExpireWarnDays__c', 'UpdateChatter__c',
				'EmailSubject__c', 'EmailMessage__c', 'SourceId__c', 'Sent__c'
			});

			if (envelope == null) return envelope;

			Envelope__c e = convert(envelope);
			if (sendNow) {
				e.Sent__c = DateTime.now();
			}
			update e;

			return convert(e)
				.withCustomFields(envelope.customFields)
				.withDocuments(envelope.documents)
				.withRecipients(envelope.recipients);
		}

		public Boolean updateEnvelopeSent(final Id envelopeId, final UUID dsEnvelopeId,
			final String emailSubject, final String emailMessage, final Boolean sendNow) {

			Permissions.verifyIsUpdateable('Envelope__c', new List<String> {
				'DocuSignId__c', 'EmailSubject__c', 'EmailMessage__c', 'Sent__c'
			});

			update new Envelope__c(
				Id = envelopeId,
				DocuSignId__c = UUID.toString(dsEnvelopeId),
				EmailSubject__c = emailSubject,
				EmailMessage__c = emailMessage,
				Sent__c = sendNow ? DateTime.now() : null);
			return true;
		}

		public Id deleteEnvelope2(final Id envelopeId) {
			Permissions.verifyIsQueryable('Envelope__c', new List<String> { 'SourceId__c' });
			Permissions.verifyIsDeletable('Recipient__c');
			Permissions.verifyIsDeletable('Document__c');
			Permissions.verifyIsDeletable('Envelope__c');
			// Removing status deletion. This isn't necessary because the only time we delete is when we cancel
			// from EEP or the tagger, so no status will be present yet. Also, DS Users do not have delete permission
			// on the status objects.
//			Permissions.verifyIsDeletable('EnvelopeStatus__c');
//			Permissions.verifyIsDeletable('RecipientStatus__c');

			Id sourceId = null;
			if (envelopeId != null) {
				List<Envelope__c> es = [
					SELECT DocuSignId__c, SourceId__c
					FROM Envelope__c
					WHERE Id = :envelopeId
					LIMIT 1
				];
				if (Collection.isNotEmpty(es)) {
					Envelope__c e = es[0];
					if (String.isNotBlank(e.SourceId__c)) {
						try {
							sourceId = Id.valueOf(e.SourceId__c);
						} catch (Exception ex) {
							LOG.exception(ex, 'Failed to parse envelope SourceId__c as Id: ' + e.SourceId__c);
						}
					}
//					if (String.isNotBlank(e.DocuSignId__c)) {
//						delete [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignEnvelopeId__c = :e.DocuSignId__c];
//						delete [SELECT Id FROM RecipientStatus__c WHERE DocuSignEnvelopeId__c = :e.DocuSignId__c];
//					}
					delete [SELECT Id FROM Recipient__c WHERE Envelope__c = :envelopeId];
					delete [SELECT Id FROM Document__c WHERE Envelope__c = :envelopeId];
					delete e;
				}
			}
			return sourceId;
		}
	}

	@TestVisible
	private static Envelope replaceUserTags(final Envelope envelope) {
		if (envelope == null) return envelope;

		return envelope
			.withEmail(
				StringUtils.replaceUserTags(envelope.emailSubject),
				StringUtils.replaceUserTags(envelope.emailMessage));
	}

	@TestVisible
	private static Envelope saveEnvelope(final Envelope envelope, final EnvelopeConfiguration envelopeConfiguration) {
		// Custom fields are not stored in our custom object, so must load and merge them later.
		Envelope result = DB.insertEnvelope(replaceUserTags(envelope));

		// Add any non-custom-button documents and recipients
		if (Collection.isNotEmpty(result.documents)) {
			result = result.withDocuments(DocumentService.addEnvelopeDocuments(result.id, result.documents));
		}
		if (Collection.isNotEmpty(result.recipients)) {
			result = result.withRecipients(RecipientService.addEnvelopeRecipients(
				result.id,
				result.recipients,
				envelopeConfiguration != null ? envelopeConfiguration.email : null,
				envelopeConfiguration != null ? envelopeConfiguration.recipients : null));
		}

		return result;
	}

	@TestVisible
	private static Envelope addNotifications(
		final Envelope envelope,
		final Envelope.Notifications notifications) {

		if (envelope == null || notifications == null) return envelope;

		return envelope.withNotifications(notifications);
	}

	@TestVisible
	private static Envelope addEmail(
		final Envelope envelope,
		final Recipient.EmailSettings emailSettings) {

		if (envelope == null || emailSettings == null) return envelope;

		return envelope
			.withEmail(
				StringUtils.replaceUserTags(String.isNotBlank(emailSettings.subject) ? emailSettings.subject : envelope.emailSubject),
				StringUtils.replaceUserTags(String.isNotBlank(emailSettings.message) ? emailSettings.message : envelope.emailMessage));
	}

	@TestVisible
	private static Envelope addFiles(
		final Envelope envelope,
		final Set<Id> fileIds) {

		if (envelope == null || Collection.isEmpty(fileIds)) return envelope;

		return envelope.addDocuments(DocumentService.resolveFiles(fileIds));
	}

	@TestVisible
	private static Envelope addTemplates(
		final Envelope envelope,
		final Set<UUID> templateIds) {

		if (envelope == null || Collection.isEmpty(templateIds)) return envelope;

		return envelope.addDocuments(DocumentService.resolveTemplates(templateIds));
	}

	@TestVisible
	private static Envelope addDefaultDocuments(
		final Envelope envelope,
		final Entity source,
		final Boolean addSourceDocuments) {

		if (envelope == null || source == null || !addSourceDocuments) return envelope;

		return envelope.addDocuments(DocumentService.resolveLinkedFiles(
			envelope.id == null ? new Set<Id> { source.id } : new Set<Id> { source.id, envelope.id }));
	}

	@TestVisible
	private static Envelope addRelatedContacts(
		final Envelope envelope,
		final Entity source,
		final List<EnvelopeConfiguration.RelatedContacts> relatedContacts,
		final Map<String, Recipient.SigningGroup> signingGroups) {

		if (envelope == null || source == null || relatedContacts == null) return envelope;

		for (EnvelopeConfiguration.RelatedContacts rc : relatedContacts) {
			envelope.addRecipients(RecipientService.resolveRelatedContacts(source, rc, signingGroups));
		}

		return envelope;
	}

	@TestVisible
	private static Envelope addDefaultRecipients(
		final Envelope envelope,
		final Entity source,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (envelope == null || source == null) return envelope;
		return envelope.addRecipients(RecipientService.resolveDefaultRecipients(source, defaultEmailSettings));
	}

	@TestVisible
	private static Envelope addCustomRecipients(
		final Envelope envelope,
		final EnvelopeConfiguration.Recipients customRecipients,
		final Map<String, Recipient.SigningGroup> signingGroups,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (envelope == null || customRecipients == null) return envelope;
		return envelope.addRecipients(RecipientService.resolveCustomRecipients(customRecipients, signingGroups,
			defaultEmailSettings));
	}

	public static Envelope createEnvelope(
		final Envelope envelope,
		final EnvelopeConfiguration envelopeConfiguration,
		final Boolean loadDefaults) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		Recipient.EmailSettings defaultEmailSettings =
			Localization.isEmailLocalizationEnabled() ? Localization.getEmailSettingsForCurrentLanguage() : null;
		Envelope result = envelope;
		if (envelopeConfiguration != null) {
			// FIXME: Enable envelope configuration validation
//			vr = EnvelopeConfigurationManager.validate(envelopeConfiguration);
//			if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

			// Envelope-level customization
			result = result.withEnvelopeConfigurationId(envelopeConfiguration.id);
			result = addNotifications(result, envelopeConfiguration.notifications);
			result = addEmail(result, envelopeConfiguration.email);
			if (envelopeConfiguration.id != null) result.withEnvelopeConfigurationId(envelopeConfiguration.id);

			if (envelopeConfiguration.documents != null) {
				Integer docSequence = 1;

				// Document-level customization
				result = addFiles(result, envelopeConfiguration.documents.fileIds);
				result = addTemplates(result, envelopeConfiguration.documents.templateIds);
				result = addDefaultDocuments(result, envelopeConfiguration.source, envelopeConfiguration.documents.addSourceDocuments);
			}

			if (envelopeConfiguration.hasRecipients) {
				// Recipient-level customization
				Map<String, Recipient.SigningGroup> signingGroups = RecipientService.resolveSigningGroups(
					envelopeConfiguration.source, envelopeConfiguration.recipients);
				result = addRelatedContacts(result, envelopeConfiguration.source, envelopeConfiguration.recipients.relatedContacts, signingGroups);
				result = addCustomRecipients(result, envelopeConfiguration.recipients.recipients, signingGroups, defaultEmailSettings);

			}
			if (envelopeConfiguration.recipients != null && envelopeConfiguration.recipients.addSourceRecipients) {
				result = addDefaultRecipients(result, envelopeConfiguration.source, defaultEmailSettings);
			}
		} else if (loadDefaults) { // Default settings if custom button is undefined?
			result = addDefaultDocuments(result, result.source, EnvelopeSettings__c.getOrgDefaults().AddFiles__c);
			result = addDefaultRecipients(result, result.source, defaultEmailSettings);
		}

		return saveEnvelope(result, envelopeConfiguration);
	}

	public static Envelope getEnvelope(final Id envelopeId) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		final Envelope envelope = DB.queryEnvelope(envelopeId);
		if (envelope == null) throw new DocuSignException(Label.EnvelopeNotFound);
		return envelope;
	}

	public static Envelope copyEnvelope(final Id envelopeId) {
		return saveEnvelope(getEnvelope(envelopeId).copy(), null);
	}

	public static Envelope updateEnvelopeNotifications(final Envelope envelope) {
		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		return DB.updateEnvelope2(replaceUserTags(envelope), false);
	}

	public static Envelope updateEnvelope(final Envelope envelope) {
		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		// Determine which documents or recipients have changed
		Envelope original = getEnvelope(envelope.id);

		return DB.updateEnvelope2(replaceUserTags(envelope), false)
			.withRecipients(RecipientService.updateEnvelopeRecipients(envelope.id, original.recipients, envelope.recipients))
			.withDocuments(DocumentService.updateEnvelopeDocuments(envelope.id, original.documents, envelope.documents));
	}

	public static Envelope sendEnvelope(final Envelope envelope, final Boolean sendNow, final Boolean updateNow) {
		ValidationResult vr = validate(envelope, sendNow);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		Envelope result = replaceUserTags(envelope);
		UUID docuSignId = EnvelopeAPI.getInstance().createEnvelope(result, EnvelopeSettings.getOptions(sendNow));
		result = result.withDocuSignId(docuSignId).withSent(Datetime.now());
		// Can update in some workflows, but not in others due to subsequent callouts (e.g. mobile)
		if (updateNow) {
			result = DB.updateEnvelope2(result, sendNow);
		}

		return result;
	}

	public static Boolean markSent(
		final Envelope envelope,
		final Boolean sendNow) {

		Envelope result = replaceUserTags(envelope);
		return DB.updateEnvelopeSent(result.id, result.docuSignId, result.emailSubject, result.emailMessage, sendNow);
	}

	public static Id deleteEnvelope(final Id envelopeId) {
		return DB.deleteEnvelope2(envelopeId);
	}

	public static Envelope getEmptyEnvelope(final Entity source) {
		EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
		Integer remindAfterDays = Integer.valueOf(settings.ReminderDays__c);
		Integer remindFrequencyDays = Integer.valueOf(settings.ReminderRepeatInterval__c);
		Integer expireAfterDays = Integer.valueOf(settings.ExpireDays__c);
		Integer expireWarnDays = Integer.valueOf(settings.ExpireWarningInterval__c);
		Recipient.EmailSettings emailSettings = Localization.getEmailSettingsForCurrentLanguage();
		return new Envelope(
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			new Envelope.Notifications(
				remindAfterDays >= 0,
				remindAfterDays >= 0 ? remindAfterDays : null,
				remindFrequencyDays >= 0 ? remindFrequencyDays : null,
				expireAfterDays >= 0,
				expireAfterDays >= 0 ? expireAfterDays : null,
				expireWarnDays >= 0 ? expireWarnDays : null,
				Salesforce.isChatterEnabled && settings.Chatter__c == EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON),
			emailSettings.subject,
			emailSettings.message,
			source,
			null);
	}
}
