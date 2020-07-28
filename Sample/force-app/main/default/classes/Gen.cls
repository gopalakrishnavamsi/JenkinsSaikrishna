public class Gen {

	public static final String TYPE_WORD = 'Microsoft Word';
	public static final String TYPE_ONLINE = 'Online Editor';
	public static final String FILE_TYPE_WORD = 'Word';
	public static final String FILE_TYPE_PDF = 'PDF';
	public static final String FILE_SUFFIX_NAME = 'name';
	public static final String FILE_SUFFIX_DATE = 'date';
	public static final String FILE_SUFFIX_NAME_DATE = 'name_date';

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
		@AuraEnabled
		public Gen.Rule rule { get; private set; }

		public File(
			final Id id,
			final String title,
			final String extension,
			final Integer size,
			final String generatedFormat,
			final String generatedName,
			final String generatedSuffix,
			final Id contentDocumentId,
			final Gen.Rule rule) {

			this.id = id;
			this.title = title;
			this.extension = extension;
			this.size = size;
			this.generatedFormat = generatedFormat;
			this.generatedName = generatedName;
			this.generatedSuffix = generatedSuffix;
			this.contentDocumentId = contentDocumentId;
			this.rule = rule;
		}
	}

	public class Rule {
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String ruleType { get; private set; }
		@AuraEnabled
		public List<RuleConditions> conditions { get; private set; }

		public Rule(
			final String name,
			final String ruleType,
			final List<RuleConditions> conditions) {

			this.name = name;
			this.ruleType = ruleType;
			this.conditions = conditions == null ? new List<RuleConditions>() : conditions;
		}
	}

	public class RuleConditions {
		@AuraEnabled
		public String fieldName { get; private set; }
		@AuraEnabled
		public String fieldType { get; private set; }
		@AuraEnabled
		public String matchType { get; private set; }
		@AuraEnabled
		public String matchValue { get; private set; }
	}

	public class RuleEvaluation {
		@AuraEnabled
		public String contentDocumentId { get; private set; }
		@AuraEnabled
		public Boolean matches { get; private set; }

		public RuleEvaluation(
			final String contentDocumentId,
			final Boolean matches) {

			this.contentDocumentId = contentDocumentId;
			this.matches = matches;
		}
	}

	public class Task {
		@AuraEnabled
		public UUID id { get; private set; }
		@AuraEnabled
		public Id contentVersionId { get; private set; }
		@AuraEnabled
		public String status { get; private set; }
		@AuraEnabled
		public String message { get; private set; }
		@AuraEnabled
		public Gen.File file { get; private set; }
		@AuraEnabled
		public String outputFileName { get; private set; }
		@AuraEnabled
		public Boolean success {
			get {
				return this.status == 'Success' || this.status == Label.Success;
			}
		}
		public Boolean complete {
			get {
				return this.status == Label.Success || this.status == Label.Failure;
			}
		}

		public Task(
			final Gen.File file,
			final String outputFileName) {

			this.file = file;
			this.outputFileName = outputFileName;
		}

		public Task(
			final UUID id,
			final Id contentVersionId,
			final String status,
			final String message) {

			this.id = id;
			this.contentVersionId = contentVersionId;
			this.status = status;
			this.message = message;
		}

		public Gen.Task withId(final UUID id) {
			this.id = id;
			return this;
		}

		public Gen.Task withStatus(final String status) {
			this.status = status;
			return this;
		}

		public Gen.Task withMessage(final String message) {
			this.message = message;
			return this;
		}

		public Gen.Task withFile(final Gen.File file) {
			this.file = file;
			return this;
		}
	}

	public class Job {
		@AuraEnabled
		public Id templateId { get; private set; }
		@AuraEnabled
		public Entity source { get; private set; }
		@AuraEnabled
		public String locale { get; private set; }
		@AuraEnabled
		public List<Gen.Task> tasks { get; private set; }

		public Job(
			final Id templateId,
			final Entity source,
			final String locale,
			final List<Gen.Task> tasks) {

			this.templateId = templateId;
			this.source = source;
			this.locale = locale;
			this.tasks = tasks == null ? new List<Gen.Task>() : tasks;
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
		public String templateType { get; private set; }
		@AuraEnabled
		public String description { get; private set; }
		@AuraEnabled
		public Gen.ObjectMapping objectMappings { get; private set; }
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
		@AuraEnabled
		public UUID springTemplateId { get; private set; }
		@AuraEnabled
		public String fileName { get; private set; }
		@AuraEnabled
		public String fileSuffix { get; private set; }
        

		public Template(final String name) {
			this.name = name;
		}

		public Template(
			final Id id,
			final String name,
			final String sourceObject,
			final String templateType,
			final String description,
			final Gen.ObjectMapping objectMappings,
			final List<Gen.SignerFieldMappings> signerMappings,
			final Boolean useAllTemplates,
			final Boolean useCurrentRecord,
			final Boolean hasPreviewedDocuments,
			final Integer stepsCompleted,
			final Boolean isSample,
			final List<File> generated,
			final UUID springTemplateId,
			final String fileName,
			final String fileSuffix) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.templateType = templateType;
			this.description = description;
			this.objectMappings = objectMappings;
			this.signerMappings = signerMappings == null ? new List<Gen.SignerFieldMappings>() : signerMappings;
			this.useAllTemplates = useAllTemplates;
			this.useCurrentRecord = useCurrentRecord;
			this.hasPreviewedDocuments = hasPreviewedDocuments;
			this.stepsCompleted = stepsCompleted;
			this.isSample = isSample;
			this.generated = generated == null ? new List<File>() : generated;
			this.springTemplateId = springTemplateId;
			this.fileName = fileName;
			this.fileSuffix = fileSuffix;
		}
	}

	public class SignerFieldMappings {
		@AuraEnabled
		public List<Gen.SignerFieldMappingDetails> fieldMappings { get; private set; }
	}

	public class SignerFieldMappingDetails {
		@AuraEnabled
		public String apiName { get; private set; }
	}

	public class ObjectMapping {
		@AuraEnabled
		public Integer version { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public List<FieldMapping> fieldMappings { get; private set; }

		public ObjectMapping(
			final Integer version,
			final String name,
			final String label,
			final List<FieldMapping> fieldMappings) {

			this.version = version;
			this.name = name;
			this.label = label;
			this.fieldMappings = fieldMappings == null ? new List<FieldMapping>() : fieldMappings;
		}
	}

	public class FieldMapping {
		@AuraEnabled
		public String type { get; private set; }
		@AuraEnabled
		public Integer depth { get; private set; }
		@AuraEnabled
		public String key { get; private set; }
		@AuraEnabled
		public List<String> path { get; private set; }
		@AuraEnabled
		public List<Field> fields { get; private set; }
		public transient Boolean isRoot {
			get {
				return this.type == 'ROOT';
			}
		}

		public FieldMapping(
			final String type,
			final Integer depth,
			final String key,
			final List<String> path,
			final List<Field> fields) {

			this.type = type;
			this.depth = depth;
			this.key = key;
			this.path = path == null ? new List<String>() : path;
			this.fields = fields == null ? new List<Field>() : fields;
		}
	}

	public class Field {
		@AuraEnabled
		public String type { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String relatesTo { get; private set; }
		@AuraEnabled
		public String relationship { get; private set; }
		@AuraEnabled
		public String parentIdField { get; private set; }
		@AuraEnabled
		public String format { get; private set; }
		@AuraEnabled
		public Integer scale { get; private set; }
		@AuraEnabled
		public Boolean isChildRelation { get; private set; }
		@AuraEnabled
		public Boolean isConditional { get; private set; }
		@AuraEnabled
		public String matchType { get; private set; }
		@AuraEnabled
		public String conditionalValue { get; private set; }
		@AuraEnabled
		public String filterBy { get; private set; }
		@AuraEnabled
		public String orderBy { get; private set; }
		@AuraEnabled
		public Integer maximumRecords { get; private set; }

		public Field(
			final String type,
			final String name,
			final String label,
			final String relatesTo,
			final String relationship,
			final String parentIdField,
			final String format,
			final Integer scale,
			final Boolean isChildRelation,
			final Boolean isConditional,
			final String matchType,
			final String conditionalValue,
			final String filterBy,
			final String orderBy,
			final Integer maximumRecords) {

			this.type = type;
			this.name = name;
			this.label = label;
			this.relatesTo = relatesTo;
			this.relationship = relationship;
			this.parentIdField = parentIdField;
			this.format = format;
			this.scale = scale;
			this.isChildRelation = isChildRelation;
			this.isConditional = isConditional;
			this.matchType = matchType;
			this.conditionalValue = conditionalValue;
			this.orderBy = orderBy;
			this.filterBy = filterBy;
			this.maximumRecords = maximumRecords;
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
			&& (Collection.isNotEmpty(q.fields) || Collection.isNotEmpty(q.children));
	}

	public static Boolean isValidChildQuery(final Query q) {
		return isValidQuery(q)
			&& String.isNotBlank(q.relationship);
	}

	public class LayoutParameters {
		public String genButtonApiName { get; private set; }
		public String genButtonLabel { get; private set; }
		public String genTemplateId { get; private set; }
	}

	public class GenTemplateDisplay {
		@AuraEnabled
		public Id id { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String sourceObject { get; private set; }
		@AuraEnabled
		public String templateType { get; private set; }
		@AuraEnabled
		public Datetime lastModifiedDate { get; private set; }

		public GenTemplateDisplay(
			final Id id,
			final String name,
			final String sourceObject,
			final String templateType,
			final Datetime lastModifiedDate) {

			this.id = id;
			this.name = name;
			this.sourceObject = sourceObject;
			this.templateType = templateType;
			this.lastModifiedDate = lastModifiedDate;
		}
	}
}