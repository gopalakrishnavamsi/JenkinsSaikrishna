public class MergeField implements Comparable {

	public static final Integer MAX_DEPTH = 4; // TODO: Move max depth to config
	private static final String TYPE_CHILD_RELATIONSHIP = 'CHILD_RELATIONSHIP';
	private static final List<String> BLACKLIST = new List<String> {
		'OwnerId', 'CreatedById', 'LastModifiedById'
	};

	transient public DescribeFieldResult field { get; private set; }

	@AuraEnabled
	public String name { get; private set; }
	@AuraEnabled
	public String type { get; private set; }
	@AuraEnabled
	public String label { get; private set; }
	@AuraEnabled
	public String relatesTo { get; private set; }
	@AuraEnabled
	public Boolean isUpdateable { get; private set; }
	@AuraEnabled
	public Boolean hasRelationship { get; private set; }

	private MergeField(
		final DescribeFieldResult field,
		final String name,
		final String type,
		final String label,
		final String relatesTo,
		final Boolean isUpdateable) {

		this.field = field;
		this.name = name;
		this.type = type;
		this.label = label;
		this.relatesTo = relatesTo;
		this.isUpdateable = isUpdateable;
		this.hasRelationship = String.isNotBlank(relatesTo);
	}

	public static Boolean isValid(final DescribeFieldResult field) {
		if (field == null
			|| BLACKLIST.contains(field.getName())
			|| !field.isAccessible()
			|| field.isNamePointing()) {

			return false;
		}

		SObjectType refType = (SObjectType)Collection.head(field.getReferenceTo());
		return refType == null || MergeObject.isValid(refType.getDescribe());
	}

	public static Boolean isValid(final ChildRelationship childRelationship) {
		return childRelationship != null
			&& String.isNotBlank(childRelationship.getRelationshipName())
			&& MergeObject.isValid(childRelationship.getChildSObject().getDescribe())
			&& isValid(childRelationship.getField().getDescribe());
	}

	private static String getType(final DescribeFieldResult field) {
		Schema.DisplayType t = field.getType();
		return t == Schema.DisplayType.TEXTAREA && field.isHtmlFormatted() ? 'RICHTEXT' : String.valueOf(t);
	}

	public static MergeField forField(final DescribeFieldResult field) {
		if (!isValid(field)) throw new DocuSignException(System.Label.InvalidType);

		return new MergeField(
			field,
			field.getName(),
			getType(field),
			field.getLabel(),
			String.valueOf(Collection.head(field.getReferenceTo())),
			field.isUpdateable());
	}

	public static MergeField forChildRelationship(final ChildRelationship childRelationship) {
		if (!isValid(childRelationship)) throw new DocuSignException(System.Label.InvalidType);

		DescribeSObjectResult typeDesc = childRelationship.getChildSObject().getDescribe();
		return new MergeField(
			childRelationship.getField().getDescribe(),
			childRelationship.getRelationshipName(),
			TYPE_CHILD_RELATIONSHIP,
			typeDesc.getLabelPlural(),
			typeDesc.getName(),
			false);
	}

	public Integer compareTo(final Object compareTo) {
		MergeField other = (MergeField)compareTo;
		if (this.label == other.label) return 0;
		if (this.label > other.label) return 1;
		return -1;
	}
}