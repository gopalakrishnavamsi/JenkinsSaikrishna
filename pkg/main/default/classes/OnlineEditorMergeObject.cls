public class OnlineEditorMergeObject implements Comparable {

	private static final Set<SObjectType> DENY_LIST = new Set<SObjectType> {
		Schema.Task.sObjectType
	};

	// updating the list of blocked fields
	private static final List<String> FIELD_DENY_LIST = new List<String> {
		'LastModifiedDate', 'LastReferencedDate', 'SystemModstamp',
		'LastViewedDate', 'CreatedDate', 'IsArchived', 'IsDeleted',
		'CreatedById', 'LastModifiedById'
	};

	transient public SObjectType type { get; private set; }
	transient public DescribeSObjectResult describe { get; private set; }

	@AuraEnabled
	public String name { get; private set; }
	@AuraEnabled
	public String label { get; private set; }
	@AuraEnabled
	public String relationshipName { get; private set;}
	@AuraEnabled
	public Boolean isList { get; private set; }
	@AuraEnabled
	public List<OnlineEditorMergeObject> children { get; private set; }
	@AuraEnabled
	public List<String> childrenPath { get; set; }

	private OnlineEditorMergeObject(
		final SObjectType type,
		final DescribeSObjectResult describe,
		final String name,
		final String label) {
		this(type, describe, name, label, false);
	}
	private OnlineEditorMergeObject(
		final SObjectType type,
		final DescribeSObjectResult describe,
		final String name,
		final String label,
		final Boolean isList) {

		this.type = type;
		this.describe = describe;
		this.name = name;
		this.label = label;
		this.children = new List<OnlineEditorMergeObject>();
		this.isList = isList;
	}

	public static Boolean isValid(final SObjectType type) {
		return type != null && isValid(type.getDescribe());
	}

	public static Boolean isValid(final DescribeSObjectResult type) {
		return type != null
			&& !DENY_LIST.contains(type.getSObjectType())
			&& type.isAccessible()
			&& type.isCreateable()
			&& type.isQueryable();
	}

	public static Boolean isValid(final DescribeFieldResult field) {
		return field != null
			&& !FIELD_DENY_LIST.contains(field.getName())
			&& field.isAccessible()
			&& !field.isNamePointing()
			&& String.isNotBlank(field.getRelationshipName());
	}

	public static OnlineEditorMergeObject forType(final SObjectType type) {
		if (!isValid(type)) throw new DocuSignException(System.Label.InvalidType);

		return forType(type.getDescribe());
	}

	public static OnlineEditorMergeObject forType(final DescribeSObjectResult describe) {
		if (!isValid(describe)) throw new DocuSignException(System.Label.InvalidType);

		return new OnlineEditorMergeObject(
			describe.getSObjectType(),
			describe,
			describe.getName(),
			describe.getLabel());
	}

	public static OnlineEditorMergeObject forField(final DescribeFieldResult field) {
		DescribeSObjectResult describe = field.getReferenceTo().get(0).getDescribe();
		String name = describe.getName();
		String label = field.getLabel().replaceFirst(' ID$', '');
		OnlineEditorMergeObject obj = new OnlineEditorMergeObject(
			describe.getSObjectType(),
			describe,
			name,
			label);
		obj.relationshipName = field.getRelationshipName();
		return obj;
	}

	public static OnlineEditorMergeObject forChildRelationship(final ChildRelationship child) {
		SObjectType type = child.getChildSObject();
		DescribeSObjectResult describe = type.getDescribe();
		String name = describe.getName();
		String relationshipName = child.getRelationshipName();
		OnlineEditorMergeObject obj = new OnlineEditorMergeObject(
			type,
			describe,
			name,
			relationshipName,
			true);
		obj.relationshipName = relationshipName;
		return obj;
	}

	public Integer compareTo(final Object compareTo) {
		OnlineEditorMergeObject other = (OnlineEditorMergeObject)compareTo;
		if (this.label == other.label) return 0;
		if (this.label > other.label) return 1;
		return -1;
	}
}