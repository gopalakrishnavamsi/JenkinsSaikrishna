/**
 * No sharing declaration here as it's run as part of post-install. "with sharing" or "inherited sharing" causes
 * package installation to fail with "Insufficient Privileges" error.
 */
public class WordTemplateUpdater implements Database.Batchable<SObject>, PostInstallScript {

	private static final Set<SObjectType> TYPE_BLACKLIST = new Set<SObjectType> { Schema.Group.getSObjectType() };
	private static final String CURRENT_DATE = 'CurrentDate';
	private static Integer templateCount = null;
	private static final Map<String, String> V1_TO_V2_DATE_MAPPINGS = new Map<String, String> {
		'default' => 'default',
		'MM/dd/yyyy' => 'MM/dd/yyyy',
		'yyyy-MM-dd' => 'YYYY-MM-DD',
		'dd.MM.yyyy' => 'D.MM.YYYY',
		'MMMM dd, yyyy' => 'MMMM D, YYYY'
	};

	@TestVisible
	private static Integer batchLimit = 200;

	@TestVisible
	private class ObjectV1 {
		public String apiName;
		public String label;
		public List<FieldV1> fieldMappings;
	}

	@TestVisible
	private class FieldV1 {
		public String apiName;
		public String dataType;
		public List<FieldV1> childFieldMappings;
		public Boolean isConditional;
		public String dateFormat;
		public String currencyFormat;
		public Integer decimalPlaces;
		public String label;
		public String matchType;
		public String conditionalValue;
	}

	@TestVisible
	private static String convertFormat(final FieldV1 v1) {
		if (v1 == null) return null;

		String result = null;

		Boolean isDateTimeType = v1.dataType == Schema.DisplayType.DATETIME.name();
		Boolean isDateType = v1.dataType == Schema.DisplayType.DATE.name() || v1.apiName == CURRENT_DATE;
		Boolean isTimeType = v1.dataType == Schema.DisplayType.TIME.name();
		Boolean isDateOrTimeType = isDateTimeType || isDateType || isTimeType;

		Boolean isCurrencyFormatDefined = String.isNotBlank(v1.currencyFormat) && v1.currencyFormat != 'default';
		Boolean isCurrencyType = v1.dataType == Schema.DisplayType.CURRENCY.name()
			|| v1.dataType == Schema.DisplayType.DOUBLE.name();

		if (isDateOrTimeType) {
			String dateFormat = V1_TO_V2_DATE_MAPPINGS.containsKey(v1.dateFormat) ? V1_TO_V2_DATE_MAPPINGS.get(v1.dateFormat) : 'default';
			String timeFormat = 'default';
			if (isDateTimeType) {
				result = String.format('{0}{1}{2}', new List<String> { dateFormat, '|', timeFormat });
			} else if (isDateType) {
				result = dateFormat;
			} else if (isTimeType) {
				result = timeFormat;
			}
		} else if (isCurrencyFormatDefined && isCurrencyType) {
			result = v1.currencyFormat;
		}
		return result;
	}

	@TestVisible
	private class Relationship {
		public String name { get; private set; }
		public String label { get; private set; }
		public String relatesTo { get; private set; }
		public String parentIdField { get; private set; }

		public Relationship(
			final String name,
			final String label,
			final String relatesTo,
			final String parentIdField) {

			this.name = name;
			this.label = label;
			this.relatesTo = relatesTo;
			this.parentIdField = parentIdField;
		}
	}

	@TestVisible
	private static DescribeSObjectResult describeSObject(final String typeName) {
		DescribeSObjectResult result = null;
		if (String.isNotBlank(typeName)) {
			SObjectType t = Schema.getGlobalDescribe().get(typeName.toLowerCase());
			if (t != null) result = t.getDescribe();
		}
		return result;
	}

