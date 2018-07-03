/**Primary interface point for DocuSign for Salesforce envelope management.
 *  A basic flow would be:
 * <pre>
 * // Get an empty envelope definition to begin.
 * Envelope e = EnvelopeService.getEmptyEnvelope(new Entity(sourceId));
 * // Create envelope and add source documents and recipients
 * e = EnvelopeService.createEnvelope(e, null, true);
 * // Create the envelope in draft state
 * e = EnvelopeService.sendEnvelope(e, false, true);
 * // Get tagger URL
 * Url u = EnvelopeService.getSenderViewUrl(e.docuSignId, new Url('https://my.return.url'));
 * // Host the tagging session with the returned URL
 * </pre>
 */
public with sharing class EnvelopeService {

	@TestVisible
	private static final EnvelopeService.Database DB = new EnvelopeService.Database();
	private static final SObjectType TYPE_ENVELOPE = Envelope__c.getSObjectType();
	private static final SObjectType TYPE_DOCUMENT = Document__c.getSObjectType();
	private static final SObjectType TYPE_RECIPIENT = Recipient__c.getSObjectType();
	private static final LoggerService LOG = LoggerService.getInstance();

	@TestVisible
	private static ValidationResult validate(final Envelope envelope, final Boolean sendNow) {
		if (envelope == null) return new ValidationResult(Label.UndefinedEnvelope);

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
							result.add(String.format(Label.RequiredEmptyList_1, new List<String> { cf.name }));
						} else if (String.isBlank(cf.value)) {
							result.add(String.format(Label.RequiredCustomField_1, new List<String> { cf.name }));
						}
					}
				} else if (cf.required && cf.show && String.isBlank(cf.value)) {
					result.add(String.format(Label.RequiredCustomField_1, new List<String> { cf.name }));
				}
			}
		}

		if (envelope.notifications != null &&
			(envelope.notifications.remindAfterDays < 0 || envelope.notifications.remindFrequencyDays < 0
				|| envelope.notifications.expireAfterDays < 0 || envelope.notifications.expireWarnDays < 0)) {

			result.add(Label.InvalidNotificationSettings);
		}

		if (String.isBlank(envelope.emailSubject) || envelope.emailSubject.length() > 100) {
			result.add(Label.EmailSubjectRequired);
		}

		if (String.isNotBlank(envelope.emailMessage) && envelope.emailMessage.length() > 2000) {
			result.add(Label.EmailMessageTooLarge);
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
				Remind__c = e.notifications == null ? false : e.notifications.remind,
				RemindAfterDays__c = e.notifications == null ? 0 : e.notifications.remindAfterDays,
				RemindFrequencyDays__c = e.notifications == null ? 0 : e.notifications.remindFrequencyDays,
				Expires__c = e.notifications == null ? false : e.notifications.expires,
				ExpireAfterDays__c = e.notifications == null ? 0 : e.notifications.expireAfterDays,
				ExpireWarnDays__c = e.notifications == null ? 0 : e.notifications.expireWarnDays,
				UpdateChatter__c = e.notifications == null ? false : e.notifications.updateChatter,
				EmailSubject__c = e.emailSubject,
				EmailMessage__c = e.emailMessage,
				SourceId__c = e.source == null || e.source.id == null ? null : e.source.id,
				Sent__c = e.sent);
		}

		public Envelope queryEnvelope(final Id envelopeId) {
			Permissions.verifyIsQueryable(TYPE_ENVELOPE, new List<String> {
				'Id', 'Name', 'DocuSignId__c', 'EnvelopeConfiguration__c', 'Remind__c', 'RemindAfterDays__c',
				'RemindFrequencyDays__c', 'Expires__c', 'ExpireAfterDays__c', 'ExpireWarnDays__c', 'UpdateChatter__c',
				'EmailSubject__c', 'EmailMessage__c', 'SourceId__c', 'Sent__c'
			});
			Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> {
				'Id', 'Type__c', 'Sequence__c', 'Name', 'Extension__c', 'Size__c', 'SourceId__c'
			});
			Permissions.verifyIsQueryable(TYPE_RECIPIENT, new List<String> {
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
					OwnerId, (
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
				if (dses[0].OwnerId != UserInfo.getUserId()) throw UnauthorizedException.notEnvelopeOwner();
				e = convert(dses[0]);
			}
			return e;
		}

		public Envelope insertEnvelope(final Envelope envelope) {
			Permissions.verifyIsCreateable(TYPE_ENVELOPE, new List<String> {
				'DocuSignId__c', 'EnvelopeConfiguration__c', 'Remind__c', 'RemindAfterDays__c',
				'RemindFrequencyDays__c', 'Expires__c', 'ExpireAfterDays__c', 'ExpireWarnDays__c', 'UpdateChatter__c',
				'EmailSubject__c', 'EmailMessage__c', 'SourceId__c', 'Sent__c'
			});

			if (envelope == null) return envelope;

			Envelope__c e = convert(envelope);
			insert e;

			return convert(e)
				.withDocuments(envelope.documents)
				.withRecipients(envelope.recipients)
				.withCustomFields(envelope.customFields);
		}

		public Envelope updateEnvelope2(final Envelope envelope, final Boolean sendNow) {
			Permissions.verifyIsUpdateable(TYPE_ENVELOPE, new List<String> {
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

			Permissions.verifyIsUpdateable(TYPE_ENVELOPE, new List<String> {
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
			Permissions.verifyIsQueryable(TYPE_ENVELOPE, new List<String> { 'SourceId__c' });
			Permissions.verifyIsDeletable(TYPE_RECIPIENT);
			Permissions.verifyIsDeletable(TYPE_DOCUMENT);
			Permissions.verifyIsDeletable(TYPE_ENVELOPE);
			// Removing status deletion. This isn't necessary because the only time we delete is when we cancel
			// from EEP or the tagger, so no status will be present yet. Also, DS Users do not have delete permission
			// on the status objects.

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
					delete [SELECT Id FROM Recipient__c WHERE Envelope__c = :envelopeId];
					delete [SELECT Id FROM Document__c WHERE Envelope__c = :envelopeId];
					delete e;
				}
			}
			return sourceId;
		}
	}

	@TestVisible
	private static Envelope applyRecipientLimit(
		final Envelope envelope,
		final Integer recipientLimit) {

		if (envelope == null || Collection.isEmpty(envelope.recipients) || recipientLimit <= 0) return envelope;

		List<Recipient> rs = new List<Recipient>();
		Integer counter = 1;
		for (Recipient r : envelope.recipients) {
			if (counter++ > recipientLimit) {
				LOG.warn(String.format('Envelope recipient count {0} is greater than the configured limit {1}.',
					new List<String> {
						String.valueOf(envelope.recipients.size()),
						String.valueOf(recipientLimit)
					}));
				break;
			}
			rs.add(r);
		}

		return envelope.withRecipients(rs);
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
	private static Envelope addNotifications(final Envelope envelope, final Envelope.Notifications notifications) {
		if (envelope == null || notifications == null) return envelope;

		return envelope.withNotifications(notifications);
	}

	@TestVisible
	private static Envelope addEmail(final Envelope envelope, final String emailSubject, final String emailMessage) {
		if (envelope == null || (String.isBlank(emailSubject) && String.isBlank(emailMessage))) return envelope;

		return envelope
			.withEmail(
				StringUtils.replaceUserTags(String.isNotBlank(emailSubject) ? emailSubject : envelope.emailSubject),
				StringUtils.replaceUserTags(String.isNotBlank(emailMessage) ? emailMessage : envelope.emailMessage));
	}

	@TestVisible
	private static Envelope addFiles(final Envelope envelope, final Set<Id> fileIds) {
		if (envelope == null || Collection.isEmpty(fileIds)) return envelope;

		return envelope.addDocuments(DocumentService.resolveFiles(fileIds));
	}

	@TestVisible
	private static Envelope addTemplates(final Envelope envelope, final Set<UUID> templateIds) {
		if (envelope == null || Collection.isEmpty(templateIds)) return envelope;

		return envelope.addDocuments(DocumentService.resolveTemplates(templateIds));
	}

	@TestVisible
	private static Envelope addSourceDocuments(final Envelope envelope, final Entity source,
		final Boolean addLastUpdatedOnly) {

		if (envelope == null || source == null) return envelope;

		return envelope.addDocuments(DocumentService.resolveLinkedFiles(
			envelope.id == null ? new Set<Id> { source.id } : new Set<Id> { source.id, envelope.id },
			addLastUpdatedOnly));
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
	private static Envelope addSourceRecipients(
		final Envelope envelope,
		final Entity source,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (envelope == null || source == null) return envelope;
		return envelope.addRecipients(RecipientService.resolveSourceRecipients(source, defaultEmailSettings));
	}

	@TestVisible
	private static Envelope addCustomRecipients(
		final Envelope envelope,
		final List<EnvelopeConfiguration.CustomRecipient> customRecipients,
		final Map<String, Recipient.SigningGroup> signingGroups,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (envelope == null || customRecipients == null) return envelope;
		return envelope.addRecipients(RecipientService.resolveCustomRecipients(customRecipients, signingGroups,
			defaultEmailSettings));
	}

	/**
	 * Creates a DocuSign envelope. This method does not send the envelope; to do so call
	 * <code>EnvelopeService.sendEnvelope</code>.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param envelope The envelope to create.
	 * @param envelopeConfiguration Optional envelope configuration used to be merged with the envelope.
	 * @param addFromSource Load source documents and recipients if <code>envelopeConfiguration</code> is
	 * <code>null</code>.
	 *
	 * @return The newly-created envelope.
	 * @see EnvelopeService.sendEnvelope for details on how to send the created envelope.
	 */
	public static Envelope createEnvelope(
		final Envelope envelope,
		final EnvelopeConfiguration envelopeConfiguration,
		final Boolean addFromSource) {

		Permissions.verifyIsDocuSignUser();

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
			if (envelopeConfiguration.email != null) {
				result = addEmail(result, envelopeConfiguration.email.subject, envelopeConfiguration.email.message);
			}
			if (envelopeConfiguration.id != null) result.withEnvelopeConfigurationId(envelopeConfiguration.id);

			if (envelopeConfiguration.documents != null) {
				Integer docSequence = 1;

				// Document-level customization
				result = addFiles(result, envelopeConfiguration.documents.fileIds);
				result = addTemplates(result, envelopeConfiguration.documents.templateIds);
			}
			if (envelopeConfiguration.documents == null || envelopeConfiguration.documents.addSourceDocuments) {
				result = addSourceDocuments(result, envelopeConfiguration.source,
					envelopeConfiguration.documents.addLastUpdatedOnly);
			}

			if (envelopeConfiguration.hasRecipients) {
				// Recipient-level customization
				Map<String, Recipient.SigningGroup> signingGroups = RecipientService.resolveSigningGroups(
					envelopeConfiguration.source, envelopeConfiguration.recipients);
				result = addRelatedContacts(result, envelopeConfiguration.source,
					envelopeConfiguration.recipients.relatedContacts, signingGroups);
				result = addCustomRecipients(result, envelopeConfiguration.recipients.recipients, signingGroups,
					defaultEmailSettings);
			}
			if (envelopeConfiguration.recipients == null || envelopeConfiguration.recipients.addSourceRecipients) {
				result = addSourceRecipients(result, envelopeConfiguration.source, defaultEmailSettings);
			}
			if (envelopeConfiguration.recipients != null) {
				result = applyRecipientLimit(result, envelopeConfiguration.recipients.recipientLimit);
			}
		} else if (addFromSource) { // Default settings if custom button is undefined?
			result = addSourceDocuments(result, result.source, false);
			result = addSourceRecipients(result, result.source, defaultEmailSettings);
		}

		return saveEnvelope(result, envelopeConfiguration);
	}

	/**
	 * Retrieves a DocuSign envelope by ID.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The ID of the envelope.
	 *
	 * @return The envelope matching the ID.
	 */
	public static Envelope getEnvelope(final Id envelopeId) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);

		// queryEnvelope verifies ownership
		Envelope envelope = DB.queryEnvelope(envelopeId);

		if (envelope == null) throw new DocuSignException(Label.EnvelopeNotFound);
		return envelope;
	}

	/**
	 * Creates a copy of an envelope that can be resent.
	 * <p>
	 * The caller must be the owner of the original envelope.
	 *
	 * @param envelopeId The ID of the envelope.
	 *
	 * @return A copy of the envelope.
	 * @see Envelope.copy for more details.
	 */
	public static Envelope copyEnvelope(final Id envelopeId) {
		// queryEnvelope via getEnvelope verifies ownership
		return saveEnvelope(getEnvelope(envelopeId).copy(), null);
	}

	/**
	 * Updates envelope notification and email settings. This method does not update the envelope documents or
	 * recipients; use <code>EnvelopeService.updateEnvelope</code> to update everything.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope to update.
	 *
	 * @return The updated envelope.
	 * @see EnvelopeService.updateEnvelope to update all envelope properties.
	 */
	public static Envelope updateEnvelopeNotifications(final Envelope envelope) {
		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		return DB.updateEnvelope2(replaceUserTags(envelope), false);
	}

	/**
	 * Updates an envelope, including documents and recipients. This is a more expensive call than
	 * <code>EnvelopeService.updateEnvelopeNotifications</code> as it updates and recalculates child entries.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope to update.
	 *
	 * @return The updated envelope.
	 */
	public static Envelope updateEnvelope(final Envelope envelope) {
		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		// Determine which documents or recipients have changed
		Envelope original = getEnvelope(envelope.id);

		return DB.updateEnvelope2(replaceUserTags(envelope), false)
			.withRecipients(RecipientService.updateEnvelopeRecipients(envelope.id, original.recipients, envelope.recipients))
			.withDocuments(DocumentService.updateEnvelopeDocuments(envelope.id, original.documents, envelope.documents));
	}

	/**
	 * Sends an envelope to DocuSign. The envelope must have been previously created via
	 * <code>EnvelopeService.createEnvelope</code> or <code>EnvelopeService.copyEnvelope</code>.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope to send.
	 * @param sendNow Whether to send immediately or save as a draft in DocuSign.
	 * @param updateNow Whether to update the envelope record immediately. This update may be deferred if the current
	 * transaction involves subsequent callouts to avoid errors. To update later, call
	 * <code>EnvelopeService.markEnvelopeSent</code>.
	 *
	 * @return The sent envelope.
	 * @see EnvelopeService.markEnvelopeSent for deferred updates.
	 */
	public static Envelope sendEnvelope(final Envelope envelope, final Boolean sendNow, final Boolean updateNow) {
		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		ValidationResult vr = validate(envelope, sendNow);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		Envelope result = replaceUserTags(envelope);
		UUID docuSignId = EnvelopeAPI.getInstance().createEnvelope(result, EnvelopeSettings.getOptions(sendNow));
		result = result.withDocuSignId(docuSignId);
		if (sendNow) result = result.withSent(Datetime.now());
		// Can update in some workflows, but not in others due to subsequent callouts (e.g. mobile)
		if (updateNow) {
			result = DB.updateEnvelope2(result, sendNow);
			if (sendNow) StatusService.createStatus(new List<Envelope.Status> { result.toEnvelopeStatus() });
		}

		return result;
	}

	/**
	 * Marks an envelope's record as sent. Used for deferred updates from <code>EnvelopeService.sendEnvelope</code>. If
	 * the envelope was updated immediately after being sent, this method does not need to be called.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope that was sent.
	 * @param sendNow Whether the envelope was immediately sent or saved as a draft in DocuSign.
	 *
	 * @return <code>true</code> if the update was successful, <code>false</code> otherwise.
	 * @see EnvelopeService.sendEnvelope for more details.
	 */
	public static Boolean markEnvelopeSent(
		final Envelope envelope,
		final Boolean sendNow) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		Envelope e = replaceUserTags(envelope);
		Boolean result = DB.updateEnvelopeSent(e.id, e.docuSignId, e.emailSubject, e.emailMessage, sendNow);
		StatusService.createStatus(new List<Envelope.Status> { e.toEnvelopeStatus() });

		return result;
	}

	/**
	 * Deletes an envelope.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The ID of the envelope to delete.
	 *
	 * @return The Salesforce source ID of the envelope. This can be used to redirect the user upon deletion.
	 */
	public static Id deleteEnvelope(final Id envelopeId) {
		Permissions.verifyIsOwner(envelopeId);

		return DB.deleteEnvelope2(envelopeId);
	}

	/**
	 * Gets an empty envelope definition that can be subsequently completed, created, and sent. This envelope will
	 * be populated with appropriate defaults based on the current account settings and localizations.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param source The originating Salesforce entity for the envelope.
	 *
	 * @return The empty envelope.
	 */
	public static Envelope getEmptyEnvelope(final Entity source) {
		Permissions.verifyIsDocuSignUser();

		EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
		Integer remindAfterDays = Integer.valueOf(settings.RemindAfterDays__c);
		Integer remindFrequencyDays = Integer.valueOf(settings.RemindFrequencyDays__c);
		Integer expireAfterDays = Integer.valueOf(settings.ExpireAfterDays__c);
		Integer expireWarnDays = Integer.valueOf(settings.ExpireWarnDays__c);
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
				Salesforce.isChatterEnabled
					&& (settings.Chatter__c == EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON
					|| settings.Chatter__c == EnvelopeSettings.CHATTER_ENABLED_DEFAULT_ON)),
			emailSettings.subject,
			emailSettings.message,
			source,
			null);
	}

	/**
	 * Retrieves a sender view URL. This will return a one-time use DocuSign tagger URL if called right after an
	 * envelope is created in the draft state.
	 * <p>
	 * When redirected back to the supplied <code>returnUrl</code>, DocuSign appends an <code>event</code> parameter
	 * to the query string. Possible values include:
	 * <ul>
	 *     <li><code>sent</code>: The envelope was sent from the tagger. It may be appropriate to initiate signing
	 *     at this point assuming the first signer or host is the current user.</li>
	 *     <li><code>save</code>: The envelope was saved as a draft in DocuSign.</li>
	 *     <li><code>cancel</code>: The draft was canceled. Delete the envelope via the
	 *     <code>EnvelopeService.deleteEnvelope</code> method.</li>
	 *     <li><code>error</code>: An error was encountered.</li>
	 * </ul>
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 * @param returnUrl The URL to redirect to once the sender action is complete.
	 *
	 * @return The sender view URL.
	 */
	public static Url getSenderViewUrl(final UUID docuSignId, final Url returnUrl) {
		Permissions.verifyIsOwner(docuSignId);

		return EnvelopeAPI.getInstance().getSenderViewUrl(docuSignId, returnUrl);
	}
}
