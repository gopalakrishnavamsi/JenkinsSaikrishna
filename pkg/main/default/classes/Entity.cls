/**
 * Represents a Salesforce object.
 */
global with sharing class Entity {

	private static final List<EntityResolver> RESOLVERS = new List<EntityResolver>();

	static {
		String rs = AccountSettings__c.getOrgDefaults().EntityResolvers__c;
		if (String.isNotBlank(rs)) {
			for (String r : rs.split(',')) {
				try {
					RESOLVERS.add((EntityResolver)Type.forName(r.trim()).newInstance());
				} catch (Exception ex) {
					LoggerService.getInstance().exception(ex, 'Invalid entity resolver: ' + r.trim());
					throw new DocuSignException(String.format(Label.InvalidEntityResolver_1, new List<String> {
						r.trim()
					}));
				}
			}
		}
	}

	/**
	 * The Salesforce object ID.
	 */
	@AuraEnabled
	global Id id { get; private set; }
	/**
	 * The Salesforce object type.
	 */
	public transient SObjectType type { get; private set; }
	/**
	 * The name of the Salesforce object type.
	 */
	@AuraEnabled
	global String typeName { get; private set; }
	/**
	 * The localized Salesforce object label.
	 */
	@AuraEnabled
	global String label { get; private set; }
	/**
	 * The Salesforce object name.
	 */
	@AuraEnabled
	global String name { get; private set; }
	/**
	 * The Salesforce object parent (e.g. Account for Opportunity).
	 */
	@AuraEnabled
	global Entity parent { get; private set; }
	/**
	 * Whether the entity is valid or not. It is considered valid if the ID is defined.
	 */
	@AuraEnabled
	global Boolean isValid { get; private set; }

	/**
	 * Constructs an entity. This will populate the type and label via SObject describe.
	 *
	 * @param id The Salesforce object ID.
	 */
	global Entity(final Id id) {
		this(id, null, null);
	}

	/**
	 * Constructs an entity. This will populate the type and label via SObject describe.
	 *
	 * @param id The Salesforce object ID.
	 * @param name The Salesforce object name.
	 * @param parent The Salesforce object parent.
	 */
	global Entity(final Id id, final String name, final Entity parent) {
		if (id != null) {
			this.id = id;
			this.type = id.getSobjectType();
			this.typeName = String.valueOf(this.type);
			this.label = this.type.getDescribe().getLabel();
			this.isValid = true;
		} else {
			this.isValid = false;
		}
		this.name = name;
		this.parent = parent;
	}

	/**
	 * Tests whether an entity is equal to an object. The <code>id</code> property is compared for equality.
	 *
	 * @param obj The object to test.
	 *
	 * @return <code>true</code> if <code>obj</code> is an entity and the <code>id</code> properties are equal, <code>false</code> otherwise.
	 */
	public Boolean equals(Object obj) {
		if (this === obj) return true;
		if (obj == null || !(obj instanceof Entity)) return false;
		Entity other = (Entity)obj;
		return (this.id == other.id);
	}

	/**
	 * Creates a display string for the entity based on the label, name, and parent.
	 *
	 * @return The string representation of the entity.
	 */
	override public String toString() {
		String result = String.isNotBlank(this.label) ? this.label : '';
		if (String.isNotBlank(this.name)) {
			if (this.parent != null && String.isNotBlank(this.parent.name)) {
				result += String.format(': {0} {1} {2}', new List<String> {
					this.name, Label.ForLabel, this.parent.name
				});
			} else {
				result += ': ' + name;
			}
		}
		return result;
	}

	/**
	 * Creates a deep copy of the entity.
	 *
	 * @return The copied entity.
	 */
	public Entity copy() {
		return new Entity(
			this.id,
			this.name,
			this.parent == null ? null : this.parent.copy());
	}

	/**
	 * Sets the <code>name</code> property on an entity.
	 *
	 * @param name The Salesforce object name.
	 *
	 * @return The entity with the updated <code>name</code> property.
	 */
	public Entity withName(final String name) {
		this.name = name;
		return this;
	}

	/**
	 * Sets the <code>parent</code> property on an entity.
	 *
	 * @param name The Salesforce object parent entity.
	 *
	 * @return The entity with the updated <code>parent</code> property.
	 */
	public Entity withParent(final Entity parent) {
		this.parent = parent;
		return this;
	}

	/**
	 * Tests whether an entity is valid. It is considered valid if it is non-null and the ID is defined.
	 *
	 * @param entity The entity to test.
	 *
	 * @return <code>true</code> if the entity is valid, <code>false</code> otherwise.
	 */
	public static Boolean isValid(final Entity entity) {
		return entity != null && entity.isValid == true;
	}

	/**
	 * Resolves an entity by type and ID. This operation may involve one or more SOQL queries.
	 *
	 * @param id The Salesforce object ID.
	 *
	 * @return The resolved entity or <code>null</code> if it cannot be resolved.
	 */
	global static Entity resolve(final Id id) {
		if (id == null) throw new DocuSignException(Label.UndefinedId);

		SObjectType type = id.getSobjectType();
		Entity result = null;
		for (EntityResolver resolver : RESOLVERS) {
			if (resolver.canResolve(type)) {
				result = resolver.resolve(id);
			}
			if (result != null) break;
		}
		return result;
	}
}