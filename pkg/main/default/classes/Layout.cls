/**
 * Representation of a Salesforce object layout.
 */
public class Layout implements Comparable {

	public static final String ACTION_TYPE_SEND = 'SEND';
	public static final String ACTION_NAME_SEND = MetadataAPI.NAMESPACE_PREFIX + 'SendWithDocuSign';
	public static final String ACTION_NAME_GEN = MetadataAPI.NAMESPACE_PREFIX + 'Generate';
	public static final String ACTION_TYPE_GEN = 'GEN';
	public static final String ACTION_TYPE_OTHER = 'OTHER';

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
	 * The layout display name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The layout's custom actions or buttons.
	 */
	@AuraEnabled
	public List<Action> actions { get; private set; }
	/**
	 * The layout API name.
	 */
	@AuraEnabled
	public String fullName { get; private set; }

	/**
	 * Constructs a new layout.
	 *
	 * @param type The Salesforce object type.
	 * @param id The layout identifier.
	 * @param namespace The layout namespace.
	 * @param name The layout name.
	 * @param actions The layout's custom actions or buttons.
	 */
	public Layout(
		final SObjectType type,
		final Id id,
		final String namespace,
		final String name,
		final List<Action> actions) {

		this.type = type;
		this.id = id;
		this.namespace = namespace;
		this.name = StringUtils.decode(name);
		this.actions = actions == null ? new List<Action>() : actions;
		this.fullName = getFullName(type, namespace, name);
	}

	/**
	 * A DocuSign action.
	 */
	public class Action {
		/**
		 * The type of the DocuSign action: <code>SEND</code> or <code>GEN</code>.
		 */
		@AuraEnabled
		public String type { get; private set; }
		/**
		 * The name of the DocuSign action.
		 */
		@AuraEnabled
		public String name { get; private set; }

		/**
		 * The label of the DocuSign action.
		 */
		@AuraEnabled
		public String label { get; private set; }

		/**
		 * Constructs a DocuSign action.
		 *
		 * @param type The type of the DocuSign action: <code>SEND</code> or <code>GEN</code>.
		 * @param name The name of the DocuSign action.
		 */
		public Action(
			final String type,
			final String name,
			final String label) {

			this.type = type;
			this.name = name;
			this.label = label;
		}
	}

	public static String getFullName(
		final SObjectType type,
		final String namespace,
		final String name) {

		return String.isBlank(namespace)
			? String.format('{0}-{1}', new List<String> {
				String.valueOf(type),
				name
			})
			: String.format('{0}-{1}__{2}', new List<String> {
				String.valueOf(type),
				namespace,
				name
			});
	}

	public Boolean hasSendAction() {
		Boolean result = false;
		if (this.actions != null) {
			for (Action a : this.actions) {
				if (a.name == ACTION_NAME_SEND) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	public Boolean hasGenAction() {
		Boolean result = false;
		if (this.actions != null) {
			for (Action a : this.actions) {
				if (a.name.startsWith(ACTION_NAME_GEN)) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	public Integer compareTo(final Object compareTo) {
		Layout other = (Layout)compareTo;
		if (this.name == other.name) return 0;
		if (this.name > other.name) return 1;
		return -1;
	}
}
