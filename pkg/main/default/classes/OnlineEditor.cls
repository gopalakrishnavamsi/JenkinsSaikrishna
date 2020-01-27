public class OnlineEditor {

	public class Query {
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public String relationship { get; set; }
		@AuraEnabled
		public List<Field> fields { get; set; }
		@AuraEnabled
		public List<Query> children { get; set; }

		public Query(
			final String type,
			final String relationship,
			final List<Field> fields,
			final List<Query> children) {

			this.type = type;
			this.relationship = relationship;
			this.fields = fields == null ? new List<Field>() : fields;
			this.children = children == null ? new List<Query>() : children;
		}
	}

	public class Field {
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public String type { get; set; }

		public Field(
			final String name,
			final String value,
			final String type) {

			this.name = name;
			this.value = value == null ? '' : value;
			this.type = type;
		}
	}

}
