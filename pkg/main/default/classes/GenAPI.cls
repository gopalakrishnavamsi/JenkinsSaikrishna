public with sharing class GenAPI extends ScmAPI {

	private static GenAPI self = null;

	@TestVisible
	private GenAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(new Url(baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static GenAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			if (c.environment.scmMergeBaseUrl == null) throw new DocuSignException(Label.GenNotConfigured);
			self = new GenAPI(c.environment.scmMergeBaseUrl, 'v1', c.account.id);
		}
		return self;
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

		RestAPI.Response response = this.post(
			new List<Object> { 'sfdocumentxmlmergetasks' },
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

		RestAPI.Response response = this.get(
			new List<Object> { 'sfdocumentxmlmergetasks', jobId },
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

