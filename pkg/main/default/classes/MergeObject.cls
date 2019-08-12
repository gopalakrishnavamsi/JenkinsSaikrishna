public class MergeObject implements Comparable {

	private static final Set<SObjectType> BLACKLIST = new Set<SObjectType> {
		Schema.Task.getSObjectType()
	};

	transient public SObjectType type { get; private set; }
	transient public DescribeSObjectResult describe { get; private set; }

	@AuraEnabled
	public String name { get; private set; }
	@AuraEnabled
	public String label { get; private set; }
	@AuraEnabled
	public Boolean isUpdateable { get; private set; }

	private MergeObject(
		final SObjectType type,
		final DescribeSObjectResult describe,
		final String name,
		final String label,
		final Boolean isUpdateable) {

		this.type = type;
		this.describe = describe;
		this.name = name;
		this.label = label;
		this.isUpdateable = isUpdateable;
	}

	public static Boolean isValid(final SObjectType type) {
		return type != null && isValid(type.getDescribe());
	}

	public static Boolean isValid(final DescribeSObjectResult type) {
		return type != null
			&& !BLACKLIST.contains(type.getSObjectType())
			&& type.isAccessible()
			&& type.isCreateable()
			&& type.isQueryable();
	}

	public static MergeObject forType(final SObjectType type) {
		if (!isValid(type)) throw new DocuSignException(System.Label.InvalidType);

		return forType(type.getDescribe());
	}

	public static MergeObject forType(final DescribeSObjectResult describe) {
		if (!isValid(describe)) throw new DocuSignException(System.Label.InvalidType);

		return new MergeObject(
			describe.getSObjectType(),
			describe,
			describe.getName(),
			describe.getLabel(),
			describe.isUpdateable());
	}

	public Integer compareTo(final Object compareTo) {
		MergeObject other = (MergeObject)compareTo;
		if (this.label == other.label) return 0;
		if (this.label > other.label) return 1;
		return -1;
	}
}