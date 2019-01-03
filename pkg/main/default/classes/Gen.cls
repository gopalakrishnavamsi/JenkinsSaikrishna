public class Gen {

	public class File {
		@AuraEnabled
		public Id id { get; private set; }
		@AuraEnabled
		public String title { get; private set; }
		@AuraEnabled
		public String extension { get; private set; }
		@AuraEnabled
		public Integer size { get; private set; }
		@AuraEnabled
		public String generatedFormat { get; private set; }
		@AuraEnabled
		public String generatedName { get; private set; }
		@AuraEnabled
		public String generatedSuffix { get; private set; }

		public File(
			final Id id,
			final String title,
			final String extension,
			final Integer size,
			final String generatedFormat,
			final String generatedName,
			final String generatedSuffix) {

			this.id = id;
			this.title = title;
			this.extension = extension;
			this.size = size;
			this.generatedFormat = generatedFormat;
			this.generatedName = generatedName;
			this.generatedSuffix = generatedSuffix;
		}
	}

	public class Job {
		@AuraEnabled
		public UUID id { get; private set; }
		@AuraEnabled
		public Id fileId { get; private set; }
		@AuraEnabled
		public String status { get; private set; }
		@AuraEnabled
		public String message { get; private set; }
		@AuraEnabled
		public File file { get; private set; }
		@AuraEnabled
		public Boolean success { get; private set; }

		public Job(
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

		public Job withFile(final File file) {
			this.file = file;
			return this;
		}
	}

	public class Template {
		@AuraEnabled
		public Id id { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String sourceObject { get; private set; }
		@AuraEnabled // TODO: Deserialize JSON into concrete type
		public Map<String, Object> objectMappings { get; private set; }
		@AuraEnabled // TODO: Deserialize JSON into concrete type
		public Map<String, Object> signerMappings { get; private set; }
		@AuraEnabled
		public Boolean useAllTemplates { get; private set; }
		@AuraEnabled
		public Boolean useCurrentRecord { get; private set; }
		@AuraEnabled
		public Boolean hasPreviewedDocuments { get; private set; }
		@AuraEnabled
		public Integer stepsCompleted { get; private set; }
		@AuraEnabled
		public Boolean isSample { get; private set; }
		@AuraEnabled
		public List<File> generated { get; private set; }

		public Template(
			final Id id,
			final String name,
			final String sourceObject,
			final Map<String, Object> objectMappings,
			final Map<String, Object> signerMappings,
			final Boolean useAllTemplates,
			final Boolean useCurrentRecord,
			final Boolean hasPreviewedDocuments,
			final Integer stepsCompleted,
			final Boolean isSample,
			final List<File> generated) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.objectMappings = objectMappings == null ? new Map<String, Object>() : objectMappings;
			this.signerMappings = signerMappings == null ? new Map<String, Object>() : signerMappings;
			this.useAllTemplates = useAllTemplates;
			this.useCurrentRecord = useCurrentRecord;
			this.hasPreviewedDocuments = hasPreviewedDocuments;
			this.stepsCompleted = stepsCompleted;
			this.isSample = isSample;
			this.generated = generated == null ? new List<File>() : generated;
		}
	}

	public class Query {
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String relationship { get; private set; }
		@AuraEnabled
		public List<String> fields { get; private set; }
		@AuraEnabled
		public List<Query> children { get; private set; }

		public Query(
			final String type,
			final String relationship,
			final List<String> fields,
			final List<Query> children) {

			this.type = type;
			this.relationship = relationship;
			this.fields = fields == null ? new List<String>() : fields;
			this.children = children == null ? new List<Query>() : children;
		}
	}

	public static Boolean isValidQuery(final Query q) {
		return q != null
			&& String.isNotBlank(q.type)
			&& Collection.isNotEmpty(q.fields);
	}

	public static Boolean isValidChildQuery(final Query q) {
		return isValidQuery(q)
			&& String.isNotBlank(q.relationship);
	}
}
