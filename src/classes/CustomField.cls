public class CustomField {

	public static final String TYPE_TEXT = 'text';
	public static final String TYPE_LIST = 'list';

	public String type { get; private set; }
	public String name { get; private set; }
	public String value { get; private set; }
	public List<String> items { get; private set; }
	public Boolean required { get; private set; }
	public Boolean show { get; private set; }
	public Boolean isText {
		get {
			return this.type == TYPE_TEXT;
		}
	}
	public Boolean isList {
		get {
			return this.type == TYPE_LIST;
		}
	}

	public CustomField(final String name, final String value, final Boolean required, final Boolean show) {
		this(TYPE_TEXT, name, value, null, required, show);
	}

	public CustomField(final String name, final String value, final List<String> items, final Boolean required,
		final Boolean show) {

		this(TYPE_LIST, name, value, items, required, show);
	}

	public CustomField(final String type, final String name, final String value, final List<String> items,
		final Boolean required, final Boolean show) {

		this.type = type;
		this.name = name;
		this.value = value;
		this.items = items == null ? new List<String>() : items;
		this.required = required;
		this.show = show;
	}

	public CustomField withValue(final String value) {
		return new CustomField(this.type, this.name, value, this.items, this.required, this.show);
	}
}
