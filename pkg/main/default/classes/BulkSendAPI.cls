public with sharing class BulkSendAPI extends ESignatureAPI {

	private static BulkSendAPI self = null;

	@TestVisible
	private BulkSendAPI(final Credentials apiCredentials) {
		super(apiCredentials, 'v2.1');
	}

	public static BulkSendAPI getInstance() {
		if (self == null) {
			self = new BulkSendAPI(Credentials.getInstance());
		}
		return self;
	}

	// Serialization objects for bulk sending lists
	@TestVisible
	private class APIBulkList {
		public String listId;
		public String name;
		public List<APIEnvelope> bulkCopies;

		public APIBulkList(final BulkList bs) {
			if (bs != null) {
				this.listId = String.valueOf(bs.docuSignId);
				this.name = bs.name;
				if (bs.copies != null) {
					this.bulkCopies = new List<APIEnvelope>();
					for (Envelope e : bs.copies) {
						this.bulkCopies.add(new APIEnvelope(e));
					}
				}
			}
		}
	}

	@TestVisible
	private class APIEnvelope {
		public String emailSubject;
		public String emailBlurb;
		public List<APICustomField> customFields;
		public List<APIRecipient> recipients;

		public APIEnvelope(final Envelope e) {
			if (e != null) {
				this.emailSubject = e.emailSubject;
				this.emailBlurb = e.emailMessage;
				if (e.customFields != null) {
					this.customFields = new List<APICustomField>();
					for (CustomField cf : e.customFields) {
						this.customFields.add(new APICustomField(cf));
					}
				}
				if (e.recipients != null) {
					this.recipients = new List<APIRecipient>();
					for (Recipient r : e.recipients) {
						this.recipients.add(new APIRecipient(r));
					}
				}
			}
		}
	}

	@TestVisible
	private class APICustomField {
		public String name;
		public String value;

		public APICustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.value = cf.value;
			}
		}
	}

	@TestVisible
	private class APIRecipient {
		public String recipientId;
		public String email;
		public String name;
		public String accessCode;
		public String idCheckConfigurationName;
		public APISmsAuthentication smsAuthentication;
		public String note;
		public List<String> customFields;

		public APIRecipient(final Recipient r) {
			if (r != null) {
				this.recipientId = String.valueOf(r.sequence);
				this.email = r.email;
				this.name = r.name;
				if (r.authentication != null) {
					this.accessCode = r.authentication.accessCode;
					if (Collection.isNotEmpty(r.authentication.smsPhoneNumbers)) {
						this.idCheckConfigurationName = 'SMS Auth $';
						this.smsAuthentication = new APISmsAuthentication(r.authentication.smsPhoneNumbers);
					}
				}
				if (r.source != null && String.isNotBlank(r.source.id) && r.source.type != null) {
					this.customFields = new List<String> {
						String.format('##SF{0}:{1}', new List<String> { String.valueOf(r.source.type), r.source.id })
					};
				}
			}
		}
	}

	@TestVisible
	private class APISmsAuthentication {
		public List<String> senderProvidedNumbers;

		public APISmsAuthentication(final List<String> smsPhoneNumbers) {
			this.senderProvidedNumbers = smsPhoneNumbers;
		}
	}

	public BulkList createList(final BulkList bulkList) {
		return this.createList(bulkList, RestAPI.defaultTimeout);
	}

	public BulkList createList(final BulkList bulkList, final Integer timeout) {
		if (bulkList == null) return null;

		RestAPI.Response response = super.post(
			'bulk_send_lists',
			JSON.serialize(new APIBulkList(bulkList)),
			timeout);
		if (response.hasError) {
			throw new APIException(response.error);
		}
		return bulkList.withDocuSignId(
			UUID.tryParse(((APIBulkList)JSON.deserialize(response.body, APIBulkList.class)).listId));
	}

	public BulkList updateList(final BulkList bulkList) {
		return this.updateList(bulkList, RestAPI.defaultTimeout);
	}

	public BulkList updateList(final BulkList bulkList, final Integer timeout) {
		if (bulkList == null) return null;

		RestAPI.Response response = super.put(
			new List<Object> { 'bulk_send_lists', bulkList.docuSignId },
			JSON.serialize(new APIBulkList(bulkList)),
			timeout);
		if (response.hasError) {
			throw new APIException(response.error);
		}

		return bulkList.withDocuSignId(
			UUID.tryParse(((APIBulkList)JSON.deserialize(response.body, APIBulkList.class)).listId));
	}

	public Boolean deleteList(final UUID bulkListId) {
		return this.deleteList(bulkListId, RestAPI.defaultTimeout);
	}

	public Boolean deleteList(final UUID bulkListId, final Integer timeout) {
		RestAPI.Response response = this.del(
			new List<Object> {
				'bulk_send_lists', bulkListId
			},
			timeout);
		if (response.hasError && response.error.code != APIErrorCode.NOT_FOUND) {
			throw new APIException(response.error);
		}
		return response.error.code != APIErrorCode.NOT_FOUND;
	}

	// Serialization objects for bulk envelope sending
	@TestVisible
	private class APIBulkSendRequest {
		private final String envelopeOrTemplateId;

		public APIBulkSendRequest(final UUID envelopeOrTemplateId) {
			this.envelopeOrTemplateId = String.valueOf(envelopeOrTemplateId);
		}
	}

	@TestVisible
	private class APIBulkSendResponse {
		public String batchId;
		public List<String> validationErrors;
		public List<String> validationErrorDetails;

		public BulkList.Result toExternalForm() {
			UUID batchId = UUID.tryParse(this.batchId);
			return new BulkList.Result(
				null,
				UUID.isEmpty(batchId) ? null : batchId,
				getAPIErrors());
		}

		private List<APIError> getAPIErrors() {
			if (Collection.isEmpty(this.validationErrors)) return null;

			List<APIError> result = new List<APIError>();
			Integer eds = Collection.size(this.validationErrorDetails);
			for (Integer i = 0; i < this.validationErrors.size(); i++) {
				String errorCode = this.validationErrors[i];
				result.add(new ESignatureAPI.Error(
					APIErrorCode.BAD_REQUEST,
					errorCode,
					i < eds ? this.validationErrorDetails[i] : errorCode));
			}

			return result;
		}
	}

	public BulkList.Result sendEnvelope(final UUID bulkListId, final UUID envelopeOrTemplateId) {
		return this.sendEnvelope(bulkListId, envelopeOrTemplateId, RestAPI.defaultTimeout);
	}

	public BulkList.Result sendEnvelope(final UUID bulkListId, final UUID envelopeOrTemplateId, final Integer timeout) {
		RestAPI.Response response = this.post(
			new List<Object> {
				'bulk_send_lists', bulkListId, 'send'
			},
			JSON.serialize(new APIBulkSendRequest(envelopeOrTemplateId)),
			timeout);
		if (response.hasError) {
			throw new APIException(response.error);
		}

		return ((APIBulkSendResponse)JSON.deserialize(response.body, APIBulkSendResponse.class)).toExternalForm();
	}

	// Serialization objects for bulk job status
	@TestVisible
	private class APIBatchStatusDetail {
		public String envelopeId;
		public String bulkStatus;

		public BulkList.StatusDetail toExternalForm() {
			return new BulkList.StatusDetail(
				UUID.tryParse(this.envelopeId),
				this.bulkStatus);
		}
	}

	@TestVisible
	private class APIBatchStatus {
		public String batchSize;
		public String batchId;
		public String failed;
		public String queued;
		public String sent;
		public String submittedDate;
		public List<APIBatchStatusDetail> bulkEnvelopes;

		public BulkList.Status toExternalForm() {
			List<BulkList.StatusDetail> details = new List<BulkList.StatusDetail>();
			if (this.bulkEnvelopes != null) {
				for (APIBatchStatusDetail bsd : this.bulkEnvelopes) {
					if (bsd != null) details.add(bsd.toExternalForm());
				}
			}
			return new BulkList.Status(
				null,
				UUID.tryParse(this.batchId),
				null,
				Integer.valueOf(this.batchSize),
				Integer.valueOf(this.queued),
				Integer.valueOf(this.sent),
				Integer.valueOf(this.failed),
				details,
				StringUtils.parseDatetime(this.submittedDate),
				Datetime.now());
		}
	}

	public BulkList.Status getStatus(final UUID batchId) {
		return this.getStatus(batchId, RestAPI.defaultTimeout);
	}

	public BulkList.Status getStatus(final UUID batchId, final Integer timeout) {
		RestAPI.Response response = super.get(
			new List<Object> {
				'bulk_envelopes', batchId
			},
			// TODO: Get individual envelope status
			QueryString.empty, //new QueryString('include', 'all'),
			timeout);
		if (response.hasError) {
			throw new APIException(response.error);
		}

		return ((APIBatchStatus)JSON.deserialize(response.body, APIBatchStatus.class)).toExternalForm();
	}
}
