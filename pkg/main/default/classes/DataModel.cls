public with sharing class DataModel {

	// TODO: Move Query.* inner classes here. They are not just used for queries any more.

	public abstract class Relationship implements Comparable {

		public String name { get; private set; }
		public String path { get; private set; }
		public Integer depth { get; private set; }
		public SObjectType relatesTo { get; private set; }
		public Relationship parent { get; private set; }
		public SObjectField idField { get; private set; }

		protected Relationship(
			final String name,
			final String path,
			final Integer depth,
			final SObjectType relatesTo,
			final Relationship parent,
			final SObjectField idField) {

			this.name = name;
			this.path = path;
			this.depth = depth;
			this.relatesTo = relatesTo;
			this.parent = parent;
			this.idField = idField;
		}

		public Integer compareTo(final Object compareTo) {
			if (compareTo == null || !(compareTo instanceof Relationship)) return -1;

			Relationship s = (Relationship)compareTo;
			if (this.depth == s.depth) return 0;
			if (this.depth > s.depth) return 1;
			return -1;
		}
	}

	public class LookupRelationship extends Relationship {

		public LookupRelationship(
			final String name,
			final String path,
			final Integer depth,
			final SObjectType relatesTo,
			final Relationship parent,
			final SObjectField idField) {

			super(name, path, depth, relatesTo, parent, idField);
		}
	}

	public class ChildRelationship extends Relationship {

		public ChildRelationship(
			final String name,
			final String path,
			final Integer depth,
			final SObjectType relatesTo,
			final Relationship parent,
			final SObjectField idField) {

			super(name, path, depth, relatesTo, parent, idField);
		}
	}

	@TestVisible
	private static DataModel.LookupRelationship getLookupRelationship(
		final DescribeSObjectResult objectDescribe,
		final String relationshipName,
		final String path,
		final Integer depth,
		final Relationship parent) {

		if (objectDescribe == null || String.isBlank(relationshipName)) return null;

		DataModel.LookupRelationship result = null;
		for (SObjectField f : objectDescribe.fields.getMap().values()) {
			DescribeFieldResult fd = f.getDescribe();
			if (fd != null
				&& fd.getType() == Schema.DisplayType.REFERENCE
				&& fd.getRelationshipName() == relationshipName) {

				Set<SObjectType> refs = new Set<SObjectType>(fd.getReferenceTo());
				// This can be polymorphic, filter out types we can't deal with (for now)
				refs.remove(Schema.Group.getSObjectType());
				SObjectType t = (SObjectType)Collection.head(new List<SObjectType>(refs));
				if (t != null) {
					result = new LookupRelationship(
						relationshipName,
						path,
						depth,
						t,
						parent,
						f);
					break;
				}
			}
		}
		return result;
	}

	@TestVisible
	private static DataModel.ChildRelationship getChildRelationship(
		final DescribeSObjectResult objectDescribe,
		final String relationshipName,
		final String path,
		final Integer depth,
		final Relationship parent) {

		if (objectDescribe == null || String.isBlank(relationshipName)) return null;

		DataModel.ChildRelationship result = null;
		for (Schema.ChildRelationship cr : objectDescribe.getChildRelationships()) {
			if (cr != null && cr.relationshipName == relationshipName) {
				result = new ChildRelationship(
					cr.getRelationshipName(),
					path,
					depth,
					cr.getChildSObject(),
					parent,
					cr.getField());
				break;
			}
		}
		return result;
	}

	@TestVisible
	private static DataModel.Relationship getRelationship(
		final DescribeSObjectResult objectDescribe,
		final String relationshipName,
		final String path,
		final Integer depth,
		final Relationship parent) {

		if (objectDescribe == null || String.isBlank(relationshipName)) return null;

		DataModel.Relationship result = getLookupRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			parent);
		if (result == null) {
			result = getChildRelationship(
				objectDescribe,
				relationshipName,
				path,
				depth,
				parent);
		}
		return result;
	}

	private static Map<SObjectType, Set<String>> buildAccessMap(
		final SObjectType type,
		final String field,
		final String path,
		final Integer depth,
		final Relationship parent,
		final Map<String, DataModel.Relationship> relationships,
		final Map<SObjectType, Set<String>> accessMap) {

		if (type == null || String.isBlank(field)) return accessMap;

		String fieldName = field;
		if (fieldName.contains('.')) { // Add parent access checks
			String relationshipName = fieldName.substringBefore('.');
			fieldName = fieldName.substringAfter('.');
			String key = path.substringBefore('.' + fieldName).toLowerCase();

			// Cache relationships as iterating over the object is inefficient
			DataModel.Relationship relationship = relationships.get(key);
			if (relationship == null) {
				relationship = getRelationship(
					type.getDescribe(),
					relationshipName,
					path,
					depth,
					parent);
				if (relationship != null) relationships.put(key, relationship);
			}
			if (relationship != null) {
				buildAccessMap(
					relationship.relatesTo,
					fieldName,
					path,
					depth + 1,
					relationship,
					relationships,
					accessMap);
			} else { // invalid relationship, will get flagged during FLS check
				accessMap.put(type, new Set<String> { relationshipName });
			}
		} else if (accessMap.containsKey(type)) {
			accessMap.get(type).add(fieldName);
		} else {
			accessMap.put(type, new Set<String> { fieldName });
		}

		return accessMap;
	}

	public static Map<SObjectType, Set<String>> buildAccessMap(
		final SObjectType type,
		final String path,
		Map<String, DataModel.Relationship> relationships,
		Map<SObjectType, Set<String>> accessMap) {

		if (type == null
			|| String.isBlank(path)
			|| relationships == null
			|| accessMap == null) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (relationships == null) relationships = new Map<String, DataModel.Relationship>();
		if (accessMap == null) accessMap = new Map<SObjectType, Set<String>>();

		return buildAccessMap(
			type,
			path.startsWithIgnoreCase(type + '.') ? path.substringAfter('.') : path,
			path,
			1,
			null,
			relationships,
			accessMap);
	}
}
