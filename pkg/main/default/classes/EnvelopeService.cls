/**
 * Primary interface point for DocuSign eSignature envelope management.
 * <p>
 * A basic flow would be:
 * <pre>
 * // Get an empty envelope definition to begin.
 * Envelope e = dfsle.EnvelopeService.getEmptyEnvelope(new Entity(sourceId));
 * // Send envelope and add source documents and recipients
 * e = dfsle.EnvelopeService.sendEnvelope(e, false);
 * // Get tagger URL (this must be in a future method or separate transaction to avoid a CalloutException)
 * Url u = dfsle.EnvelopeService.getSenderViewUrl(e.docuSignId, new Url('https://my.return.url'));
 * // Host the tagging session with the returned URL
 * </pre>
 */
global with sharing class EnvelopeService {

	@TestVisible
	private static final EnvelopeService.Database DB = new EnvelopeService.Database();
	private static final SObjectType TYPE_ENVELOPE = Envelope__c.getSObjectType();
	private static final SObjectType TYPE_DOCUMENT = Document__c.getSObjectType();
	private static final SObjectType TYPE_RECIPIENT = Recipient__c.getSObjectType();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static final String SENDER_TOKEN = 'Apex Toolkit';
	@TestVisible
	private static final Integer MULTI_SEND_ENVELOPE_LIMIT = 99;

	public static ValidationResult validate(final Envelope envelope, final Boolean sendNow) {
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
				new Notifications(
					e.Remind__c,
					Integer.valueOf(e.RemindAfterDays__c),
					Integer.valueOf(e.RemindFrequencyDays__c),
					e.Expires__c,
					Integer.valueOf(e.ExpireAfterDays__c),
					Integer.valueOf(e.ExpireWarnDays__c)),
				e.EmailSubject__c,
				e.EmailMessage__c,
				String.isBlank(e.SenderPermissions__c) ? Envelope.DEFAULT_PERMISSIONS
					: (Envelope.Permissions)JSON.deserialize(e.SenderPermissions__c, Envelope.Permissions.class),
				String.isBlank(e.Options__c) ? Envelope.DEFAULT_OPTIONS : EnvelopeParser.deserializeOptions(e.Options__c),
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
				Remind__c = e.notifications != null && e.notifications.remind == true, // Can be null
				RemindAfterDays__c = e.notifications == null ? 0 : e.notifications.remindAfterDays,
				RemindFrequencyDays__c = e.notifications == null ? 0 : e.notifications.remindFrequencyDays,
				Expires__c = e.notifications != null && e.notifications.expires == true, // Can be null
				ExpireAfterDays__c = e.notifications == null ? 0 : e.notifications.expireAfterDays,
				ExpireWarnDays__c = e.notifications == null ? 0 : e.notifications.expireWarnDays,
				EmailSubject__c = e.emailSubject,
				EmailMessage__c = e.emailMessage,
				SenderPermissions__c = e.senderPermissions == null ? null : JSON.serialize(e.senderPermissions),
				Options__c = e.options == null ? null : JSON.serialize(e.options),
				SourceId__c = e.source == null || e.source.id == null ? null : e.source.id,
				Sent__c = e.sent);
		}

		public Envelope queryEnvelope(final Id envelopeId) {
			Permissions.verifyIsQueryable(TYPE_ENVELOPE, new List<String> {
				'Id',
				'Name',
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'ExpireAfterDays__c',
				Application.namespacePrefix + 'Expires__c',
				Application.namespacePrefix + 'ExpireWarnDays__c',
				Application.namespacePrefix + 'Remind__c',
				Application.namespacePrefix + 'RemindAfterDays__c',
				Application.namespacePrefix + 'RemindFrequencyDays__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Sent__c'
			});
			Permissions.verifyIsQueryable(TYPE_DOCUMENT, new List<String> {
				'Id',
				'Name',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'LastModified__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'Size__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});
			Permissions.verifyIsQueryable(TYPE_RECIPIENT, new List<String> {
				'Id',
				'Name',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeRecipientId__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Role__c',
				Application.namespacePrefix + 'RoleValue__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
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
					EmailSubject__c,
					EmailMessage__c,
					SenderPermissions__c,
					Options__c,
					SourceId__c,
					Sent__c,
					OwnerId, (
					SELECT Id,
						Type__c,
						Sequence__c,
						Name,
						Extension__c,
						Size__c,
						LastModified__c,
						SourceId__c,
						ReadOnly__c,
						Required__c
					FROM Documents__r
					ORDER BY Sequence__c
				), (
					SELECT Id,
						EnvelopeRecipientId__c,
						Sequence__c,
						Name,
						Email__c,
						RoutingOrder__c,
						Type__c,
						Role__c,
						RoleValue__c,
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
						SourceId__c,
						ReadOnly__c,
						Required__c
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
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'ExpireAfterDays__c',
				Application.namespacePrefix + 'Expires__c',
				Application.namespacePrefix + 'ExpireWarnDays__c',
				Application.namespacePrefix + 'Remind__c',
				Application.namespacePrefix + 'RemindAfterDays__c',
				Application.namespacePrefix + 'RemindFrequencyDays__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'Sent__c',
				Application.namespacePrefix + 'SourceId__c'
			});

			if (envelope == null) return envelope;

			Envelope__c e = convert(envelope);
			insert e;

			return convert(e)
				.withDocuments(envelope.documents)
				.withRecipients(envelope.recipients)
				.withCustomFields(envelope.customFields);
		}

		public Envelope__c insertEnvelope() {
			Permissions.verifyIsCreateable(TYPE_ENVELOPE, new List<String> {
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'ExpireAfterDays__c',
				Application.namespacePrefix + 'Expires__c',
				Application.namespacePrefix + 'ExpireWarnDays__c',
				Application.namespacePrefix + 'Remind__c',
				Application.namespacePrefix + 'RemindAfterDays__c',
				Application.namespacePrefix + 'RemindFrequencyDays__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'Sent__c',
				Application.namespacePrefix + 'SourceId__c'
			});

			Envelope__c env = new Envelope__c();
			insert env;
			return env;
		}

		public List<Envelope> insertSentEnvelopes(final List<Envelope> envelopes) {
			Permissions.verifyIsCreateable(TYPE_ENVELOPE, new List<String> {
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'ExpireAfterDays__c',
				Application.namespacePrefix + 'Expires__c',
				Application.namespacePrefix + 'ExpireWarnDays__c',
				Application.namespacePrefix + 'Remind__c',
				Application.namespacePrefix + 'RemindAfterDays__c',
				Application.namespacePrefix + 'RemindFrequencyDays__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'Sent__c',
				Application.namespacePrefix + 'SourceId__c'
			});

			List<Envelope> result = new List<Envelope>();
			if (Collection.isNotEmpty(envelopes)) {
				List<Envelope__c> es = new List<Envelope__c>();
				Map<String, Envelope> dses = new Map<String, Envelope>();
				for (Envelope e : envelopes) {
					if (e != null && UUID.isNotEmpty(e.docuSignId)) {
						es.add(convert(e));
						dses.put(e.docuSignId.toString(), e);
					}
				}
				insert es;

				for (Envelope__c e : es) {
					if (dses.containsKey(e.DocuSignId__c)) result.add(dses.get(e.DocuSignId__c).withId(e.Id));
				}
			}
			return result;
		}

		public Envelope updateEnvelope2(final Envelope envelope, final Boolean sendNow) {
			Permissions.verifyIsUpdateable(TYPE_ENVELOPE, new List<String> {
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'ExpireAfterDays__c',
				Application.namespacePrefix + 'Expires__c',
				Application.namespacePrefix + 'ExpireWarnDays__c',
				Application.namespacePrefix + 'Remind__c',
				Application.namespacePrefix + 'RemindAfterDays__c',
				Application.namespacePrefix + 'RemindFrequencyDays__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'Sent__c',
				Application.namespacePrefix + 'SourceId__c'
			});

			if (envelope == null) return envelope;

			Envelope__c e = convert(envelope);
			if (sendNow) {
				e.Sent__c = Datetime.now();
			}
			update e;

			return convert(e)
				.withCustomFields(envelope.customFields)
				.withDocuments(envelope.documents)
				.withRecipients(envelope.recipients);
		}

		public Boolean updateEnvelopeSent(
			final Id envelopeId,
			final UUID dsEnvelopeId,
			final Boolean sendNow) {

			Permissions.verifyIsUpdateable(TYPE_ENVELOPE, new List<String> {
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'Sent__c'
			});

			update new Envelope__c(
				Id = envelopeId,
				DocuSignId__c = UUID.toString(dsEnvelopeId),
				Sent__c = sendNow ? Datetime.now() : null);
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

	/**
	 * Saves a DocuSign envelope record.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.
	 *
	 * @param envelope The DocuSign envelope.
	 *
	 * @return The saved DocuSign envelope.
	 */
	public static Envelope saveEnvelope(final Envelope envelope) {
		// Custom fields are not stored in our custom object, so must load and merge them later.
		Envelope result = DB.insertEnvelope(envelope);

		// Add any non-custom-button documents and recipients
		if (Collection.isNotEmpty(result.documents)) {
			result = result.withDocuments(DocumentService.addEnvelopeDocuments(
				result.id,
				result.documents));
		}
		if (Collection.isNotEmpty(result.recipients)) {
			result = result.withRecipients(RecipientService.addEnvelopeRecipients(
				result.id,
				RecipientService.prepareRecipients(result.recipients)));
		}

		return result;
	}

	/**
	 * Saves a placeholder Envelope__c record
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.
	 *
	 * @return The saved placeholder envelope.
	 */
	public static Envelope__c saveEnvelope() {
		return DB.insertEnvelope();
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
	private static Envelope addSourceRecipients(
		final Envelope envelope,
		final Entity source,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (envelope == null || source == null) return envelope;
		return envelope.addRecipients(RecipientService.resolveSourceRecipients(source, defaultEmailSettings));
	}

	/**
	 * Creates a DocuSign envelope. This method does not send the envelope; to do so call
	 * <code>dfsle.EnvelopeService.sendEnvelope</code>.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param envelope The envelope to create.
	 * @param addFromSource Load source documents and recipients.
	 *
	 * @return The newly-created envelope.
	 * @see dfsle.EnvelopeService.sendEnvelope for details on how to send the created envelope.
	 */
	public static Envelope createEnvelope(
		final Envelope envelope,
		final Boolean addFromSource) {

		Permissions.verifyIsDocuSignUser();

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		Recipient.EmailSettings defaultEmailSettings =
			Localization.isEmailLocalizationEnabled() ? Localization.getEmailSettingsForCurrentLanguage() : null;
		Envelope result = envelope;
		if (addFromSource) { // Default settings if custom button is undefined?
			result = addSourceDocuments(result, result.source, false);
			result = addSourceRecipients(result, result.source, defaultEmailSettings);
		}

		return saveEnvelope(result);
	}

	/**
	 * Creates a DocuSign envelope. This method does not send the envelope; to do so call
	 * <code>dfsle.EnvelopeService.sendEnvelope</code>.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param envelope The envelope to create.
	 * @param envelopeConfiguration Deprecated - ignored.
	 * @param addFromSource Load source documents and recipients.
	 *
	 * @return The newly-created envelope.
	 * @see dfsle.EnvelopeService.sendEnvelope for details on how to send the created envelope.
	 */
	@Deprecated
	global static Envelope createEnvelope(
		final Envelope envelope,
		final EnvelopeConfiguration envelopeConfiguration,
		final Boolean addFromSource) {

		return createEnvelope(envelope, addFromSource);
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
	global static Envelope getEnvelope(final Id envelopeId) {
		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);

		// queryEnvelope verifies ownership
		Envelope envelope = DB.queryEnvelope(envelopeId);

		if (envelope == null) throw new DocuSignException(Label.EnvelopeNotFound);
		return envelope;
	}

	/**
	 * Updates an envelope, including documents and recipients. This is a more expensive call than
	 * <code>dfsle.EnvelopeService.updateEnvelopeNotifications</code> as it updates and recalculates child entries.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope to update.
	 *
	 * @return The updated envelope.
	 */
	global static Envelope updateEnvelope(final Envelope envelope) {
		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		ValidationResult vr = validate(envelope, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		// Determine which documents or recipients have changed
		Envelope original = getEnvelope(envelope.id);

		return DB.updateEnvelope2(envelope, false)
			.withRecipients(RecipientService.updateEnvelopeRecipients(envelope.id, original.recipients, envelope.recipients))
			.withDocuments(DocumentService.updateEnvelopeDocuments(envelope.id, original.documents, envelope.documents));
	}

	/**
	 * Sends an envelope to DocuSign. This will also create the envelope record in Salesforce if necessary.
	 * <p>
	 * This method should be isolated on its own transaction as it involves a callout followed by a DML operation.
	 * <p>
	 * If previously created, the caller must be the owner of the envelope. Otherwise the caller must be assigned the
	 * <code>DocuSign Sender</code> permission set.
	 *
	 * @param envelope The envelope to send.
	 * @param sendNow Whether to send immediately or save as a draft in DocuSign.
	 *
	 * @return The sent envelope.
	 */
	global static Envelope sendEnvelope(
		final Envelope envelope,
		final Boolean sendNow) {

		return sendEnvelope(envelope, sendNow, true, SENDER_TOKEN);
	}

	/**
	 * Sends an envelope to DocuSign. The envelope may have been previously created via
	 * <code>dfsle.EnvelopeService.createEnvelope</code> or <code>dfsle.EnvelopeService.copyEnvelope</code>, or this
	 * method will create the requisite Salesforce records.
	 * <p>
	 * If previously created, the caller must be the owner of the envelope. Otherwise the caller must be assigned the
	 * <code>DocuSign Sender</code> permission set.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param envelope The envelope to send.
	 * @param sendNow Whether to send immediately or save as a draft in DocuSign.
	 * @param updateNow Whether to update the envelope record immediately. This update may be deferred if the current
	 * transaction involves subsequent callouts to avoid errors. To update later, call
	 * <code>dfsle.EnvelopeService.markEnvelopeSent</code>.
	 * @param senderToken The application sending the envelope. This will be appended to the User-Agent header on the
	 * DocuSign create envelope API callout.
	 *
	 * @return The sent envelope.
	 * @see dfsle.EnvelopeService.markEnvelopeSent for deferred updates.
	 */
	public static Envelope sendEnvelope(
		final Envelope envelope,
		final Boolean sendNow,
		final Boolean updateNow,
		final String senderToken) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Boolean sfdcEnvelopeCreated = envelope != null && envelope.id != null;
		if (sfdcEnvelopeCreated) {
			Permissions.verifyIsOwner(envelope.id);
		} else {
			Permissions.verifyIsDocuSignSender();
		}

		ValidationResult vr = validate(envelope, sendNow);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		Envelope result = envelope.withRecipients(RecipientService.prepareRecipients(envelope.recipients));
		try {
			result = result.withDocuSignId(
				EnvelopeAPI.getInstance().createEnvelope(
					result,
					sendNow,
					senderToken));

			// Maybe create Connect configuration after 2.5 upgrade
			if (updateNow && AccountSettings__c.getOrgDefaults().CreateConnectConfiguration__c) {
				ConnectService.asyncCreateConfiguration();
			}
		} finally {
			if (updateNow) Credentials.save();
		}
		if (sendNow) result = result.withSent(Datetime.now());
		// Can update in some workflows, but not in others due to subsequent callouts (e.g. mobile)
		if (updateNow) {
			if (sfdcEnvelopeCreated) {
				result = DB.updateEnvelope2(result, sendNow);
			} else {
				result = DB.insertEnvelope(result);
				if (Collection.isNotEmpty(result.documents)) {
					result = result.withDocuments(DocumentService.addEnvelopeDocuments(result.id, result.documents));
				}
				if (Collection.isNotEmpty(result.recipients)) {
					result = result.withRecipients(RecipientService.addEnvelopeRecipients(result.id, result.recipients));
				}
			}
			if (sendNow) StatusService.createStatus(new List<Envelope.Status> { result.toEnvelopeStatus() });
		}

		return result;
	}

	/**
	 * Marks an envelope's record as sent. Used for deferred updates from
	 * <code>dfsle.EnvelopeService.sendEnvelope</code>. If the envelope was updated immediately after being sent, this
	 * method does not need to be called.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The envelope that was sent.
	 * @param sendNow Whether the envelope was immediately sent or saved as a draft in DocuSign.
	 *
	 * @return <code>true</code> if the update was successful, <code>false</code> otherwise.
	 * @see dfsle.EnvelopeService.sendEnvelope for more details.
	 */
	public static Boolean markEnvelopeSent(
		final Envelope envelope,
		final Boolean sendNow) {

		if (envelope == null) throw new DocuSignException(Label.UndefinedEnvelope);

		Permissions.verifyIsOwner(envelope.id);

		Boolean result = DB.updateEnvelopeSent(envelope.id, envelope.docuSignId, sendNow);
		if (sendNow) {
			StatusService.createStatus(new List<Envelope.Status> {
				envelope.withSent(Datetime.now()).toEnvelopeStatus()
			});
		}

		return result;
	}

	/**
	 * Immediately sends one or more DocuSign envelopes.
	 * <p>
	 * This method involves web service callouts to DocuSign, but no subsequent DML. It is intended for scenarios where
	 * multiple envelopes are sent in a single transaction or whenever else DML should be deferred. At the end of the
	 * transaction, <code>dfsle.EnvelopeService.saveSentEnvelopes</code> should be called. Otherwise the associated
	 * envelope and status records will not be created.
	 * <p>
	 * This call is limited to 99 envelopes at a time, and subject to hourly API and Salesforce Governor limits.
	 * <p>
	 * Every envelope must be valid or else a <code>ValidationException</code> will be thrown and no envelopes will be
	 * sent. If all envelopes pass validation, any API error for an envelope will be logged on the <code>error</code>
	 * property. Only successfully sent ones may be saved with <code>dfsle.EnvelopeService.saveSentEnvelopes</code>.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code>, <code>DocuSign User</code>, or
	 * <code>DocuSign Sender</code> permission set.
	 *
	 * @param envelopes The envelopes to send.
	 *
	 * @return The sent envelope.
	 * @see dfsle.EnvelopeService.saveSentEnvelopes to complete the transaction.
	 */
	global static List<Envelope> sendEnvelopes(final List<Envelope> envelopes) {
		Permissions.verifyIsDocuSignSender();

		if (Collection.isEmpty(envelopes)) throw new DocuSignException(Label.UndefinedArgument);
		if (envelopes.size() > MULTI_SEND_ENVELOPE_LIMIT) throw new DocuSignException(Label.MultiSendEnvelopeLimitExceeded);

		List<Envelope> result = new List<Envelope>();
		ValidationResult vr = new ValidationResult();
		for (Envelope e : envelopes) {
			ValidationResult vr2 = validate(e, true);
			if (vr.isValid && vr2.isValid) { // Prepare envelope for sending only if there are no validation errors.
				result.add(e.withRecipients(RecipientService.prepareRecipients(e.recipients)));
			} else { // Invalid envelope, skip preparation
				vr.add(vr2);
			}
		}
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelope, vr);

		EnvelopeAPI client = EnvelopeAPI.getInstance();
		for (Envelope e : result) {
			try {
				e = e.withDocuSignId(client.createEnvelope(e, true, SENDER_TOKEN))
					.withSent(Datetime.now());
			} catch (APIException ex) {
				LOG.exception(ex, 'Failed to send envelope');
				e = e.withError(ex.error);
			}
		}

		return result;
	}

	/**
	 * Completes a transaction initiated by <code>dfsle.EnvelopeService.sendEnvelopes</code>. This will create envelope
	 * and status records for each sent envelope.
	 * <p>
	 * Each envelope must have valid <code>docuSignId</code> and <code>sent<code> properties and an empty
	 * <code>error</code> property, otherwise an exception will be thrown and no envelopes will be saved. Any invalid
	 * envelopes should be filtered out prior to calling this method.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code>, <code>DocuSign User</code>, or
	 * <code>DocuSign Sender</code> permission set.
	 *
	 * @param envelopes The sent envelopes.
	 *
	 * @return The sent envelopes with updated record IDs.
	 * @see dfsle.EnvelopeService.sendEnvelopes to initiate the transaction.
	 */
	global static List<Envelope> saveSentEnvelopes(final List<Envelope> envelopes) {
		Permissions.verifyIsDocuSignSender();

		if (Collection.isEmpty(envelopes)) throw new DocuSignException(Label.UndefinedArgument);

		List<Envelope.Status> ess = new List<Envelope.Status>();
		for (Envelope e : envelopes) {
			if (e == null
				|| String.isNotBlank(e.id)
				|| UUID.isEmpty(e.docuSignId)
				|| e.sent == null
				|| (e.error != null && e.error != APIError.none)) {

				throw new DocuSignException(Label.InvalidSentEnvelopes);
			}

			ess.add(e.toEnvelopeStatus());
		}

		Map<Id, Envelope> result = new Map<Id, Envelope>();
		Map<Id, List<Document>> documents = new Map<Id, List<Document>>();
		Map<Id, List<Recipient>> recipients = new Map<Id, List<Recipient>>();
		for (Envelope e : DB.insertSentEnvelopes(envelopes)) {
			if (e == null || String.isBlank(e.id)) continue;

			result.put(e.id, e);
			if (Collection.isNotEmpty(e.documents)) documents.put(e.id, e.documents);
			if (Collection.isNotEmpty(e.recipients)) recipients.put(e.id, e.recipients);
		}

		documents = DocumentService.addEnvelopeDocuments(documents);
		for (Id eId : documents.keySet()) {
			if (eId != null && result.containsKey(eId)) {
				result.put(eId, result.get(eId).withDocuments(documents.get(eId)));
			}
		}

		recipients = RecipientService.addEnvelopeRecipients(recipients);
		for (Id eId : recipients.keySet()) {
			if (eId != null && result.containsKey(eId)) {
				result.put(eId, result.get(eId).withRecipients(recipients.get(eId)));
			}
		}

		StatusService.createStatus(ess);

		return result.values();
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
	global static Id deleteEnvelope(final Id envelopeId) {
		Permissions.verifyIsOwner(envelopeId);

		return DB.deleteEnvelope2(envelopeId);
	}

	/**
	 * Gets an empty envelope definition that can be subsequently completed, created, and sent. This envelope will
	 * be populated with appropriate defaults based on the current account settings and localizations.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Sender</code> permission set.
	 *
	 * @param source The originating Salesforce entity for the envelope.
	 *
	 * @return The empty envelope.
	 */
	global static Envelope getEmptyEnvelope(final Entity source) {
		Permissions.verifyIsDocuSignSender();

		Recipient.EmailSettings emailSettings = Localization.getEmailSettingsForCurrentLanguage();
		return new Envelope(
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			new Notifications(
				false,
				null,
				null,
				false,
				null,
				null),
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
	 *     <code>dfsle.EnvelopeService.deleteEnvelope</code> method.</li>
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
	global static Url getSenderViewUrl(final UUID docuSignId, final Url returnUrl) {
		Permissions.verifyIsOwner(docuSignId);

		try {
			return EnvelopeAPI.getInstance().getSenderViewUrl(docuSignId, returnUrl);
		} finally {
			Credentials.save();
		}
	}
}
