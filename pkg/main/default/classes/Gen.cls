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
		@AuraEnabled
		public Id contentDocumentId { get; private set; }

		public File(
			final Id id,
			final String title,
			final String extension,
			final Integer size,
			final String generatedFormat,
			final String generatedName,
			final String generatedSuffix,
			final Id contentDocumentId) {

			this.id = id;
			this.title = title;
			this.extension = extension;
			this.size = size;
			this.generatedFormat = generatedFormat;
			this.generatedName = generatedName;
			this.generatedSuffix = generatedSuffix;
			this.contentDocumentId = contentDocumentId;
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
		@AuraEnabled
		public List<Gen.ObjectMappings> objectMappings { get; private set; }
		@AuraEnabled
		public List<Gen.SignerFieldMappings> signerMappings { get; private set; }
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
			final List<Gen.ObjectMappings> objectMappings,
			final List<Gen.SignerFieldMappings> signerMappings,
			final Boolean useAllTemplates,
			final Boolean useCurrentRecord,
			final Boolean hasPreviewedDocuments,
			final Integer stepsCompleted,
			final Boolean isSample,
			final List<File> generated) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.objectMappings = objectMappings == null ? new List<Gen.ObjectMappings>() : objectMappings;
			this.signerMappings = signerMappings == null ? new List<Gen.SignerFieldMappings>() : signerMappings;
			this.useAllTemplates = useAllTemplates;
			this.useCurrentRecord = useCurrentRecord;
			this.hasPreviewedDocuments = hasPreviewedDocuments;
			this.stepsCompleted = stepsCompleted;
			this.isSample = isSample;
			this.generated = generated == null ? new List<File>() : generated;
		}
	}

	public class SignerFieldMappings {
		@AuraEnabled
		public List<Gen.SignerFieldMappingDetails> fieldMappings { get; private set; }
		public SignerFieldMappings(
			final List<Gen.SignerFieldMappingDetails> fieldMappings) {
			this.fieldMappings = fieldMappings == null ? new List<Gen.SignerFieldMappingDetails>() : fieldMappings;
		}
	}

	public class SignerFieldMappingDetails {
		@AuraEnabled
		public String apiName { get; private set; }
		public SignerFieldMappingDetails(
			final String apiName) {
			this.apiName = apiName;
		}
	}

	public class ObjectMappings {
		@AuraEnabled
		public String apiName { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String objLabel { get; private set; }
		@AuraEnabled
		public List<Gen.FieldMappings> fieldMappings { get; private set; }
		@AuraEnabled
		public Boolean isPrimary { get; private set; }

		public ObjectMappings(
			final String apiName,
			final String label,
			final String objLabel,
			final List<Gen.FieldMappings> fieldMappings,
			final Boolean isPrimary) {
			this.apiName = apiName;
			this.label = label;
			this.objLabel = objLabel;
			this.fieldMappings = fieldMappings == null ? new List<Gen.FieldMappings>() : fieldMappings;
			this.isPrimary = isPrimary;
		}
	}

	public class FieldMappings {
		@AuraEnabled
		public String apiName { get; private set; }
		@AuraEnabled
		public String dataType { get; private set; }
		@AuraEnabled
		public List<Gen.ChildFieldMappings> childFieldMappings { get; private set; }
		@AuraEnabled
		public Boolean isConditional { get; private set; }
		@AuraEnabled
		public Boolean isChildRelation { get; private set; }
		@AuraEnabled
		public String format { get; private set; }
		@AuraEnabled
		public Integer decimalPlaces { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String matchType { get; private set; }
		@AuraEnabled
		public String conditionalValue { get; private set; }

		public FieldMappings(
			final String apiName,
			final String dataType,
			final List<Gen.ChildFieldMappings> childFieldMappings,
			final Boolean isConditional,
			final Boolean isChildRelation,
			final String format,
			final Integer decimalPlaces,
			final String label,
			final String matchType,
			final String conditionalValue) {
			this.apiName = apiName;
			this.dataType = dataType;
			this.childFieldMappings = childFieldMappings == null ? new List<Gen.ChildFieldMappings>() : childFieldMappings;
			this.isConditional = isConditional;
			this.isChildRelation = isChildRelation;
			this.decimalPlaces = decimalPlaces;
			this.format = format;
			this.label = label;
			this.matchType = matchType;
			this.conditionalValue = conditionalValue;
		}
	}

	public class ChildFieldMappings {
		@AuraEnabled
		public String apiName { get; private set; }
		@AuraEnabled
		public String dataType { get; private set; }
		@AuraEnabled
		public Boolean isConditional { get; private set; }
		@AuraEnabled
		public String format { get; private set; }
		@AuraEnabled
		public Integer decimalPlaces { get; private set; }
		@AuraEnabled
		public Boolean isChildRelation { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String matchType { get; private set; }
		@AuraEnabled
		public String conditionalValue { get; private set; }

		public ChildFieldMappings(
			final String apiName,
			final String dataType,
			final Boolean isConditional,
			final String format,
			final Integer decimalPlaces,
			final Boolean isChildRelation,
			final String label,
			final String matchType,
			final String conditionalValue) {
			this.apiName = apiName;
			this.dataType = dataType;
			this.isConditional = isConditional;
			this.format = format;
			this.decimalPlaces = decimalPlaces;
			this.isChildRelation = isChildRelation;
			this.label = label;
			this.matchType = matchType;
			this.conditionalValue = conditionalValue;
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

	public class LayoutParameters {
		public String genButtonApiName { get; private set; }
		public String genButtonLabel { get; private set; }
		public String genTemplateId { get; private set; }

		public LayoutParameters(
			final String genButtonApiName,
			final String genButtonLabel,
			final String genTemplateId) {

			this.genButtonApiName = genButtonApiName;
			this.genButtonLabel = genButtonLabel;
			this.genTemplateId = genTemplateId;
		}
	}

	public class GenTemplateDisplay {
		@AuraEnabled
		public Id id { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String sourceObject { get; private set; }
		@AuraEnabled
		public Datetime lastModifiedDate { get; private set; }

		public GenTemplateDisplay(
			final Id id,
			final String name,
			final String sourceObject,
			final Datetime lastModifiedDate) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.lastModifiedDate = lastModifiedDate;
		}
	}
}
