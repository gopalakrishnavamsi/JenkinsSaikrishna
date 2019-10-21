/**
 * This class is the entry point for DocuSign eSignature envelope and recipient status management. It provides
 * methods to retrieve and take action upon DocuSign eSignature statuses.
 */
global with sharing class StatusService {

	@TestVisible
	private static final StatusService.Database DB = new StatusService.Database();
	private static final Long STATUS_POLL_INTERVAL_MS = 900000; // 15 min * 60 sec * 1000 ms
	private static final Set<String> COMPLETED_STATUSES = new Set<String> {
		Envelope.STATUS_VOIDED, Envelope.STATUS_DECLINED, Envelope.STATUS_COMPLETED,
		Recipient.STATUS_SIGNED, Recipient.STATUS_DECLINED, Recipient.STATUS_CANCELED, Recipient.STATUS_COMPLETED
	};
	private static final SObjectType TYPE_ENVELOPE_STATUS = EnvelopeStatus__c.getSObjectType();
	private static final SObjectType TYPE_RECIPIENT_STATUS = RecipientStatus__c.getSObjectType();
	private static final SObjectType TYPE_ENVELOPE = Envelope__c.getSObjectType();
	private static final SObjectType TYPE_DOCUMENT = Document__c.getSObjectType();
	private static final SObjectType TYPE_RECIPIENT = Recipient__c.getSObjectType();

	private class Database {

		@TestVisible
		private List<Envelope.Status> convert(final List<EnvelopeStatus__c> ess) {
			if (ess == null) return null;

			List<Envelope.Status> result = new List<Envelope.Status>();
			for (EnvelopeStatus__c es : ess) {
				result.add(convert(es));
			}
			return result;
		}

		@TestVisible
		private Envelope.Status convert(final EnvelopeStatus__c es) {
			if (es == null) return null;

			return new Envelope.Status(
				es.Id,
				String.isBlank(es.SourceId__c) ? null : new Entity(es.SourceId__c),
				UUID.parse(es.DocuSignId__c),
				es.Status__c,
				es.SenderName__c,
				es.SenderEmail__c,
				convert(es.Recipients__r),
				es.Sent__c,
				es.Expires__c,
				es.Completed__c,
				es.EmailSubject__c,
				es.Reason__c,
				es.LastStatusUpdate__c);
		}

		@TestVisible
		private List<Recipient.Status> convert(final List<RecipientStatus__c> rss) {
			if (rss == null) return null;

			List<Recipient.Status> result = new List<Recipient.Status>();
			for (RecipientStatus__c rs : rss) {
				result.add(convert(rs));
			}
			return result;
		}

		@TestVisible
		private Recipient.Status convert(final RecipientStatus__c rs) {
			if (rs == null) return null;

			return new Recipient.Status(
				rs.Id,
				String.isBlank(rs.SourceId__c) ? null : new Entity(rs.SourceId__c),
				rs.Type__c,
				Integer.valueOf(rs.Sequence__c),
				rs.Status__c,
				rs.Name,
				rs.Email__c,
				Integer.valueOf(rs.RoutingOrder__c),
				rs.Sent__c,
				rs.Completed__c,
				rs.Reason__c,
				rs.LastStatusUpdate__c);
		}

		public Set<UUID> querySourceEnvelopes(final Set<Id> sourceIds, final Integer maximumRecords) {
			Permissions.verifyIsQueryable(TYPE_ENVELOPE, new List<String> { 'DocuSignId__c' });

			Integer max = maximumRecords == null || maximumRecords <= 0 ? 5 : maximumRecords;
			Set<UUID> result = new Set<UUID>();
			for (Envelope__c e : [
				SELECT DocuSignId__c
				FROM Envelope__c
				WHERE SourceId__c IN :sourceIds
				AND DocuSignId__c != NULL
				AND Sent__c != NULL
				ORDER BY Sent__c DESC
				LIMIT :max
			]) {
				result.add(UUID.parse(e.DocuSignId__c));
			}
			return result;
		}

		public List<Envelope.Status> queryStatus(final Set<UUID> docuSignIds) {
			Permissions.verifyIsQueryable(TYPE_ENVELOPE_STATUS, new List<String> {
				'Id', 'SourceId__c', 'DocuSignId__c', 'Status__c', 'SenderName__c', 'SenderEmail__c',
				'EmailSubject__c', 'Sent__c', 'Expires__c', 'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});
			Permissions.verifyIsQueryable(TYPE_RECIPIENT_STATUS, new List<String> {
				'Id', 'EnvelopeStatus__c', 'SourceId__c', 'Type__c', 'Sequence__c', 'Status__c',
				'RoutingOrder__c', 'Name', 'Email__c', 'Sent__c', 'Completed__c', 'Reason__c',
				'LastStatusUpdate__c'
			});

			if (docuSignIds == null) return new List<Envelope.Status>();

			List<String> dsEnvelopeIds = new List<String>();
			for (UUID dseId : docuSignIds) {
				dsEnvelopeIds.add(String.valueOf(dseId));
			}

			return convert([
				SELECT
					Id, SourceId__c, DocuSignId__c, Status__c, SenderName__c, SenderEmail__c, EmailSubject__c, Sent__c,
					Expires__c, Completed__c, Reason__c, LastStatusUpdate__c, (
					SELECT
						Id, SourceId__c, Type__c, Sequence__c, Status__c, RoutingOrder__c,
						Name, Email__c, Sent__c, Completed__c, Reason__c, LastStatusUpdate__c
					FROM Recipients__r
					ORDER BY Sequence__c
				)
				FROM EnvelopeStatus__c
				WHERE DocuSignId__c IN :dsEnvelopeIds
				ORDER BY Sent__c ASC
			]);
		}

		public List<Envelope.Status> insertStatus(final List<Envelope.Status> envelopes) {
			Permissions.verifyIsCreateable(TYPE_ENVELOPE_STATUS, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'Status__c', 'SenderName__c', 'SenderEmail__c', 'EmailSubject__c',
				'Sent__c', 'Expires__c', 'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});
			Permissions.verifyIsCreateable(TYPE_RECIPIENT_STATUS, new List<String> {
				'EnvelopeStatus__c', 'SourceId__c', 'Sequence__c', 'Type__c', 'Status__c', 'RoutingOrder__c', 'Name',
				'Email__c', 'Sent__c', 'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});

			if (envelopes == null) return new List<Envelope.Status>();

			// Create parent envelope status records.
			Map<UUID, EnvelopeStatus__c> esMap = new Map<UUID, EnvelopeStatus__c>();
			List<EnvelopeStatus__c> ess = new List<EnvelopeStatus__c>();
			for (Envelope.Status e : envelopes) {
				if (e.docuSignId == null) throw new DocuSignException(Label.UndefinedDocuSignEnvelopeId);
				EnvelopeStatus__c es = new EnvelopeStatus__c(
					SourceId__c = e.source == null ? null : e.source.id,
					DocuSignId__c = String.valueOf(e.docuSignId),
					Status__c = e.status,
					SenderName__c = e.senderName,
					SenderEmail__c = e.senderEmail,
					EmailSubject__c = e.emailSubject,
					Sent__c = e.sent,
					Expires__c = e.expires,
					Completed__c = e.completed,
					Reason__c = e.reason,
					LastStatusUpdate__c = e.lastStatusUpdate);
				esMap.put(e.docuSignId, es);
				ess.add(es);
			}
			insert ess;

			// Create child recipient status records.
			List<RecipientStatus__c> rss = new List<RecipientStatus__c>();
			for (Envelope.Status e : envelopes) {
				EnvelopeStatus__c es = esMap.get(e.docuSignId);
				if (e.recipients != null) {
					for (Recipient.Status r : e.recipients) {
						rss.add(new RecipientStatus__c(
							SourceId__c = r.source == null ? null : r.source.id,
							EnvelopeStatus__c = es.Id,
							Type__c = r.type,
							Sequence__c = r.sequence,
							Status__c = r.status,
							RoutingOrder__c = r.routingOrder,
							Name = r.name,
							Email__c = r.email,
							Sent__c = r.sent,
							Completed__c = r.completed,
							Reason__c = r.reason,
							LastStatusUpdate__c = r.lastStatusUpdate));
					}
				}
			}
			upsert rss;

			return queryStatus(esMap.keySet());
		}

		public List<Envelope.Status> upsertStatus(final List<Envelope.Status> envelopes) {
			Permissions.verifyIsCreateable(TYPE_ENVELOPE_STATUS, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'Status__c', 'SenderName__c', 'SenderEmail__c', 'EmailSubject__c',
				'Sent__c', 'Expires__c', 'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});
			Permissions.verifyIsUpdateable(TYPE_ENVELOPE_STATUS, new List<String> {
				'DocuSignId__c', 'SourceId__c', 'Status__c', 'SenderName__c', 'SenderEmail__c', 'EmailSubject__c',
				'Sent__c', 'Expires__c', 'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});
			Permissions.verifyIsDeletable(TYPE_RECIPIENT_STATUS);
			Permissions.verifyIsCreateable(TYPE_RECIPIENT_STATUS, new List<String> {
				'SourceId__c', 'Sequence__c', 'Type__c', 'Status__c', 'RoutingOrder__c', 'Name', 'Email__c', 'Sent__c',
				'Completed__c', 'Reason__c', 'LastStatusUpdate__c'
			});

			if (envelopes == null) return new List<Envelope.Status>();

			// Create parent envelope status records.
			Map<UUID, EnvelopeStatus__c> esMap = new Map<UUID, EnvelopeStatus__c>();
			List<EnvelopeStatus__c> ess = new List<EnvelopeStatus__c>();
			Set<Id> esIds = new Set<Id>();
			for (Envelope.Status e : envelopes) {
				if (e.docuSignId == null) throw new DocuSignException(Label.UndefinedDocuSignEnvelopeId);
				if (e.id != null) esIds.add(e.id);
				EnvelopeStatus__c es = new EnvelopeStatus__c(
					Id = e.id,
					SourceId__c = e.source == null ? null : e.source.id,
					DocuSignId__c = String.valueOf(e.docuSignId),
					Status__c = e.status,
					SenderName__c = e.senderName,
					SenderEmail__c = e.senderEmail,
					EmailSubject__c = e.emailSubject,
					Sent__c = e.sent,
					Expires__c = e.expires,
					Completed__c = e.completed,
					Reason__c = e.reason,
					LastStatusUpdate__c = Datetime.now());
				esMap.put(e.docuSignId, es);
				ess.add(es);
			}
			upsert ess;

			// Delete any child recipients
			delete [SELECT Id FROM RecipientStatus__c WHERE EnvelopeStatus__c IN :esIds];

			// Create child recipient status records.
			List<RecipientStatus__c> rss = new List<RecipientStatus__c>();
			for (Envelope.Status e : envelopes) {
				EnvelopeStatus__c es = esMap.get(e.docuSignId);
				if (e.recipients != null) {
					for (Recipient.Status r : e.recipients) {
						rss.add(new RecipientStatus__c(
							EnvelopeStatus__c = es.Id,
							SourceId__c = r.source == null ? null : r.source.id,
							Type__c = r.type,
							Sequence__c = r.sequence,
							Status__c = r.status,
							RoutingOrder__c = r.routingOrder,
							Name = r.name,
							Email__c = r.email,
							Sent__c = r.sent,
							Completed__c = r.completed,
							Reason__c = r.reason,
							LastStatusUpdate__c = Datetime.now()));
					}
				}
			}
			insert rss;

			return queryStatus(esMap.keySet());
		}

		public Boolean deleteStatus(final Set<UUID> docuSignIds, final Boolean deleteEnvelopes) {
			Permissions.verifyIsDeletable(TYPE_ENVELOPE_STATUS);
			Permissions.verifyIsDeletable(TYPE_RECIPIENT_STATUS);
			if (deleteEnvelopes) {
				Permissions.verifyIsDeletable(TYPE_ENVELOPE);
				Permissions.verifyIsDeletable(TYPE_DOCUMENT);
				Permissions.verifyIsDeletable(TYPE_RECIPIENT);
			}

			Set<String> dsIds = new Set<String>();
			for (UUID u : docuSignIds) {
				if (u != null) dsIds.add(String.valueOf(u));
			}

			Boolean result = false;
			if (Collection.isNotEmpty(dsIds)) {
				// Cascading delete for RecipientStatus__c detail records.
				delete [SELECT Id FROM EnvelopeStatus__c WHERE DocuSignId__c IN :dsIds];
				if (deleteEnvelopes) {
					// Cascading delete on child Document__c and Recipient__c records
					delete [SELECT Id FROM Envelope__c WHERE DocuSignId__c IN :dsIds];
				}
				result = true;
			}
			return result;
		}

		public Boolean updateStatus(final Set<UUID> docuSignIds, final String status, final String reason) {
			Permissions.verifyIsUpdateable(TYPE_ENVELOPE_STATUS, new List<String> {
				'Status__c', 'Reason__c', 'Completed__c', 'LastStatusUpdate__c'
			});
			Permissions.verifyIsUpdateable(TYPE_RECIPIENT_STATUS, new List<String> {
				'Status__c', 'Completed__c', 'LastStatusUpdate__c'
			});

			Set<String> dsIds = new Set<String>();
			for (UUID u : docuSignIds) {
				if (u != null) dsIds.add(String.valueOf(u));
			}

			Set<Id> esIds = new Set<Id>();
			List<EnvelopeStatus__c> ess = new List<EnvelopeStatus__c>();
			for (EnvelopeStatus__c es : [
				SELECT
					Id, Status__c, Reason__c, Completed__c, LastStatusUpdate__c
				FROM EnvelopeStatus__c
				WHERE DocuSignId__c IN :dsIds
			]) {
				esIds.add(es.Id);
				ess.add(es);
				es.Status__c = status;
				es.Reason__c = reason;
				if (COMPLETED_STATUSES.contains(status)) es.Completed__c = Datetime.now();
				es.LastStatusUpdate__c = Datetime.now();
			}

			List<RecipientStatus__c> rss = new List<RecipientStatus__c>();
			for (RecipientStatus__c rs : [
				SELECT
					Id, Status__c, Completed__c, LastStatusUpdate__c
				FROM RecipientStatus__c
				WHERE EnvelopeStatus__c IN :esIds
			]) {
				if (!COMPLETED_STATUSES.contains(rs.Status__c)) {
					rs.Status__c = Recipient.STATUS_CANCELED;
					rs.Completed__c = Datetime.now();
					rs.LastStatusUpdate__c = Datetime.now();
					rss.add(rs);
				}
			}

			update rss;
			update ess;

			return Collection.isNotEmpty(esIds);
		}
	}

	@TestVisible
	private static ValidationResult validate(final List<Envelope.Status> envelopes) {
		ValidationResult result = new ValidationResult();

		if (Collection.isEmpty(envelopes)) {
			result.add(Label.AtLeastOneEnvelopeIsRequired);
		} else {
			for (Envelope.Status e : envelopes) {
				if (e.docuSignId == null || e.sent == null) {
					result.add(Label.EnvelopesMustBeSent);
					break;
				}
			}
		}

		return result;
	}

	@TestVisible
	private static Envelope.Status prepareUpsert(final Envelope.Status envelope) {
		if (envelope == null) return null;

		// Ensure the recipient statuses are accurate when an envelope is in a final state
		if (envelope.isFinal && envelope.recipients != null) {
			for (Recipient.Status r : envelope.recipients) {
				if (!r.isFinal) {
					r = r.cancel();
				}
			}
		}

		return envelope;
	}

	private static List<Envelope.Status> prepareUpsert(final List<Envelope.Status> envelopes) {
		if (envelopes == null) return null;

		List<Envelope.Status> result = new List<Envelope.Status>();
		for (Envelope.Status e : envelopes) {
			result.add(prepareUpsert(e));
		}
		return result;
	}

	/**
	 * Creates envelope status records from a list of sent envelopes. This will fail if any of the envelopes already
	 * has a status record associated with it.
	 * <p>
	 * The caller must be the owner of the envelopes.
	 *
	 * @param envelopes The DocuSign envelopes from which to create statuses. These must have been previously sent with
	 * a non-null <code>docuSignId</code>.
	 *
	 * @return The new envelope statuses.
	 */
	global static List<Envelope.Status> createStatus(final List<Envelope.Status> envelopes) {
		verifyIsOwner(envelopes);

		ValidationResult vr = validate(envelopes);
		if (!vr.isValid) throw new ValidationException(Label.CannotCreateStatus, vr);

		return DB.insertStatus(envelopes);
	}

	/**
	 * Retrieves envelope statuses. This will perform a callout to DocuSign for each status that has not been refreshed
	 * within the last 15 minutes.
	 * <p>
	 * Any orphaned DocuSign envelope records will also be deleted. This will occur if the envelope exists as a
	 * Salesforce record, but not in DocuSign.
	 *
	 * @param docuSignIds The DocuSign envelope IDs.
	 *
	 * @return A list of envelope statuses.
	 */
	@TestVisible
	private static List<Envelope.Status> getStatus(final Set<UUID> docuSignIds) {
		List<Envelope.Status> result = new List<Envelope.Status>();
		List<Envelope.Status> toUpdate = new List<Envelope.Status>();
		Set<UUID> toDelete = new Set<UUID>();
		EnvelopeAPI api = EnvelopeAPI.getInstance();
		Long now = Datetime.now().getTime();
		Set<UUID> idsFound = new Set<UUID>();
		for (Envelope.Status es : DB.queryStatus(docuSignIds)) {
			idsFound.add(es.docuSignId);
			Long elapsedMs = es.lastStatusUpdate == null ? STATUS_POLL_INTERVAL_MS : now - es.lastStatusUpdate.getTime();
			if (!es.isFinal && elapsedMs >= STATUS_POLL_INTERVAL_MS) {
				try {
					toUpdate.add(api.getEnvelopeStatus(es.docuSignId, true).mergeWith(es));
				} catch (APIException ex) {
					if (ex.error == APIError.notFound) {
						// Envelope no longer exists in DocuSign, so delete.
						toDelete.add(es.docuSignId);
					} else if (ex.error == APIError.unauthorized) {
						// Skip updates of envelopes the user cannot access in DocuSign
						result.add(es);
					} else {
						throw ex;
					}
				}
			} else {
				result.add(es);
			}
		}

		for (UUID id : Collection.difference(docuSignIds, idsFound)) {
			try {
				toUpdate.add(api.getEnvelopeStatus(id, true));
			} catch (APIException ex) {
				if (ex.error != APIError.notFound) throw ex;
				// Envelope no longer exists in DocuSign, so delete.
				toDelete.add(id);
			}
		}

		if (Collection.isNotEmpty(toUpdate)) {
			result.addAll(DB.upsertStatus(prepareUpsert(toUpdate)));
		}

		if (Collection.isNotEmpty(toDelete)) {
			DB.deleteStatus(toDelete, true);
		}

		// Commit changes to access token
		Credentials.save();

		// Sort by ascending sent date/time
		result.sort();
		return result;
	}

	/**
	 * Retrieves envelope statuses associated with Salesforce source records.
	 *
	 * @param sourceIds The IDs of the initiating Salesforce objects.
	 * @param maximumRecords The maximum number of records to retrieve.
	 *
	 * @return A list of envelope statuses.
	 */
	global static List<Envelope.Status> getStatus(final Set<Id> sourceIds, final Integer maximumRecords) {
		return getStatus(DB.querySourceEnvelopes(sourceIds, maximumRecords));
	}

	/**
	 * Deletes envelope status and related envelope records.
	 * <p>
	 * The caller must be the owner of the envelopes.
	 *
	 * @param docuSignIds The DocuSign envelope IDs.
	 * @param deleteEnvelopes Whether to also delete associated envelope records.
	 *
	 * @return <code>true</code> if records were deleted, <code>false</code> otherwise.
	 */
	public static Boolean deleteStatus(final Set<UUID> docuSignIds, final Boolean deleteEnvelopes) {
		Permissions.verifyIsOwner(docuSignIds);

		return DB.deleteStatus(docuSignIds, deleteEnvelopes);
	}

	@TestVisible
	private static Boolean isValidStatus(final List<Envelope.Status> envelopes) {
		Boolean result = Collection.isNotEmpty(envelopes);
		if (result) {
			for (Envelope.Status es : envelopes) {
				result &= isValidStatus(es);
				if (!result) break;
			}
		}
		return result;
	}

	private static Boolean isValidStatus(final Envelope.Status es) {
		return es != null
			&& es.docuSignId != null
			&& (es.status == Envelope.STATUS_SENT
			|| es.status == Envelope.STATUS_DELIVERED);
	}

	private static void verifyIsOwner(final List<Envelope.Status> envelopes) {
		if (envelopes != null) {
			Set<UUID> dseIds = new Set<UUID>();
			for (Envelope.Status es : envelopes) {
				if (es.docuSignId != null) dseIds.add(es.docuSignId);
			}
			Permissions.verifyIsOwner(dseIds);
		}
	}

	/**
	 * Resends a DocuSign envelope to pending recipients in the routing order.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 *
	 * @return <code>true</code> if the envelope was resent, <code>false</code> otherwise.
	 */
	global static Boolean resendEnvelope(final UUID docuSignId) {
		Permissions.verifyIsOwner(docuSignId);

		List<Envelope.Status> ess = DB.queryStatus(new Set<UUID> { docuSignId });
		if (!isValidStatus(ess)) throw new DocuSignException(Label.CannotResendEnvelope);

		try {
			return EnvelopeAPI.getInstance().resendEnvelope(docuSignId);
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Resends a DocuSign envelope to the specified recipients. This method may be partially successful, so check the
	 * returned results for errors.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 * @param recipients The recipients for which to resend the envelope.
	 *
	 * @return A list of recipient resend results.
	 */
	global static List<Recipient.ResendResult> resendRecipients(final UUID docuSignId, final List<Recipient> recipients) {
		Permissions.verifyIsOwner(docuSignId);

		List<Envelope.Status> ess = DB.queryStatus(new Set<UUID> { docuSignId });
		if (!isValidStatus(ess)) throw new DocuSignException(Label.CannotResendEnvelope);

		try {
			return EnvelopeAPI.getInstance().resendRecipients(docuSignId, recipients);
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Voids a DocuSign envelope. The envelope must be in the 'sent' or 'delivered' state and a non-blank reason must be
	 * provided.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 * @param reason The reason to void the envelope.
	 *
	 * @return <code>true</code> if the void operation was successful, <code>false</code> otherwise.
	 */
	global static Boolean voidEnvelope(final UUID docuSignId, final String reason) {
		Permissions.verifyIsOwner(docuSignId);

		List<Envelope.Status> ess = DB.queryStatus(new Set<UUID> { docuSignId });
		if (Collection.isEmpty(ess)) {
			throw new DocuSignException(String.format(Label.StatusNotFound_1, new List<String> {
				String.valueOf(docuSignId)
			}));
		}
		if (!isValidStatus(ess)) throw new DocuSignException(Label.CannotVoidEnvelope);

		try {
			Boolean result = EnvelopeAPI.getInstance().voidEnvelope(docuSignId, reason);
			if (result) {
				result &= DB.updateStatus(new Set<UUID> { docuSignId }, Envelope.STATUS_VOIDED, reason);
			}
			return result;
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Retrieves an envelope correction URL from DocuSign. The URL may be used once.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 * @param returnUrl Where to redirect once correction is complete.
	 *
	 * @return The envelope correction URL.
	 */
	global static Url getCorrectUrl(final UUID docuSignId, final Url returnUrl) {
		Permissions.verifyIsOwner(docuSignId);

		List<Envelope.Status> ess = DB.queryStatus(new Set<UUID> { docuSignId });
		if (Collection.isEmpty(ess)) {
			throw new DocuSignException(String.format(Label.StatusNotFound_1, new List<String> {
				String.valueOf(docuSignId)
			}));
		}
		if (!isValidStatus(ess)) throw new DocuSignException(Label.CannotCorrectEnvelope);

		try {
			return EnvelopeAPI.getInstance().getCorrectViewUrl(docuSignId, returnUrl);
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Retrieves an envelope view URL from DocuSign. The URL may be used once.
	 *
	 * @param docuSignId The DocuSign envelope ID.
	 * @param returnUrl Where to redirect once viewing is complete.
	 *
	 * @return The envelope view URL.
	 */
	global static Url getViewUrl(final UUID docuSignId, final Url returnUrl) {
		// Don't check envelope permissions here. Let DS platform handle this.
		if (docuSignId == null) throw new DocuSignException(Label.InvalidStatus);

		try {
			return EnvelopeAPI.getInstance().getConsoleViewUrl(docuSignId, returnUrl);
		} finally {
			Credentials.save();
		}
	}
}
