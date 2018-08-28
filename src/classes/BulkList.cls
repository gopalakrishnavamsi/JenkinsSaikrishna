/**
 * DocuSign envelope bulk send list.
 * <p>
 * Exactly one bulk signer recipient per envelope is supported.
 */
global class BulkList {
	/**
	 * Constant for queued status.
	 */
	global static final String STATUS_QUEUED = 'queued';
	/**
	 * Constant for processing status.
	 */
	global static final String STATUS_PROCESSING = 'processing';
	/**
	 * Constant for sent status.
	 */
	global static final String STATUS_SENT = 'sent';
	/**
	 * Constant for failed status.
	 */
	global static final String STATUS_FAILED = 'failed';

	/**
	 * The bulk list identifier.
	 */
	@AuraEnabled
	global Id id { get; private set; }
	/**
	 * The DocuSign bulk send list identifier.
	 */
	@AuraEnabled
	global UUID docuSignId { get; private set; }
	/**
	 * The name of the bulk send list.
	 */
	@AuraEnabled
	global String name { get; private set; }
	/**
	 * Copies of the DocuSign envelope to be sent.
	 */
	@AuraEnabled
	global List<Envelope> copies { get; private set; }
	/**
	 * The Salesforce source object from which the list was generated.
	 */
	@AuraEnabled
	global Entity source { get; private set; }

	/**
	 * Constructs a DocuSign bulk send list.
	 *
	 * @param id The bulk list identifier.
	 * @param docuSignId The DocuSign bulk send list identifier.
	 * @param name The name of the bulk send list.
	 * @param copies Copies of the DocuSign envelope to be sent.
	 * @param source The Salesforce object from which the list was generated.
	 */
	global BulkList(
		final Id id,
		final UUID docuSignId,
		final String name,
		final List<Envelope> copies,
		final Entity source) {

		this.id = id;
		this.docuSignId = docuSignId;
		this.name = name;
		this.copies = copies;
		this.source = source;
	}

	/**
	 * Sets the bulk send list DocuSign ID.
	 *
	 * @param docuSignId The bulk send list DocuSign ID.
	 *
	 * @return The bulk send list with updated DocuSign ID.
	 */
	public BulkList withDocuSignId(final UUID docuSignId) {
		this.docuSignId = docuSignId;
		return this;
	}

	/**
	 * The result of testing or sending a bulk list.
	 */
	global class Result {
		/**
		 * The ID of the bulk status record.
		 */
		@AuraEnabled
		global Id bulkStatusId { get; private set; }
		/**
		 * The DocuSign batch job ID.
		 */
		public UUID batchId { get; private set; }
		/**
		 * A list of validation or sending errors.
		 */
		@AuraEnabled
		global List<APIError> errors { get; private set; }
		/**
		 * Read-only property indicating whether the batch job submission was successful.
		 */
		@AuraEnabled
		global Boolean success {
			get {
				return !UUID.isEmpty(this.batchId) && Collection.isEmpty(this.errors);
			}
		}

		/**
		 * Constructs a new bulk send result.
		 *
		 * @param bulkStatusId The ID of the bulk status record.
		 * @param batchId The DocuSign batch job ID.
		 * @param errors A list of validation or sending errors.
		 */
		public Result(
			final Id bulkStatusId,
			final UUID batchId,
			final List<APIError> errors) {

			this.bulkStatusId = bulkStatusId;
			this.batchId = batchId;
			this.errors = errors;
		}

		/**
		 * Sets the <code>bulkStatusId</code> property.
		 *
		 * @param bulkStatusId The ID of the bulk status record.
		 *
		 * @return The bulk send result with updated <code>bulkStatusId</code>.
		 */
		public Result withBulkStatusId(final Id bulkStatusId) {
			this.bulkStatusId = bulkStatusId;
			return this;
		}
	}

	/**
	 * The status of a bulk send batch job.
	 */
	global class Status {
		/**
		 * The ID of the status.
		 */
		global Id id { get; private set; }
		/**
		 * The DocuSign batch job ID.
		 */
		@AuraEnabled
		global UUID docuSignId { get; private set; }
		/**
		 * The Salesforce source object for the batch.
		 */
		@AuraEnabled
		global Entity source { get; private set; }
		/**
		 * The size of the batch.
		 */
		@AuraEnabled
		global Integer batchSize { get; private set; }
		/**
		 * The number of envelopes remaining to be sent.
		 */
		@AuraEnabled
		global Integer queuedEnvelopes { get; private set; }
		/**
		 * The number of envelopes sent successfully.
		 */
		@AuraEnabled
		global Integer sentEnvelopes { get; private set; }
		/**
		 * The number of envelopes that failed to send.
		 */
		@AuraEnabled
		global Integer failedEnvelopes { get; private set; }
		/**
		 * Bulk envelope status details.
		 */
		@AuraEnabled
		public List<StatusDetail> details { get; private set; }
		/**
		 * Date and time when the job was submitted.
		 */
		@AuraEnabled
		global Datetime submitted { get; private set; }
		/**
		 * Date and time when the status was last updated.
		 */
		@AuraEnabled
		global Datetime lastStatusUpdate { get; private set; }
		/**
		* Whether or not the status is in a final state.
		*/
		@AuraEnabled
		global Boolean isFinal {
			get {
				return this.queuedEnvelopes == 0
					&& (this.sentEnvelopes + this.failedEnvelopes) == this.batchSize;
			}
		}

		/**
		 * Constructs a new bulk send batch job status.
		 *
		 * @param id The ID of the status.
		 * @param docuSignId The DocuSign batch job ID.
		 * @param source The Salesforce source object for the batch.
		 * @param batchSize The size of the batch.
		 * @param queuedEnvelopes The number of envelopes remaining to be sent.
		 * @param sentEnvelopes The number of envelopes sent successfully.
		 * @param failedEnvelopes The number of envelopes that failed to send.
		 * @param details Bulk envelope status details.
		 * @param submitted Date and time when the job was submitted.
		 * @param lastStatusUpdate Date and time when the status was last updated.
		 */
		public Status(
			final Id id,
			final UUID docuSignId,
			final Entity source,
			final Integer batchSize,
			final Integer queuedEnvelopes,
			final Integer sentEnvelopes,
			final Integer failedEnvelopes,
			final List<StatusDetail> details,
			final Datetime submitted,
			final Datetime lastStatusUpdate) {

			this.id = id;
			this.docuSignId = docuSignId;
			this.source = source;
			this.batchSize = batchSize;
			this.queuedEnvelopes = queuedEnvelopes;
			this.sentEnvelopes = sentEnvelopes;
			this.failedEnvelopes = failedEnvelopes;
			this.details = details;
			this.submitted = submitted;
			this.lastStatusUpdate = lastStatusUpdate;
		}

		/**
		 * Sets the <code>id</code> property.
		 *
		 * @param id The ID of the bulk status record.
		 *
		 * @return The bulk send result with updated <code>id</code>.
		 */
		public Status withId(final Id id) {
			this.id = id;
			return this;
		}

		/**
		 * Sets the <code>source</code> property.
		 *
		 * @param source The Salesforce source object.
		 *
		 * @return The bulk send result with updated <code>source</code>.
		 */
		public Status withSource(final Entity source) {
			this.source = source;
			return this;
		}
	}

	/**
	 * DocuSign envelope batch status detail.
	 */
	public class StatusDetail {
		/**
		 * The DocuSign envelope ID.
		 */
		@AuraEnabled
		public UUID envelopeId { get; private set; }
		/**
		 * The batch status of the envelope: <code>queued</code>, <code>processing</code>,
		 * <code>sent</code>, or <code>failed</code>.
		 */
		@AuraEnabled
		public String status { get; private set; }

		/**
		 * Constructs a DocuSign envelope batch status detail.
		 *
		 * @param envelopeId The DocuSign envelope ID.
		 * @param status The batch status of the envelope: <code>queued</code>, <code>processing</code>,
		 * <code>sent</code>, or <code>failed</code>.
		 */
		public StatusDetail(
			final UUID envelopeId,
			final String status) {

			this.envelopeId = envelopeId;
			this.status = status;
		}
	}
}
