public class GenV1 {

	public class Task {
		@AuraEnabled
		public UUID id { get; private set; }
		@AuraEnabled
		public Id fileId { get; private set; }
		@AuraEnabled
		public String status { get; private set; }
		@AuraEnabled
		public String message { get; private set; }
		@AuraEnabled
		public Gen.File file { get; private set; }
		@AuraEnabled
		public Boolean success { get; private set; }

		public Task(
			final UUID id,
			final Id fileId,
			final String status,
			final String message) {

			this.id = id;
			this.fileId = fileId;
			this.status = String.isBlank(status) ? Label.Unknown : status;
			this.message = message;
			this.success = status == 'Success' || status == Label.Success;
		}

		public Task withFile(final Gen.File file) {
			this.file = file;
			return this;
		}
	}
}
