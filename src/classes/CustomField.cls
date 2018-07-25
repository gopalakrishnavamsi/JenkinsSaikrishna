/**
 * Represents an envelope, template, or account custom field.
 */
public class CustomField {

	private static final String TYPE_TEXT = 'text';
	private static final String TYPE_LIST = 'list';

	/**
	 * The type of the custom field, list or text.
	 */
	@AuraEnabled
	public String type { get; private set; }
	/**
	 * The name of the custom field.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The value of the custom field.
	 */
	@AuraEnabled
	public String value { get; private set; }
	/**
	 * List items for the custom field. Ignored if this is a text custom field.
	 */
	@AuraEnabled
	public List<String> items { get; private set; }
	/**
	 * Whether a value is required for the custom field.
	 */
	@AuraEnabled
	public Boolean required { get; private set; }
	/**
	 * Whether to display the custom field to recipients.
	 */
	@AuraEnabled
	public Boolean show { get; private set; }
	/**
	 * Read-only property indicating whether this is a text custom field.
	 */
	@AuraEnabled
	public Boolean isText {
		get {
			return this.type == TYPE_TEXT;
		}
	}
	/**
	 * Read-only property indicating whether this is a list custom field.
	 */
	@AuraEnabled
	public Boolean isList {
		get {
			return this.type == TYPE_LIST;
		}
	}

	/**
	 * Constructs a custom field.
	 *
	 * @param type The type of the custom field, either list or text.
	 * @param name The name of the custom field.
	 * @param value The value of the custom field.
	 * @param items The list items for list custom fields. Ignored for text custom fields.
	 * @param required Whether a value is required for the custom field.
	 * @param show Whether to display the custom field to recipients.
	 */
	public CustomField(final String type, final String name, final String value, final List<String> items,
		final Boolean required, final Boolean show) {

		this.type = type;
		this.name = name;
		this.value = value;
		this.items = items == null ? new List<String>() : items;
		this.required = required;
		this.show = show;
	}

	/**
 	 * Factory constructor for a text custom field.
 	 *
 	 * @param name The name of the custom field.
 	 * @param value The value of the custom field.
 	 * @param required Whether a value is required for the custom field.
 	 * @param show Whether to display the custom field to recipients.
 	 *
 	 * @returns The new text custom field.
 	 */
	public static CustomField newTextField(final String name, final String value, final Boolean required,
		final Boolean show) {

		return new CustomField(TYPE_TEXT, name, value, null, required, show);
	}

	/**
	 * Factory constructor for a list custom field.
	 *
	 * @param name The name of the custom field.
	 * @param value The value of the custom field.
	 * @param items The possible values for the custom field.
	 * @param required Whether a value is required for the custom field.
	 * @param show Whether to display the custom field to recipients.
	 *
	 * @return The new list custom field.
	 */
	public static CustomField newListField(final String name, final String value, final List<String> items,
		final Boolean required, final Boolean show) {

		return new CustomField(TYPE_LIST, name, value, items, required, show);
	}

	/**
	 * Creates a deep copy of the custom field.
	 *
	 * @return The copied custom field.
	 */
	public CustomField copy() {
		return new CustomField(this.type, this.name, this.value, this.items.clone(), this.required, this.show);
	}

	/**
	 * Set the <code>value</code> property of the custom field.
	 *
	 * @param value The new custom field value.
	 *
	 * @return This custom field with the updated <code>value</code> property.
	 */
	public CustomField withValue(final String value) {
		this.value = value;
		return this;
	}
}
