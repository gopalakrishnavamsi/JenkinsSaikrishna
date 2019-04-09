public with sharing class GenAPI extends DocuSignAPI {
	private static GenAPI self = null;

	@TestVisible
	private GenAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super (new Url (baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static GenAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			if (c.environment.scmApiBaseUrl != null && c.account.id != null) {
				self = new GenAPI(c.environment.scmApiBaseUrl, 'v1', c.account.id);
			} else {
				throw UnauthorizedException.accountNotConfigured();
			}
		}
		return self;
	}

	public class Error extends APIError {
		public UUID referenceId { get; private set; }

		public Error(
			final Integer code,
			final UUID referenceId,
			final String description) {

			super(code, description);

			this.referenceId = referenceId;
		}

		override public String toString() {
			return String.format(Label.ApiError_3, new List<String> {
				String.valueOf(this.code),
				this.description,
				String.valueOf(this.referenceId)
			});
		}
	}

	@TestVisible
	override protected virtual APIError getError(final HttpResponse response) {
		APIError e = APIError.none;
		Integer statusCode = response.getStatusCode();
		if (statusCode >= 400) {
			String body = response.getBody();
			try {
				Map<String, Object> error = (Map<String, Object>)((Map<String, Object>)JSON.deserializeUntyped(body))
					.get('Error');
				e = new GenAPI.Error(
					error.containsKey('ErrorCode') ? (Integer)error.get('ErrorCode') : statusCode,
					UUID.tryParse((String)error.get('ReferenceId')),
					error.containsKey('UserMessage') ? (String)error.get('UserMessage') : response.getStatus());
				this.log.warn('Gen API error: ' + e);
			} catch (Exception ex) {
				this.log.exception(ex, 'Failed to parse Gen API error. Response body:\n' + body);
				e = new APIError(statusCode, response.getStatus());
			}
		}
		return e;
	}

	public Gen.Job queueDocumentGeneration(
		final Id fileId,
		final Id sourceId,
		final String xmlPayload, // FIXME: Generate XML in service class. The callout payload must be opaque to clients.
		final String fileFormat,
		final String fileName) {

		return this.queueDocumentGeneration(
			fileId,
			sourceId,
			xmlPayload,
			fileFormat,
			fileName,
			RestAPI.defaultTimeout);
	}

	public Gen.Job queueDocumentGeneration(
		final Id fileId,
		final Id sourceId,
		final String xmlPayload, // FIXME: Generate XML in service class. The callout payload must be opaque to clients.
		final String fileFormat,
		final String fileName,
		final Integer timeout) {

		RestAPI.Response response = post(
			getBaseUrl(),
			new List<Object> { 'sfdocumentxmlmergetasks' },
			QueryString.empty,
			getDefaultHeaders(),
			JSON.serialize(new Map<String, Object> {
				'TemplateSfContentVersionId' => fileId,
				'DataXml' => xmlPayload,
				'SfObjectId' => sourceId,
				'OutputFormat' => fileFormat,
				'OutputFileName' => fileName,
				'SfUserId' => UserInfo.getUserId()
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to generate document: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Gen.Job(
			UUID.parse(((String)body.get('Href')).substringAfterLast('/')),
			fileId,
			Label.Queued,
			null);
	}

	public Gen.Job getJobStatus(final UUID jobId) {
		return this.getJobStatus(jobId, RestAPI.defaultTimeout);
	}

	public Gen.Job getJobStatus(
		final UUID jobId,
		final Integer timeout) {

		RestAPI.Response response = get(
			getBaseUrl(),
			new List<Object> { 'sfdocumentxmlmergetasks', jobId },
			QueryString.empty,
			getDefaultHeaders(),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve document generation job status: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new Gen.Job(
			jobId,
			(Id)body.get('SfContentVersionId'),
			(String)body.get('Status'),
			(String)body.get('Message'));
	}
}

