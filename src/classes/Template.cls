public class Template {
	public UUID id { get; private set; }
	public String name { get; private set; }
	// TODO: Custom fields is the only thing we need on subsequent lookups. See if we can store with Document__c to avoid extra callouts. Or just use cache.
	public List<CustomField> customFields { get; private set; }

	public Template(final UUID id, final String name, final List<CustomField> customFields) {
		this.id = id;
		this.name = name;
		this.customFields = customFields;
	}

	public Document toDocument(final Integer sequence) {
		return new Document(null, Document.TYPE_TEMPLATE, sequence, this.name, null,
			0, UUID.toString(this.id));
	}
}
