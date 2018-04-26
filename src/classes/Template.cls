/**
 * Representation of a DocuSign template.
 */
public class Template {
	/**
	 * The DocuSign template ID.
	 */
	public UUID id { get; private set; }
	/**
	 * The DocuSign template name.
	 */
	public String name { get; private set; }
	/**
	 * The DocuSign template custom fields.
	 */
	// TODO: Custom fields is the only thing we need on subsequent lookups. See if we can store with Document__c to avoid extra callouts. Or just use cache.
	public List<CustomField> customFields { get; private set; }

	/**
	 * Constructs a DocuSign template.
	 *
	 * @param id The DocuSign template ID.
	 * @param name The DocuSign template name.
	 * @param customFields The DocuSign template custom fields.
	 */
	public Template(final UUID id, final String name, final List<CustomField> customFields) {
		this.id = id;
		this.name = name;
		this.customFields = customFields;
	}

	public Document toDocument() {
		return new Document(null, Document.TYPE_TEMPLATE, null, this.name, null, 0, UUID.toString(this.id));
	}
}
