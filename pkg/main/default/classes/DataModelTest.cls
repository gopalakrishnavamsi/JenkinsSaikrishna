@IsTest
private class DataModelTest {

	@IsTest
	static void test_Relationship_sort() {
		DataModel.Relationship r1 = new DataModel.LookupRelationship(
			'r1',
			null,
			2,
			User.getSObjectType(),
			null,
			null);
		DataModel.Relationship r2 = new DataModel.LookupRelationship(
			'r2',
			null,
			1,
			User.getSObjectType(),
			null,
			null);
		DataModel.Relationship r3 = new DataModel.ChildRelationship(
			'r3',
			null,
			3,
			null,
			null,
			null);
		DataModel.Relationship r4 = new DataModel.LookupRelationship(
			'r4',
			null,
			1,
			User.getSObjectType(),
			null,
			null);
		List<DataModel.Relationship> rs = new List<DataModel.Relationship> { r1, r2, r3, r4 };

		Test.startTest();
		rs.sort();
		Test.stopTest();

		System.assertEquals(new List<DataModel.Relationship> { r2, r4, r1, r3 }, rs);
	}

	@IsTest
	static void test_getLookupRelationship_undefined_arguments() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Envelope__r';
		String path = Application.namespacePrefix + 'Recipient__c.' + Application.namespacePrefix + 'Envelope__r';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getLookupRelationship(
			null,
			relationshipName,
			path,
			depth,
			null));
		System.assertEquals(null, DataModel.getLookupRelationship(
			objectDescribe,
			' ',
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getLookupRelationship_invalid() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Invalid';
		String path = Application.namespacePrefix + 'Invalid';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getLookupRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getLookupRelationship_valid() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Envelope__r';
		String path = Application.namespacePrefix + 'Recipient__c.' + Application.namespacePrefix + 'Envelope__r';
		Integer depth = 1;

		Test.startTest();
		DataModel.LookupRelationship result = DataModel.getLookupRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(relationshipName, result.name);
		System.assertEquals(path, result.path);
		System.assertEquals(depth, result.depth);
		System.assertEquals(Envelope__c.getSObjectType(), result.relatesTo);
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', String.valueOf(result.idField));
	}

	@IsTest
	static void test_getChildRelationship_undefined_arguments() {
		DescribeSObjectResult objectDescribe = Envelope__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Recipients__r';
		String path = Application.namespacePrefix + 'Envelope__c.' + Application.namespacePrefix + 'Recipients__r';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getChildRelationship(
			null,
			relationshipName,
			path,
			depth,
			null));
		System.assertEquals(null, DataModel.getChildRelationship(
			objectDescribe,
			' ',
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getChildRelationship_invalid() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Invalid';
		String path = Application.namespacePrefix + 'Invalid';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getChildRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getChildRelationship_valid() {
		DescribeSObjectResult objectDescribe = Envelope__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Recipients__r';
		String path = Application.namespacePrefix + 'Envelope__c.' + Application.namespacePrefix + 'Recipients__r';
		Integer depth = 1;

		Test.startTest();
		DataModel.ChildRelationship result = DataModel.getChildRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(relationshipName, result.name);
		System.assertEquals(path, result.path);
		System.assertEquals(depth, result.depth);
		System.assertEquals(Recipient__c.getSObjectType(), result.relatesTo);
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', String.valueOf(result.idField));
	}

	@IsTest
	static void test_getRelationship_undefined_arguments() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Envelope__r';
		String path = Application.namespacePrefix + 'Recipient__c.' + Application.namespacePrefix + 'Envelope__r';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getRelationship(
			null,
			relationshipName,
			path,
			depth,
			null));
		System.assertEquals(null, DataModel.getRelationship(
			objectDescribe,
			' ',
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getRelationship_invalid() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Invalid';
		String path = Application.namespacePrefix + 'Invalid';
		Integer depth = 1;

		Test.startTest();
		System.assertEquals(null, DataModel.getRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null));
		Test.stopTest();
	}

	@IsTest
	static void test_getRelationship_lookup() {
		DescribeSObjectResult objectDescribe = Recipient__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Envelope__r';
		String path = Application.namespacePrefix + 'Recipient__c.' + Application.namespacePrefix + 'Envelope__r';
		Integer depth = 1;

		Test.startTest();
		DataModel.Relationship result = DataModel.getLookupRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result instanceof DataModel.LookupRelationship);
		System.assertEquals(relationshipName, result.name);
		System.assertEquals(path, result.path);
		System.assertEquals(depth, result.depth);
		System.assertEquals(Envelope__c.getSObjectType(), result.relatesTo);
	}

	@IsTest
	static void test_getRelationship_child() {
		DescribeSObjectResult objectDescribe = Envelope__c.getSObjectType().getDescribe();
		String relationshipName = Application.namespacePrefix + 'Recipients__r';
		String path = Application.namespacePrefix + 'Envelope__c.' + Application.namespacePrefix + 'Recipients__r';
		Integer depth = 1;

		Test.startTest();
		DataModel.Relationship result = DataModel.getRelationship(
			objectDescribe,
			relationshipName,
			path,
			depth,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result instanceof DataModel.ChildRelationship);
		System.assertEquals(relationshipName, result.name);
		System.assertEquals(path, result.path);
		System.assertEquals(depth, result.depth);
		System.assertEquals(Recipient__c.getSObjectType(), result.relatesTo);
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', String.valueOf(result.idField));
	}

	@IsTest
	static void test_buildAccessMap_undefined_arguments() {
		SObjectType type = Envelope__c.getSObjectType();
		String field = String.valueOf(type) + '.' + Application.namespacePrefix + 'Recipients__r.CreatedBy.Name';
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship>();
		Map<SObjectType, Set<String>> accessMap = new Map<SObjectType, Set<String>>();

		Test.startTest();
		try {
			DataModel.buildAccessMap(
				null,
				field,
				relationships,
				accessMap);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			DataModel.buildAccessMap(
				type,
				'\r ',
				relationships,
				accessMap);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			DataModel.buildAccessMap(
				type,
				field,
				null,
				accessMap);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			DataModel.buildAccessMap(
				type,
				field,
				relationships,
				null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_buildAccessMap_invalid() {
		SObjectType type = Envelope__c.getSObjectType();
		String field = String.valueOf(type) + '.' + Application.namespacePrefix + 'Recipients__r.Invalid.Name';
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship>();
		Map<SObjectType, Set<String>> accessMap = new Map<SObjectType, Set<String>>();

		Test.startTest();
		Map<SObjectType, Set<String>> result = DataModel.buildAccessMap(
			type,
			field,
			relationships,
			accessMap);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<SObjectType> { Recipient__c.getSObjectType() }, result.keySet());
		System.assertEquals(new Set<String> { 'Invalid' }, result.get(Recipient__c.getSObjectType()));
	}

	@IsTest
	static void test_buildAccessMap_new() {
		SObjectType type = Envelope__c.getSObjectType();
		String field = String.valueOf(type) + '.' + Application.namespacePrefix + 'Recipients__r.CreatedBy.Name';
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship>();
		Map<SObjectType, Set<String>> accessMap = new Map<SObjectType, Set<String>>();

		Test.startTest();
		Map<SObjectType, Set<String>> result = DataModel.buildAccessMap(
			type,
			field,
			relationships,
			accessMap);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<SObjectType> { User.getSObjectType() }, result.keySet());
		System.assertEquals(new Set<String> { 'Name' }, result.get(User.getSObjectType()));

		System.assertEquals(new Set<String> {
			String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase() + 'recipients__r',
			String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase() + 'recipients__r.createdby'
		}, relationships.keySet());

		DataModel.Relationship r = relationships.get(String.valueOf(type).toLowerCase() + '.'
			+ Application.namespacePrefix.toLowerCase() + 'recipients__r');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.ChildRelationship);
		System.assertEquals(Application.namespacePrefix + 'Recipients__r', r.name);
		System.assertEquals(field, r.path);
		System.assertEquals(1, r.depth);
		System.assertEquals(Recipient__c.getSObjectType(), r.relatesTo);
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', String.valueOf(r.idField));

		r = relationships.get(String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase()
			+ 'recipients__r.createdby');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.LookupRelationship);
		System.assertEquals('CreatedBy', r.name);
		System.assertEquals(field, r.path);
		System.assertEquals(2, r.depth);
		System.assertEquals(User.getSObjectType(), r.relatesTo);
	}

	@IsTest
	static void test_buildAccessMap_existing() {
		SObjectType type = Envelope__c.getSObjectType();
		String field = String.valueOf(type) + '.' + Application.namespacePrefix + 'Recipients__r.CreatedBy.Name';
		Map<String, DataModel.Relationship> relationships = new Map<String, DataModel.Relationship> {
			String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase()
				+ 'recipients__r' => new DataModel.ChildRelationship(
				Application.namespacePrefix + 'Recipients__r',
				field,
				1,
				Recipient__c.getSObjectType(),
				null,
				Recipient__c.getSObjectType().getDescribe().fields.getMap()
					.get(Application.namespacePrefix + 'Envelope__c'))
		};
		Map<SObjectType, Set<String>> accessMap = new Map<SObjectType, Set<String>> {
			User.getSObjectType() => new Set<String> { 'Email', 'Phone' }
		};

		Test.startTest();
		Map<SObjectType, Set<String>> result = DataModel.buildAccessMap(
			type,
			field,
			relationships,
			accessMap);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<SObjectType> { User.getSObjectType() }, result.keySet());
		System.assertEquals(new Set<String> { 'Email', 'Phone', 'Name' }, result.get(User.getSObjectType()));

		System.assertEquals(new Set<String> {
			String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase() + 'recipients__r',
			String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase()
				+ 'recipients__r.createdby'
		}, relationships.keySet());

		DataModel.Relationship r = relationships.get(String.valueOf(type).toLowerCase() + '.'
			+ Application.namespacePrefix.toLowerCase() + 'recipients__r');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.ChildRelationship);
		System.assertEquals(Application.namespacePrefix + 'Recipients__r', r.name);
		System.assertEquals(field, r.path);
		System.assertEquals(1, r.depth);
		System.assertEquals(Recipient__c.getSObjectType(), r.relatesTo);
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', String.valueOf(r.idField));

		r = relationships.get(String.valueOf(type).toLowerCase() + '.' + Application.namespacePrefix.toLowerCase()
			+ 'recipients__r.createdby');
		System.assertNotEquals(null, r);
		System.assert(r instanceof DataModel.LookupRelationship);
		System.assertEquals('CreatedBy', r.name);
		System.assertEquals(field, r.path);
		System.assertEquals(2, r.depth);
		System.assertEquals(User.getSObjectType(), r.relatesTo);
	}
}
