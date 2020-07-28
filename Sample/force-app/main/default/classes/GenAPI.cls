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
			Url baseUrl = AccountProducts.getInstance().getScmMergeBaseUrl();
			if (baseUrl == null) throw new DocuSignException(Label.GenNotConfigured);
			self = new GenAPI(
				baseUrl,
				'v1',
				Credentials.getInstance().account.id);
		}
		return self;
	}

	@TestVisible
	private class APITask {
		public Id sfObjectId { get; private set; }
		public Id templateSfContentVersionId { get; private set; }
		public String outputFileName { get; private set; }
		public String outputFormat { get; private set; }

		public APITask(
			final Id linkedEntityId,
			final Gen.Task task) {

			this.sfObjectId = linkedEntityId;
			if (task != null) {
				this.outputFileName = task.outputFileName;
				if (task.file != null) {
					this.templateSfContentVersionId = task.file.id;
					this.outputFormat = task.file.generatedFormat;
				}
			}
		}
	}

	@TestVisible
	private class APIJob {
		public Id genTemplateId { get; private set; }
		public Id sfSourceId { get; private set; }
		public String sfSourceType { get; private set; }
		public String locale { get; private set; }
		public Id sfUserId { get; private set; }
		public List<APITask> mergeDocumentTasks { get; private set; }

		public APIJob(final Gen.Job job) {
			if (job != null) {
				this.genTemplateId = job.templateId;
				if (job.source != null) {
					this.sfSourceId = job.source.id;
					this.sfSourceType = job.source.typeName;
				}
				this.locale = job.locale;

				if (job.tasks != null) {
					this.mergeDocumentTasks = new List<APITask>();
					for (Gen.Task task : job.tasks) {
						if (task == null || task.file == null) continue;

						this.mergeDocumentTasks.add(new APITask(
							this.sfSourceId,
							task));
					}
				}
			}
			this.sfUserId = UserInfo.getUserId();
		}
	}

	@TestVisible
	private class APITaskStatus {
		public String Status;
		public String Href;
		public Id SfContentVersionId;
		public String Message;

		@TestVisible
		private String getStatusLabel() {
			if (String.isBlank(this.Status)) return Label.Unknown;

			switch on this.Status.toLowerCase() {
				when 'success' {
					return Label.Success;
				} when 'failure' {
					return Label.Failure;
				} when 'processing' {
					return Label.Processing;
				} when else {
					return this.Status;
				}
			}
		}

		public Gen.Task toTask() {
			return new Gen.Task(
				String.isBlank(this.Href) ? null : UUID.tryParse(this.Href.substringAfterLast('/')),
				this.SfContentVersionId,
				this.getStatusLabel(),
				this.Message);
		}
	}

	public Gen.Job enqueueJob(final Gen.Job job) {
		return this.enqueueJob(
			job,
			RestAPI.defaultTimeout);
	}

	public Gen.Job enqueueJob(
		final Gen.Job job,
		final Integer timeout) {

		if (job == null || job.tasks == null) throw new DocuSignException(Label.UndefinedArgument);
      System.debug('enqueueJob');

		RestAPI.Response response = this.post(
			new List<Object> { 'sfdocumentxmlmergeandquerytask' },
			JSON.serialize(new APIJob(job)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to queue document generation job: ' + response.error);
			throw new APIException(response.error);
		}

		List<APITaskStatus> statuses = (List<APITaskStatus>)JSON.deserialize(response.body, List<APITaskStatus>.class);
		Integer statusSize = statuses == null ? 0 : statuses.size();
		for (Integer i = 0; i < job.tasks.size(); i++) {
			if (i < statusSize) {
				APITaskStatus status = statuses[i];
				job.tasks[i]
					.withId(String.isBlank(status.Href) ? null : UUID.tryParse(status.Href.substringAfterLast('/')))
					.withStatus(status.Status);
			} else {
				job.tasks[i]
					.withStatus(Label.Unknown);
			}
		}
		return job;
	}

	public Gen.Task getTaskStatus(final UUID taskId) {
		return this.getTaskStatus(taskId, RestAPI.defaultTimeout);
	}

	public Gen.Task getTaskStatus(
		final UUID taskId,
		final Integer timeout) {

		if (UUID.isEmpty(taskId)) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.get(
			new List<Object> { 'sfdocumentxmlmergetasks', taskId },
			timeout);
		if (response.hasError) {
			this.log.error('Failed to retrieve document generation task status: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APITaskStatus)JSON.deserialize(response.body, APITaskStatus.class)).toTask();
	}
}