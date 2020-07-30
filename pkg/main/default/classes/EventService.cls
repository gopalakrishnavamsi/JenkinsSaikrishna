@RestResource(UrlMapping = '/v1/status/*')
global with sharing class EventService {

	@TestVisible
	private static final String KEY_TRANSACTION_ID = 'transactionId';
	@TestVisible
	private static final EventService.Database DB = new EventService.Database();
	private static final Map<String, Integer> ENVELOPE_STATUS_ORDINALS = new Map<String, Integer> {
		Envelope.STATUS_CREATED => 0,
		Envelope.STATUS_SENT => 1,
		Envelope.STATUS_DELIVERED => 2,
		// Last 3 statuses are final and mutually-exclusive
		Envelope.STATUS_DECLINED => 3,
		Envelope.STATUS_VOIDED => 3,
		Envelope.STATUS_COMPLETED => 3
	};

	@TestVisible
	private class Database {

		public Map<UUID, Envelope.Options> queryEnvelopeOptions(final Set<UUID> envelopeIds) {
			Permissions.verifyIsQueryable(Envelope__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'Options__c'
			});

			if (Collection.isEmpty(envelopeIds)) return new Map<UUID, Envelope.Options>();

			Set<String> ids = new Set<String>();
			for (UUID id : envelopeIds) {
				ids.add(String.valueOf(id));
			}

			Map<UUID, Envelope.Options> result = new Map<UUID, Envelope.Options>();
			for (Envelope__c e : [
				SELECT DocuSignId__c, Options__c
				FROM Envelope__c
				WHERE DocuSignId__c IN :ids
			]) {
				if (e == null || String.isBlank(e.DocuSignId__c) || String.isBlank(e.Options__c)) continue;

				Envelope.Options o = EnvelopeParser.deserializeOptions(e.Options__c);
				if (o != null) result.put(UUID.parse(e.DocuSignId__c), EnvelopeParser.deserializeOptions(e.Options__c));
			}
			return result;
		}
	}

	@TestVisible
	private class EventRecipient {
		public String recipientId;
		public String type;
		public String email;
		public String username;
		public Integer routingOrder;
		public String sent;
		public String delivered;
		public String signed;
		public String declined;
		public String declineReason;
		public String status;
		public List<String> customFields;

		private Id sourceId;
		private Boolean checkedSourceId = false;

		public Id getSourceId() {
			if (this.checkedSourceId != true) {
				if (this.customFields != null) {
					this.sourceId = CustomField.getRecipientSourceId(this.customFields);
				}
				this.checkedSourceId = true;
			}
			return this.sourceId;
		}

		public Recipient.Status toStatus(final Integer sequence) {
			Id sourceId = this.getSourceId();
			return new Recipient.Status(
				null,
				String.isBlank(sourceId) ? null : new Entity(sourceId),
				UUID.parse(this.recipientId),
				this.type,
				sequence,
				this.status,
				this.username,
				this.email,
				this.routingOrder,
				StringUtils.parseDatetime(this.sent), // TODO: Use delivered or track separately?
				String.isNotBlank(this.declined) ? StringUtils.parseDatetime(this.declined)
					: StringUtils.parseDatetime(this.signed),
				this.declineReason,
				Datetime.now());
		}
	}

	@TestVisible
	private class EventCustomField {
		public String name;
		public String value;
	}

	@TestVisible
	private class Event {
		public List<EventRecipient> recipientStatuses;
		public String envelopeId;
		public String subject;
		public String username;
		public String email;
		public String status;
		public String created;
		public String sent;
		public String delivered;
		public String declined;
		public String signed;
		public String completed;
		public String voided;
		public String voidReason;
		public List<EventCustomField> customFields;

		private Id sourceId;
		private Boolean checkedSourceId = false;

		public Id getSourceId() {
			if (this.checkedSourceId != true) {
				if (customFields != null) {
					Map<String, String> cfs = new Map<String, String>();
					for (EventCustomField cf : this.customFields) {
						if (cf == null) continue;

						cfs.put(cf.name, cf.value);
					}
					this.sourceId = CustomField.getEnvelopeSourceId(cfs);
				}
				this.checkedSourceId = true;
			}
			return this.sourceId;
		}

		public List<EventRecipient> getRecipients() {
			return this.recipientStatuses != null ? this.recipientStatuses : new List<EventRecipient>();
		}

		@TestVisible
		private Datetime getCompletedDatetime() {
			Datetime result = null;
			if (this.status == Envelope.STATUS_VOIDED) {
				result = StringUtils.parseDatetime(this.voided);
			} else if (this.status == Envelope.STATUS_DECLINED) {
				result = StringUtils.parseDatetime(this.declined);
			} else if (this.status == Envelope.STATUS_COMPLETED) {
				result = StringUtils.parseDatetime(this.completed);
			}
			return result;
		}

		private List<Recipient.Status> getRecipientStatus() {
			List<Recipient.Status> result = new List<Recipient.Status>();
			if (this.recipientStatuses != null) {
				Integer sequence = 0;
				for (EventRecipient r : this.recipientStatuses) {
					if (r != null) result.add(r.toStatus(++sequence));
				}
			}
			return result;
		}

		public Envelope.Status toStatus() {
			Id sourceId = this.getSourceId();
			return new Envelope.Status(
				null,
				String.isBlank(sourceId) ? null : new Entity(sourceId),
				UUID.parse(this.envelopeId),
				this.status,
				this.username,
				this.email,
				getRecipientStatus(),
				StringUtils.parseDatetime(this.sent),
				null, // TODO: Need date/time expires
				getCompletedDatetime(),
				this.subject,
				this.voidReason,
				Datetime.now());
		}
	}

	@TestVisible
	private class EventWrapper {
		public EventService.Event envelopeStatus;
	}

	@TestVisible
	private abstract class Updates {
		transient public UUID id { get; private set; }
		transient public Id sourceId { get; private set; }
		transient public Map<String, Object> updates { get; private set; }

		public Boolean success { get; protected set; }

		protected Updates(
			final UUID id,
			final Id sourceId,
			final Map<String, Object> updates) {

			this.id = id;
			this.sourceId = sourceId;
			this.updates = updates == null ? new Map<String, Object>() : updates;
			this.success = false;
		}

		public Updates addUpdates(final Map<String, Object> updates) {
			if (Collection.isNotEmpty(updates)) {
				for (String path : updates.keySet()) {
					if (String.isNotBlank(path)) this.updates.put(path.toLowerCase(), updates.get(path));
				}
			}
			return this;
		}

		public Updates withSuccess(final Boolean success) {
			this.success = success;
			return this;
		}
	}

	@TestVisible
	private class RecipientUpdates extends Updates {

		public String recipientId { get; private set; }

		public RecipientUpdates(
			final UUID id,
			final Id sourceId,
			final Map<String, Object> updates) {

			super(id, sourceId, updates);

			this.recipientId = String.valueOf(id);
		}
	}

	@TestVisible
	private class EnvelopeUpdates extends Updates implements Comparable {

		public String envelopeId { get; private set; }
		public String status { get; private set; }
		public Map<String, List<RecipientUpdates>> recipients { get; private set; }

		public EnvelopeUpdates(
			final UUID id,
			final Id sourceId,
			final String status,
			final Map<String, Object> updates,
			final Map<String, List<RecipientUpdates>> recipients) {

			super(id, sourceId, updates);

			this.envelopeId = String.valueOf(id);
			this.status = status;
			this.recipients = recipients == null ? new Map<String, List<RecipientUpdates>>() : recipients;
		}

		public Integer compareTo(final Object compareTo) {
			if (compareTo == null || !(compareTo instanceof EnvelopeUpdates)) return -1;

			EnvelopeUpdates that = (EnvelopeUpdates)compareTo;
			Integer thisStatusOrdinal = String.isBlank(this.status) ? 10 : ENVELOPE_STATUS_ORDINALS.get(this.status);
			Integer thatStatusOrdinal = String.isBlank(that.status) ? 10 : ENVELOPE_STATUS_ORDINALS.get(that.status);
			if (thisStatusOrdinal == thatStatusOrdinal) return 0;
			if (thisStatusOrdinal > thatStatusOrdinal) return 1;
			return -1;
		}
	}

	private static List<Envelope.Status> eventsToStatus(final List<EventService.Event> events) {
		List<Envelope.Status> result = new List<Envelope.Status>();
		if (events != null) {
			for (EventService.Event e : events) {
				if (e != null) result.add(e.toStatus());
			}
		}
		return result;
	}

	@TestVisible
	private static Map<String, Object> getWriteBackMergeFields(
		final UUID transactionId,
		final UUID envelopeId,
		final Id sourceId) {

		Map<String, Object> result = new Map<String, Object>();

		if (UUID.isEmpty(envelopeId) || String.isBlank(sourceId)) return result;

		try {
			List<Tab> mergeFields = EnvelopeAPI.getInstance().getEnvelopeMergeFields(envelopeId, true);
			if (mergeFields != null) {
				for (Tab t : mergeFields) {
					if (t == null || String.isBlank(t.path)) continue;

					result.put(t.path.toLowerCase(), t.value);
				}
			}
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.GetMergeFieldsError,
				new LoggerService.LogContext(
					transactionId,
					envelopeId,
					sourceId,
					String.valueOf(EventService.class),
					'getWriteBackMergeFields'));
		}

		return result;
	}

	@TestVisible
	private static Map<UUID, List<EnvelopeUpdates>> buildMergeFieldUpdates(
		final UUID transactionId,
		final List<EventService.Event> events) {

		Map<UUID, List<EnvelopeUpdates>> result = new Map<UUID, List<EnvelopeUpdates>>();

		if (Collection.isEmpty(events)) return result;

		for (EventService.Event e : events) { // Only write-back merge fields when envelope is complete.
			if (e == null || String.isBlank(e.envelopeId) || String.isBlank(e.status)) continue;

			UUID envelopeId = UUID.parse(e.envelopeId);
			Id sourceId = e.getSourceId();
			Map<String, List<RecipientUpdates>> recipients = new Map<String, List<RecipientUpdates>>();
			for (EventRecipient r : e.getRecipients()) {
				if (r == null || String.isBlank(r.status)) continue;

				RecipientUpdates rus = new RecipientUpdates(
					UUID.parse(r.recipientId),
					r.getSourceId(),
					null);
				String rStatus = r.status.toLowerCase();
				if (recipients.containsKey(rStatus)) {
					recipients.get(rStatus).add(rus);
				} else {
					recipients.put(rStatus, new List<RecipientUpdates> { rus });
				}
			}

			EnvelopeUpdates eus = new EnvelopeUpdates(
				envelopeId,
				sourceId,
				e.status,
				e.status == Envelope.STATUS_COMPLETED
					? getWriteBackMergeFields(transactionId, envelopeId, sourceId)
					: new Map<String, Object>(),
				recipients);
			if (String.isBlank(sourceId)) {
				LoggerService.getInstance().warn(
					Label.DataUpdateMissingSourceId,
					new LoggerService.LogContext(
						transactionId,
						envelopeId,
						sourceId,
						String.valueOf(EventService.class),
						'buildMergeFieldUpdates'));
			}
			if (result.containsKey(envelopeId)) {
				result.get(envelopeId).add(eus);
			} else {
				result.put(envelopeId, new List<EnvelopeUpdates> { eus });
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, List<EnvelopeUpdates>> mergeEnvelopeOptions(
		final Map<UUID, List<EnvelopeUpdates>> envelopeUpdates) {

		if (Collection.isEmpty(envelopeUpdates)) return new Map<UUID, List<EnvelopeUpdates>>();

		Map<UUID, Envelope.Options> eos = DB.queryEnvelopeOptions(envelopeUpdates.keySet());
		if (eos != null) {
			for (UUID envelopeId : eos.keySet()) {
				Envelope.Options o = eos.get(envelopeId);
				if (o == null || (o.envelopeEventUpdates == null && o.recipientEventUpdates == null)) continue;

				List<EnvelopeUpdates> eus = envelopeUpdates.get(envelopeId);
				if (eus == null) continue;

				for (EnvelopeUpdates eu : eus) {
					if (eu == null || String.isBlank(eu.status)) continue;

					if (o.envelopeEventUpdates != null && String.isNotBlank(eu.sourceId)) {
						eu.addUpdates(o.envelopeEventUpdates.get(eu.status));
					}

					if (eu.recipients == null || o.recipientEventUpdates == null) continue;

					for (String rs : o.recipientEventUpdates.keySet()) {
						if (String.isBlank(rs) || !eu.recipients.containsKey(rs)) continue;

						List<RecipientUpdates> rus = eu.recipients.get(rs);
						if (rus == null) continue;

						for (RecipientUpdates ru : rus) {
							if (ru == null || String.isBlank(ru.sourceId)) continue;

							ru.addUpdates(o.recipientEventUpdates.get(rs));
						}
					}
				}
			}
		}
		return envelopeUpdates;
	}

	@TestVisible
	private static Boolean updateData(
		final UUID transactionId,
		final UUID envelopeId,
		final Id sourceId,
		final Map<String, Object> dataUpdates) {

		if (UUID.isEmpty(envelopeId) || String.isBlank(sourceId)) return false;
		if (Collection.isEmpty(dataUpdates)) return true;

		Boolean result = false;
		Savepoint sp = System.Database.setSavepoint();
		try {
			MergeService.mergeData(sourceId, dataUpdates);
			result = true;
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.DataUpdateFailed,
				new LoggerService.LogContext(
					transactionId,
					envelopeId,
					sourceId,
					String.valueOf(EventService.class),
					'updateData'));
			System.Database.rollback(sp);
		}
		return result;
	}

	@TestVisible
	private static List<EnvelopeUpdates> writeBackData(
		final UUID transactionId,
		final List<EventService.Event> events) {

		List<EnvelopeUpdates> result = new List<EnvelopeUpdates>();

		if (Collection.isEmpty(events)) return result;

		Map<UUID, List<EnvelopeUpdates>> updates = buildMergeFieldUpdates(transactionId, events);
		if (updates != null) updates = mergeEnvelopeOptions(updates);

		if (updates != null) {
			for (UUID envelopeId : updates.keySet()) {
				List<EnvelopeUpdates> eus = updates.get(envelopeId);
				if (Collection.isEmpty(eus)) continue;

				eus.sort(); // Sort to ensure final status updates are processed last
				for (EnvelopeUpdates eu : eus) {
					if (eu == null) continue;

					if (eu.recipients != null) {
						for (String status : eu.recipients.keySet()) {
							List<RecipientUpdates> rus = eu.recipients.get(status);
							if (rus == null) continue;

							for (RecipientUpdates ru : rus) {
								if (ru == null || Collection.isEmpty(ru.updates)) continue;

								ru.withSuccess(updateData(
									transactionId,
									envelopeId,
									ru.sourceId,
									ru.updates));
							}
						}
					}

					// Update envelope source
					result.add((EnvelopeUpdates)eu.withSuccess(updateData(
						transactionId,
						envelopeId,
						eu.sourceId,
						eu.updates)));
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Boolean updateStatus(
		final UUID transactionId,
		final List<EventService.Event> events) {

		if (Collection.isEmpty(events)) return true;

		Boolean result = true;
		List<Envelope.Status> ess = eventsToStatus(events);
		Savepoint sp = System.Database.setSavepoint();
		try {
			StatusService.updateStatus(ess);
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.StatusUpdateFailed,
				new LoggerService.LogContext(
					transactionId,
					null,
					null,
					String.valueOf(EventService.class),
					'updateStatus'));
			System.Database.rollback(sp);
			result = false;
		}

		return result;
	}

	@TestVisible
	private class Error {

		public Integer code { get; private set; }
		public String type { get; private set; }
		public String message { get; private set; }

		public Error(
			final Integer code,
			final String type,
			final String message) {

			this.code = code;
			this.type = type;
			this.message = message;
		}
	}

	@TestVisible
	private class Response {

		public String transactionId { get; private set; }
		public Integer status { get; private set; }
		public Long millisecondDuration { get; private set; }
		public List<EnvelopeUpdates> results { get; private set; }
		public Error error { get; private set; }

		public Response(
			final UUID transactionId,
			final Integer status,
			final List<EnvelopeUpdates> results) {

			this.transactionId = String.valueOf(transactionId);
			this.status = status;
			this.results = results;
			this.error = null;
		}

		public Response(
			final UUID transactionId,
			final Integer status,
			final Error error) {

			this.transactionId = String.valueOf(transactionId);
			this.status = status;
			this.results = null;
			this.error = error;
		}

		public Response withDuration(final Long millisecondDuration) {
			this.millisecondDuration = millisecondDuration;
			return this;
		}
	}

	@TestVisible
	private class RequestException extends Exception {
		public Integer code { get; private set; }

		public RequestException(final Integer code, final String message) {
			this(message);

			this.code = code;
		}

		public Error toError() {
			return new Error(
				this.code,
				String.valueOf(RequestException.class),
				this.getMessage());
		}
	}

	// Must not blindly leak implementation details for JSON parsing or authorization errors.
	@TestVisible
	private static Response getErrorResponse(
		final UUID transactionId,
		final Exception ex) {

		Response result = null;
		if (ex == null) {
			result = new Response(
				transactionId,
				500,
				new Error(
					APIErrorCode.FAILURE,
					null,
					Label.UnknownError));
		} else if (ex instanceof RequestException) {
			result = new Response(
				transactionId,
				400,
				((RequestException)ex).toError());
		} else if (ex instanceof UnauthorizedException) {
			result = new Response(
				transactionId,
				401,
				new Error(
					APIErrorCode.UNAUTHORIZED,
					ex.getTypeName(),
					Label.UnauthorizedOperation));
		} else if (ex instanceof JSONException) {
			result = new Response(
				transactionId,
				400,
				new Error(
					APIErrorCode.INVALID_JSON,
					ex.getTypeName(),
					Label.InvalidJson));
		} else {
			result = new Response(
				transactionId,
				400,
				new Error(
					APIErrorCode.BAD_REQUEST,
					ex.getTypeName(),
					ex.getMessage()));
		}
		return result;
	}

	private static List<EnvelopeUpdates> doUpdates(
		final UUID transactionId,
		final List<EventService.Event> events) {

		if (Collection.isEmpty(events)) return new List<EnvelopeUpdates>();

		List<EnvelopeUpdates> result = writeBackData(transactionId, events);
		Boolean statusResult = updateStatus(transactionId, events);

		for (EnvelopeUpdates eu : result) {
			if (eu == null) continue;

			eu.withSuccess(statusResult && eu.success);
			if (eu.recipients == null) continue;

			for (List<RecipientUpdates> rus : eu.recipients.values()) {
				if (rus == null) continue;

				for (RecipientUpdates ru : rus) {
					if (ru == null) continue;

					ru.withSuccess(ru.success && statusResult);
				}
			}
		}
		return result;
	}

	private static List<EventService.Event> unwrapEvents(final List<EventWrapper> events) {
		List<EventService.Event> result = new List<EventService.Event>();

		if (events != null) {
			for (EventWrapper e : events) {
				if (e == null || e.envelopeStatus == null) continue;

				result.add(e.envelopeStatus);
			}
		}

		return result;
	}

	// TODO: Use HTTP headers for meta-properties? Transaction ID? Duration? Anything else?
	@HttpPut
	global static void publishEvents() {
		Long start = System.currentTimeMillis();
		UUID transactionId = UUID.randomUUID();
		RestResponse resp = RestContext.response;
		Response result = null;
		try {
			QueryString params = new QueryString(RestContext.request.params);
			transactionId = params.getUUID(KEY_TRANSACTION_ID, transactionId);

			Permissions.verifyIsDocuSignAdministrator();

			if (RestContext.request == null || RestContext.request.requestBody == null) {
				throw new RequestException(APIErrorCode.UNDEFINED_REQUEST_BODY, Label.UndefinedRequestBody);
			}

			List<EventService.Event> events = unwrapEvents((List<EventWrapper>)JSON.deserialize(
				RestContext.request.requestBody.toString(),
				List<EventWrapper>.class));

			result = new Response(
				transactionId,
				200,
				doUpdates(transactionId, events));
		} catch (Exception ex) {
			LoggerService.getInstance().exception(
				ex,
				Label.EventProcessingFailed,
				new LoggerService.LogContext(
					transactionId,
					null,
					null,
					String.valueOf(EventService.class),
					'publishEvents'));
			result = getErrorResponse(transactionId, ex);
		} finally {
			// Commit the log records to the DB
			LoggerService.getInstance().flush();
			resp.statusCode = result.status;
			resp.headers.put('Content-Type', 'application/json');
			resp.responseBody = Blob.valueOf(JSON.serialize(
				result.withDuration(System.currentTimeMillis() - start)));
		}
	}
}
