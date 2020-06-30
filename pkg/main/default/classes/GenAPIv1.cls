public with sharing class GenAPIv1 extends ScmAPI {

	private static GenAPIv1 self = null;

	@TestVisible
	private GenAPIv1(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(new Url(baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static GenAPIv1 getInstance() {
		if (self == null) {
			Url baseUrl = AccountProducts.getInstance().getScmMergeBaseUrl();
			if (baseUrl == null) throw new DocuSignException(Label.GenNotConfigured);
			self = new GenAPIv1(
				baseUrl,
				'v1',
				Credentials.getInstance().account.id);
		}
		return self;
	}

	public GenV1.Task queueDocumentGeneration(
		final Id fileId,
		final Id sourceId,
		final String xmlPayload,
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

	public GenV1.Task queueDocumentGeneration(
		final Id fileId,
		final Id sourceId,
		final String xmlPayload,
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
		return new GenV1.Task(
			UUID.parse(((String)body.get('Href')).substringAfterLast('/')),
			fileId,
			Label.Queued,
			null);
	}

	public GenV1.Task getTaskStatus(final UUID taskId) {
		return this.getTaskStatus(taskId, RestAPI.defaultTimeout);
	}

	public GenV1.Task getTaskStatus(
		final UUID taskId,
		final Integer timeout) {

		RestAPI.Response response = this.get(
			new List<Object> { 'sfdocumentxmlmergetasks', taskId },
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve document generation job status: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		return new GenV1.Task(
			taskId,
			(Id)body.get('SfContentVersionId'),
			(String)body.get('Status'),
			(String)body.get('Message'));
	}
}

