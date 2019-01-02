/**
 * Representation of a Salesforce object layout.
 */
public class Layout {
	/**
	 * The Salesforce object type.
	 */
	public transient SObjectType type { get; private set; }
	/**
	 * The layout identifier.
	 */
	@AuraEnabled
	public Id id { get; private set; }
	/**
	 * The layout namespace.
	 */
	@AuraEnabled
	public String namespace { get; private set; }
	/**
	 * The layout name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The layout full name.
	 */
	public transient String fullName {
		get {
			return String.isBlank(this.namespace)
				? String.format('{0}-{1}', new List<String> {
					String.valueOf(this.type),
					this.name
				})
				: String.format('{0}-{1}__{2}', new List<String> {
					String.valueOf(this.type),
					this.namespace,
					this.name
				});
		}
	}

	/**
	 * Constructs a new layout.
	 *
	 * @param type The Salesforce object type.
	 * @param id The layout identifier.
	 * @param namespace The layout namespace.
	 * @param name The layout name.
	 */
	public Layout(
		final SObjectType type,
		final Id id,
		final String namespace,
		final String name) {

		this.type = type;
		this.id = id;
		this.namespace = namespace;
		this.name = name;
	}
}