	// TODO: This is more solid than Salesforce.getParentObjectType. Replace with this.
	@TestVisible
	private static Relationship getLookupField(
		final DescribeSObjectResult objectDescribe,
		final String relationshipName) {

		if (objectDescribe == null || String.isBlank(relationshipName)) return null;

		Relationship result;
		for (SObjectField f : objectDescribe.fields.getMap().values()) {
			DescribeFieldResult fd = f.getDescribe();
			if (fd != null && fd.getType() == Schema.DisplayType.REFERENCE && fd.getRelationshipName() == relationshipName) {
				Set<SObjectType> refs = new Set<SObjectType>(fd.getReferenceTo());
				refs.removeAll(TYPE_BLACKLIST); // This can be polymorphic, filter out types we can't deal with (for now)
				SObjectType t = (SObjectType)Collection.head(new List<SObjectType>(refs));
				if (t != null) {
					result = new Relationship(
						fd.getRelationshipName(),
						fd.getLabel(),
						t.getDescribe().getName(),
						fd.getName());
					break;
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Relationship getChildRelationship(
		final DescribeSObjectResult objectDescribe,
		final String relationshipName) {

		if (objectDescribe == null || String.isBlank(relationshipName)) return null;

		Relationship result = null;
		for (ChildRelationship cr : objectDescribe.getChildRelationships()) {
			if (cr != null && cr.relationshipName == relationshipName) {
				DescribeFieldResult dfr = cr.getField().getDescribe();
				result = new Relationship(
					cr.getRelationshipName(),
					dfr.getLabel(),
					cr.getChildSObject().getDescribe().getName(),
					dfr.getName());
				break;
			}
		}
		return result;
	}

	private static Boolean isValid(
		final DescribeSObjectResult objectDescribe,
		final String fieldName) {

		if (objectDescribe == null || String.isBlank(fieldName)) return false;

		if (fieldName == CURRENT_DATE) return true;

		SObjectField field = objectDescribe.fields.getMap().get(fieldName);
		return field != null && MergeField.isValid(field.getDescribe());
	}

	@TestVisible
	private static Gen.FieldMapping convert(
		final FieldV1 v1,
		final DescribeSObjectResult objectDescribe,
		final Gen.FieldMapping root,
		final Map<String, Gen.FieldMapping> lookups,
		final Map<String, Relationship> childRelationships) {

		if (v1 == null
			|| String.isBlank(v1.apiName)
			|| objectDescribe == null
			|| root == null
			|| root.fields == null
			|| lookups == null
			|| childRelationships == null) {

			return null;
		}

		List<String> path = v1.apiName.split('\\.');
		String type = path.size() > 1 ? 'REFERENCE' : v1.dataType;
		if (v1.apiName == CURRENT_DATE) {
			type = 'DATE';
		} else if (String.isBlank(type) || Collection.isNotEmpty(v1.childFieldMappings)) {
			type = 'CHILD_RELATIONSHIP';
		}

		Gen.FieldMapping result;
		switch on (type) {
			when 'REFERENCE' { // Lookup path[0] objectType.
				String relationshipName = path[0];
				Gen.FieldMapping lookup = lookups.get(relationshipName);
				if (lookup == null) {
					Relationship lookupField = getLookupField(objectDescribe, relationshipName);
					if (lookupField == null) {
						LoggerService.getInstance().warn('Invalid relationship ' + relationshipName
							+ ' for object ' + objectDescribe.getName());
						return null;
					}

					// add root lookup field
					root.fields.add(new Gen.Field(
						type,
						lookupField.name,
						lookupField.label,
						lookupField.relatesTo,
						lookupField.name,
						lookupField.parentIdField,
						null,
						null,
						false,
						false,
						null,
						null));
					// Cache relationship for later
					lookup = new Gen.FieldMapping(
						type,
						2,
						relationshipName,
						new List<String> { relationshipName },
						null);
					lookups.put(relationshipName, lookup);
				}
				lookup.fields.add(new Gen.Field(
					v1.dataType,
					path[1],
					v1.label,
					null,
					null,
					null,
					convertFormat(v1),
					v1.decimalPlaces,
					false,
					v1.isConditional,
					v1.matchType,
					v1.conditionalValue));
				result = lookup;
			} when 'CHILD_RELATIONSHIP' {
				Relationship childRelationship = childRelationships.get(v1.apiName);
				if (childRelationship == null) {
					// V1 stores relationship name in label field
					childRelationship = getChildRelationship(objectDescribe, v1.label);
					root.fields.add(new Gen.Field(
						type,
						childRelationship.relatesTo,
						childRelationship.label,
						childRelationship.relatesTo,
						childRelationship.name,
						childRelationship.parentIdField,
						null,
						null,
						true,
						false,
						null,
						null));
					childRelationships.put(v1.apiName, childRelationship);
				}
				Gen.FieldMapping child = new Gen.FieldMapping(
					type,
					2,
					v1.label,
					new List<String>(),
					null);
				DescribeSObjectResult childDesc = describeSObject(v1.apiName);
				if (childDesc != null && v1.childFieldMappings != null) {
					for (FieldV1 childFieldV1 : v1.childFieldMappings) {
						convert(
							childFieldV1,
							childDesc,
							child,
							lookups,
							childRelationships);
					}
				}
				result = child;
			} when else { // use type as-is
				if (isValid(objectDescribe, v1.apiName)) {
					root.fields.add(new Gen.Field(
						type,
						v1.apiName,
						v1.label,
						null,
						null,
						null,
						convertFormat(v1),
						v1.decimalPlaces,
						false,
						v1.isConditional,
						v1.matchType,
						v1.conditionalValue));
					result = root;
				}
			}
		}
		return result;
	}

	private static List<Gen.FieldMapping> convert(
		final List<FieldV1> v1,
		final DescribeSObjectResult objectDescribe) {

		if (objectDescribe == null || v1 == null) return new List<Gen.FieldMapping>();

		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			objectDescribe.getName(),
			null,
			null);
		List<Gen.FieldMapping> result = new List<Gen.FieldMapping> { root };
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, Relationship> childRelationships = new Map<String, Relationship>();
		Set<String> alreadyAdded = new Set<String>();
		for (FieldV1 f : v1) {
			Gen.FieldMapping v2 = convert(
				f,
				objectDescribe,
				root,
				lookups,
				childRelationships);
			if (v2 != null && !v2.isRoot && !alreadyAdded.contains(v2.key)) { // Root is already added
				result.add(v2);
				alreadyAdded.add(v2.key);
			}
		}
		return result;
	}

	@TestVisible
	private static Gen.ObjectMapping convert(final ObjectV1 v1) {
		if (v1 == null) return null;

		Gen.ObjectMapping result = null;
		DescribeSObjectResult d = describeSObject(v1.apiName);
		if (d != null) {
			result = new Gen.ObjectMapping(
				2,
				v1.apiName,
				v1.label,
				convert(
					v1.fieldMappings,
					d));
		}
		return result;
	}

	@TestVisible
	private static GenTemplate__c updateTemplate(final GenTemplate__c template) {
		if (template != null) {
			if (String.isNotBlank(template.ObjectMappings__c)) {
				JSONParser p = JSON.createParser(template.ObjectMappings__c);
				if (p.nextToken() == JSONToken.START_ARRAY) { // v1
					List<ObjectV1> v1s = (List<ObjectV1>)JSON.deserialize(
						template.ObjectMappings__c,
						List<ObjectV1>.class);
					Gen.ObjectMapping v2 = convert((ObjectV1)Collection.head(v1s));
					if (v2 != null) template.ObjectMappings__c = JSON.serialize(v2);
				}
			}
			if (String.isBlank(template.TemplateType__c)) template.TemplateType__c = Gen.TYPE_WORD;
		}
		return template;
	}

	private static List<GenTemplate__c> updateTemplates(final List<GenTemplate__c> templates) {
		if (templates == null) return new List<GenTemplate__c>();

		List<GenTemplate__c> result = new List<GenTemplate__c>();
		for (GenTemplate__c t : templates) {
			result.add(updateTemplate(t));
		}
		return result;
	}

	public Database.QueryLocator start(final Database.BatchableContext context) {
		LoggerService.getInstance().info('Starting Gen template migration batch: '
			+ (context == null ? 'UNKNOWN' : context.getJobId()));

		return Database.getQueryLocator('SELECT '
			+ Application.namespacePrefix + 'TemplateType__c, '
			+ Application.namespacePrefix + 'ObjectMappings__c '
			+ 'FROM ' + Application.namespacePrefix + 'GenTemplate__c '
			+ 'WHERE ' + Application.namespacePrefix + 'TemplateType__c != \'Online Editor\'');
	}

	public void execute(
		final Database.BatchableContext context,
		final List<GenTemplate__c> scope) {

		LoggerService.getInstance().info('Executing Gen template migration batch - '
			+ scope.size() + ' record(s): ' + (context == null ? 'UNKNOWN' : context.getJobId()));

		update updateTemplates(scope);
	}

	public void finish(final Database.BatchableContext context) {
		GenMigrationSettings__c s = GenMigrationSettings__c.getOrgDefaults();
		s.WordTemplatesUpdated__c = true;
		upsert s;

		LoggerService.getInstance().info('Gen template migration batch job complete: '
			+ (context == null ? 'UNKNOWN' : context.getJobId()));
	}

	private static AsyncApexJob getExistingJob() {
		return (AsyncApexJob)Collection.head([
			SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.NamespacePrefix = :Application.packageNamespace
			AND ApexClass.Name = 'WordTemplateUpdater'
			AND Status NOT IN ('Aborted', 'Completed', 'Failed')
			ORDER BY CreatedDate DESC
			LIMIT 1
		]);
	}

	public class UpdateResult {
		public Integer templateCount { get; private set; }
		public Id jobId { get; private set; }

		@TestVisible
		private UpdateResult(
			final Integer templateCount,
			final Id jobId) {

			this.templateCount = templateCount;
			this.jobId = jobId;
		}

		override public String toString() {
			if (String.isNotBlank(this.jobId)) {
				return String.format(Label.UpgradeTemplatesQueued_2, new List<Object> {
					this.templateCount, this.jobId
				});
			}
			return String.format(Label.UpgradeTemplatesComplete_1, new List<Object> {
				this.templateCount
			});
		}
	}

	private static Integer getTemplateCount() {
		if (templateCount == null) {
			templateCount = [
				SELECT COUNT()
				FROM GenTemplate__c
				WHERE TemplateType__c != :Gen.TYPE_ONLINE
			];
		}
		return templateCount;
	}

	@TestVisible
	private static UpdateResult updateTemplates() {
		Id jobId = null;
		AsyncApexJob job = getExistingJob();
		Integer templates = getTemplateCount();
		if (job != null) {
			jobId = job.Id;
		} else {
			LoggerService.getInstance().info('Found ' + templateCount
				+ ' Word template(s) that may require updates.');
			if (templates > batchLimit) { // queue batch job
				jobId = Database.executeBatch(new WordTemplateUpdater());
			} else if (templates > 0) { // update now
				update updateTemplates([
					SELECT TemplateType__c, ObjectMappings__c
					FROM GenTemplate__c
					WHERE TemplateType__c != :Gen.TYPE_ONLINE
					LIMIT 200
				]);
				GenMigrationSettings__c s = GenMigrationSettings__c.getOrgDefaults();
				s.WordTemplatesUpdated__c = true;
				upsert s;
			}
		}
		return new UpdateResult(
			templates,
			jobId);
	}

	public Boolean shouldExecute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		// Only execute if upgrading from < v2.2 and there are templates that haven't been updated
		return isUpgrade
			&& previousVersion != null
			&& previousVersion.major() <= 2
			&& previousVersion.minor() < 2
			&& !GenMigrationSettings__c.getOrgDefaults().WordTemplatesUpdated__c
			&& getTemplateCount() > 0;
	}

	public PostInstallResults execute(
		final Id organizationId,
		final Id installerId,
		final Version previousVersion,
		final Boolean isPush,
		final Boolean isUpgrade) {

		if (!this.shouldExecute(organizationId, installerId, previousVersion, isPush, isUpgrade)) {
			return new PostInstallResults().skipStep(Label.UpgradeWordTemplates, Label.PostInstallCriteriaNotMet);
		}

		PostInstallResults result = new PostInstallResults();
		try {
			UpdateResult updateResult = updateTemplates();
			result.endStepSuccess(
				Label.UpgradeWordTemplates,
				updateResult == null ? Label.Unknown : String.valueOf(updateResult));
		} catch (Exception ex) {
			result.endStepFailure(Label.UpgradeWordTemplates, ex);
		}
		return result;
	}
}
