public with sharing class Entity {

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

	public Id id { get; private set; }
	public String type { get; private set; }
	public String label { get; private set; }
	public String name { get; private set; }
	public Entity parent { get; private set; }
	public Boolean isValid { get; private set; }

	public Entity(final Id id) {
		this(id, null, null);
	}

	public Entity(final Id id, final String name, final Entity parent) {
		if (id != null) {
			DescribeSObjectResult d = id.getSobjectType().getDescribe();
			this.id = id;
			this.type = d.getName();
			this.label = d.getLabel();
			this.isValid = true;
		} else {
			this.isValid = false;
		}
		this.name = name;
		this.parent = parent;
	}

	public Boolean equals(Object obj) {
		if (this === obj) return true;
		if (obj == null || !(obj instanceof Entity)) return false;
		Entity other = (Entity)obj;
		return (this.id == other.id);
	}

	override public String toString() {
		String result = String.isNotBlank(this.label) ? this.label : '';
		if (String.isNotBlank(this.name)) {
			if (this.parent != null && String.isNotBlank(this.parent.name)) {
				result += String.format(': {0} {1} {2}', new List<String> {
					this.name, System.Label.ForLabel, this.parent.name
				});
			} else {
				result += ': ' + name;
			}
		}
		return result;
	}

	public Entity copy() {
		return new Entity(this.id, this.name, this.parent.copy());
	}

	public Entity withName(final String name) {
		this.name = name;
		return this;
	}

	public Entity withParent(final Entity parent) {
		this.parent = parent;
		return this;
	}

	public static Boolean isValid(final Entity entity) {
		return entity != null && entity.isValid;
	}

	public static Entity resolve(final Id sObjectId) {
		if (sObjectId == null) throw new DocuSignException(Label.UndefinedId);

		SObjectType t = sObjectId.getSobjectType();
		if (t == null) throw new DocuSignException(Label.InvalidType);
		DescribeSObjectResult d = t.getDescribe();
		if (d == null) throw new DocuSignException(Label.InvalidType);

		return resolve(d.getName(), sObjectId);
	}

	public static Entity resolve(final String sObjectType, final Id sObjectId) {
		if (String.isBlank(sObjectType)) throw new DocuSignException(Label.UndefinedType);
		if (sObjectId == null) throw new DocuSignException(Label.UndefinedId);

		String resolvedType = Application.resolveType(sObjectType);
		Entity result = null;
		for (EntityResolver resolver : RESOLVERS) {
			if (resolver.canResolve(resolvedType)) {
				result = resolver.resolve(resolvedType, sObjectId);
			}
			if (result != null) break;
		}
		return result;
	}
}
