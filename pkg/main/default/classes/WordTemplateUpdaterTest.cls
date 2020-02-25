@IsTest
private class WordTemplateUpdaterTest {

	@IsTest
	static void test_convertFormat_null() {
		WordTemplateUpdater.FieldV1 f1 = new WordTemplateUpdater.FieldV1();
		f1.dataType = 'PICKLIST';
		f1.currencyFormat = 'cf';
		f1.dateFormat = 'df';

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.convertFormat(null));
		System.assertEquals(null, WordTemplateUpdater.convertFormat(f1));
		Test.stopTest();
	}

	@IsTest
	static void test_convertFormat_currency() {
		WordTemplateUpdater.FieldV1 f1 = new WordTemplateUpdater.FieldV1();
		f1.dataType = 'CURRENCY';
		f1.currencyFormat = 'cf';
		f1.dateFormat = 'df';
		WordTemplateUpdater.FieldV1 f2 = new WordTemplateUpdater.FieldV1();
		f2.dataType = 'CURRENCY';
		f2.currencyFormat = 'default';
		f2.dateFormat = 'df';

		Test.startTest();
		System.assertEquals('cf', WordTemplateUpdater.convertFormat(f1));
		System.assertEquals(null, WordTemplateUpdater.convertFormat(f2));
		Test.stopTest();
	}

	@IsTest
	static void test_convertFormat_date() {
		WordTemplateUpdater.FieldV1 f1 = new WordTemplateUpdater.FieldV1();
		f1.dataType = 'DATE';
		f1.currencyFormat = 'cf';
		f1.dateFormat = 'df';
		WordTemplateUpdater.FieldV1 f2 = new WordTemplateUpdater.FieldV1();
		f2.dataType = 'DATE';
		f2.currencyFormat = 'cf';
		f2.dateFormat = 'default';
		WordTemplateUpdater.FieldV1 f3 = new WordTemplateUpdater.FieldV1();
		f3.dataType = 'DATETIME';
		f3.currencyFormat = 'cf';
		f3.dateFormat = 'df';
		WordTemplateUpdater.FieldV1 f4 = new WordTemplateUpdater.FieldV1();
		f4.apiName = 'CurrentDate';
		f4.dataType = '';
		f4.currencyFormat = 'cf';
		f4.dateFormat = 'df';
		WordTemplateUpdater.FieldV1 f5 = new WordTemplateUpdater.FieldV1();
		f5.dataType = 'TIME';
		f5.currencyFormat = 'cf';
		f5.dateFormat = 'df';

		Test.startTest();
		System.assertEquals('df', WordTemplateUpdater.convertFormat(f1));
		System.assertEquals(null, WordTemplateUpdater.convertFormat(f2));
		System.assertEquals('df', WordTemplateUpdater.convertFormat(f3));
		System.assertEquals('df', WordTemplateUpdater.convertFormat(f4));
		System.assertEquals('df', WordTemplateUpdater.convertFormat(f5));

		Test.stopTest();
	}

	@IsTest
	static void test_getLookupField_undefined_args() {
		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.getLookupField(null, 'Account'));
		System.assertEquals(null, WordTemplateUpdater.getLookupField(Opportunity.getSObjectType().getDescribe(), null));
		System.assertEquals(null, WordTemplateUpdater.getLookupField(Opportunity.getSObjectType().getDescribe(), '  '));
		Test.stopTest();
	}

	@IsTest
	static void test_getLookupField_success() {
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		String rn = 'Account';

		Test.startTest();
		WordTemplateUpdater.Relationship result = WordTemplateUpdater.getLookupField(objDesc, rn);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(rn, result.name);
		System.assertEquals(objDesc.fields.getMap().get('AccountId').getDescribe().getLabel(), result.label);
		System.assertEquals(Schema.Account.getSObjectType().getDescribe().getName(), result.relatesTo);
		System.assertEquals('AccountId', result.parentIdField);
	}

	@IsTest
	static void test_getLookupField_polymorphic() {
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		String rn = 'Owner';

		Test.startTest();
		WordTemplateUpdater.Relationship result = WordTemplateUpdater.getLookupField(objDesc, rn);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(rn, result.name);
		System.assertEquals(objDesc.fields.getMap().get('OwnerId').getDescribe().getLabel(), result.label);
		System.assertEquals(Schema.User.getSObjectType().getDescribe().getName(), result.relatesTo);
		System.assertEquals('OwnerId', result.parentIdField);
	}
	
	@IsTest
	static void test_getChildRelationship_undefined_args() {
		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.getChildRelationship(null, 'Account'));
		System.assertEquals(null, WordTemplateUpdater.getChildRelationship(Opportunity.getSObjectType().getDescribe(), null));
		System.assertEquals(null, WordTemplateUpdater.getChildRelationship(Opportunity.getSObjectType().getDescribe(), '  '));
		Test.stopTest();
	}

	@IsTest
	static void test_getChildRelationships_success() {
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		String rn = 'OpportunityLineItems';

		Test.startTest();
		WordTemplateUpdater.Relationship result = WordTemplateUpdater.getChildRelationship(objDesc, rn);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(rn, result.name);
		System.assertEquals(OpportunityLineItem.getSObjectType().getDescribe().fields.getMap().get('OpportunityId').getDescribe().getLabel(), result.label);
		System.assertEquals(Schema.OpportunityLineItem.getSObjectType().getDescribe().getName(), result.relatesTo);
		System.assertEquals('OpportunityId', result.parentIdField);
	}

	@IsTest
	static void test_convert_field_undefined_args() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'Opportunity',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.convert(null, objDesc, root, lookups, children));
		System.assertEquals(null, WordTemplateUpdater.convert(v1, null, root, lookups, children));
		System.assertEquals(null, WordTemplateUpdater.convert(v1, objDesc, null, lookups, children));
		System.assertEquals(null, WordTemplateUpdater.convert(v1, objDesc, root, null, children));
		System.assertEquals(null, WordTemplateUpdater.convert(v1, objDesc, root, lookups, null));
		Test.stopTest();
	}

	@IsTest
	static void test_convert_field_simple() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		v1.apiName = 'Name';
		v1.dataType = 'STRING';
		v1.isConditional = false;
		v1.dateFormat = 'df';
		v1.currencyFormat = 'cf';
		v1.decimalPlaces = 2;
		v1.label = 'Opportunity Name';
		v1.matchType = 'mt';
		v1.conditionalValue = 'cv';
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		Gen.FieldMapping result = WordTemplateUpdater.convert(v1, objDesc, root, lookups, children);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isRoot);
		System.assertEquals('ROOT', result.type);
		System.assertEquals(1, result.depth);
		System.assertEquals('Opportunity', result.key);
		System.assertEquals(new List<String>(), result.path);
		System.assertEquals(1, Collection.size(result.fields));
		System.assertNotEquals(null, result.fields[0]);
		System.assertEquals('STRING', result.fields[0].type);
		System.assertEquals('Name', result.fields[0].name);
		System.assertEquals('Opportunity Name', result.fields[0].label);
		System.assertEquals(null, result.fields[0].relatesTo);
		System.assertEquals(null, result.fields[0].relationship);
		System.assertEquals(null, result.fields[0].parentIdField);
		System.assertEquals(null, result.fields[0].format);
		System.assertEquals(2, result.fields[0].scale);
		System.assertEquals(false, result.fields[0].isChildRelation);
		System.assertEquals(false, result.fields[0].isConditional);
		System.assertEquals('mt', result.fields[0].matchType);
		System.assertEquals('cv', result.fields[0].conditionalValue);
	}

	@IsTest
	static void test_convert_field_CurrentDate() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		v1.apiName = 'CurrentDate';
		v1.dataType = '';
		v1.isConditional = false;
		v1.dateFormat = 'df';
		v1.currencyFormat = 'cf';
		v1.decimalPlaces = 2;
		v1.label = 'Current Date';
		v1.matchType = 'mt';
		v1.conditionalValue = 'cv';
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		Gen.FieldMapping result = WordTemplateUpdater.convert(v1, objDesc, root, lookups, children);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isRoot);
		System.assertEquals('ROOT', result.type);
		System.assertEquals(1, result.depth);
		System.assertEquals('Opportunity', result.key);
		System.assertEquals(new List<String>(), result.path);
		System.assertEquals(1, Collection.size(result.fields));
		System.assertNotEquals(null, result.fields[0]);
		System.assertEquals('DATE', result.fields[0].type);
		System.assertEquals('CurrentDate', result.fields[0].name);
		System.assertEquals('Current Date', result.fields[0].label);
		System.assertEquals(null, result.fields[0].relatesTo);
		System.assertEquals(null, result.fields[0].relationship);
		System.assertEquals(null, result.fields[0].parentIdField);
		System.assertEquals('df', result.fields[0].format);
		System.assertEquals(2, result.fields[0].scale);
		System.assertEquals(false, result.fields[0].isChildRelation);
		System.assertEquals(false, result.fields[0].isConditional);
		System.assertEquals('mt', result.fields[0].matchType);
		System.assertEquals('cv', result.fields[0].conditionalValue);
	}

	@IsTest
	static void test_convert_field_lookup_invalid() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		v1.apiName = 'Invalid.Email';
		v1.dataType = 'EMAIL';
		v1.isConditional = false;
		v1.dateFormat = 'df';
		v1.currencyFormat = 'cf';
		v1.decimalPlaces = 2;
		v1.label = 'Email';
		v1.matchType = 'mt';
		v1.conditionalValue = 'cv';
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.convert(v1, objDesc, root, lookups, children));
		Test.stopTest();
	}

	@IsTest
	static void test_convert_field_lookup_valid() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		v1.apiName = 'Owner.Email';
		v1.dataType = 'EMAIL';
		v1.isConditional = false;
		v1.dateFormat = 'df';
		v1.currencyFormat = 'cf';
		v1.decimalPlaces = 2;
		v1.label = 'Email';
		v1.matchType = 'mt';
		v1.conditionalValue = 'cv';
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		Gen.FieldMapping result = WordTemplateUpdater.convert(v1, objDesc, root, lookups, children);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isRoot);
		System.assertEquals('REFERENCE', result.type);
		System.assertEquals(2, result.depth);
		System.assertEquals('Owner', result.key);
		System.assertEquals(new List<String> { 'Owner' }, result.path);
		System.assertEquals(1, Collection.size(result.fields));
		System.assertNotEquals(null, result.fields[0]);
		System.assertEquals('EMAIL', result.fields[0].type);
		System.assertEquals('Email', result.fields[0].name);
		System.assertEquals('Email', result.fields[0].label);
		System.assertEquals(null, result.fields[0].relatesTo);
		System.assertEquals(null, result.fields[0].relationship);
		System.assertEquals(null, result.fields[0].parentIdField);
		System.assertEquals(null, result.fields[0].format);
		System.assertEquals(2, result.fields[0].scale);
		System.assertEquals(false, result.fields[0].isChildRelation);
		System.assertEquals(false, result.fields[0].isConditional);
		System.assertEquals('mt', result.fields[0].matchType);
		System.assertEquals('cv', result.fields[0].conditionalValue);

		System.assertEquals(1, Collection.size(root.fields));
		System.assertNotEquals(null, root.fields[0]);
		System.assertEquals('REFERENCE', root.fields[0].type);
		System.assertEquals('Owner', root.fields[0].name);
		System.assert(String.isNotBlank(root.fields[0].label));
		System.assertEquals('User', root.fields[0].relatesTo);
		System.assertEquals('Owner', root.fields[0].relationship);
		System.assertEquals('OwnerId', root.fields[0].parentIdField);
		System.assertEquals(null, root.fields[0].format);
		System.assertEquals(null, root.fields[0].scale);
		System.assertEquals(false, root.fields[0].isChildRelation);
		System.assertEquals(false, root.fields[0].isConditional);
		System.assertEquals(null, root.fields[0].matchType);
		System.assertEquals(null, root.fields[0].conditionalValue);

		System.assertEquals(result, lookups.get('Owner'));
	}

	@IsTest
	static void test_convert_field_child_relationship() {
		WordTemplateUpdater.FieldV1 v1 = new WordTemplateUpdater.FieldV1();
		v1.apiName = 'OpportunityLineItem';
		v1.dataType = '';
		v1.isConditional = false;
		v1.dateFormat = 'df';
		v1.currencyFormat = 'cf';
		v1.decimalPlaces = 2;
		v1.label = 'OpportunityLineItems';
		v1.matchType = 'mt';
		v1.conditionalValue = 'cv';
		WordTemplateUpdater.FieldV1 v1c1 = new WordTemplateUpdater.FieldV1();
		v1c1.apiName = 'Name';
		v1c1.dataType = 'STRING';
		v1c1.isConditional = false;
		v1c1.dateFormat = 'df';
		v1c1.currencyFormat = 'cf';
		v1c1.decimalPlaces = 2;
		v1c1.label = 'Opportunity Product Name';
		v1c1.matchType = 'mt';
		v1c1.conditionalValue = 'cv';
		WordTemplateUpdater.FieldV1 v1c2 = new WordTemplateUpdater.FieldV1();
		v1c2.apiName = 'ProductCode';
		v1c2.dataType = 'STRING';
		v1c2.isConditional = false;
		v1c2.dateFormat = 'df';
		v1c2.currencyFormat = 'cf';
		v1c2.decimalPlaces = 2;
		v1c2.label = 'Product Code';
		v1c2.matchType = 'mt';
		v1c2.conditionalValue = 'cv';
		v1.childFieldMappings = new List<WordTemplateUpdater.FieldV1> { v1c1, v1c2 };
		DescribeSObjectResult objDesc = Opportunity.getSObjectType().getDescribe();
		Gen.FieldMapping root = new Gen.FieldMapping(
			'ROOT',
			1,
			'Opportunity',
			null,
			null);
		Map<String, Gen.FieldMapping> lookups = new Map<String, Gen.FieldMapping>();
		Map<String, WordTemplateUpdater.Relationship> children = new Map<String, WordTemplateUpdater.Relationship>();

		Test.startTest();
		Gen.FieldMapping result = WordTemplateUpdater.convert(v1, objDesc, root, lookups, children);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.isRoot);
		System.assertEquals('CHILD_RELATIONSHIP', result.type);
		System.assertEquals(2, result.depth);
		System.assertEquals('OpportunityLineItem', result.key);
		System.assertEquals(new List<String> { 'OpportunityLineItem' }, result.path);
		System.assertEquals(2, Collection.size(result.fields));
		System.assertNotEquals(null, result.fields[0]);
		System.assertEquals('STRING', result.fields[0].type);
		System.assertEquals('Name', result.fields[0].name);
		System.assertEquals('Opportunity Product Name', result.fields[0].label);
		System.assertEquals(null, result.fields[0].relatesTo);
		System.assertEquals(null, result.fields[0].relationship);
		System.assertEquals(null, result.fields[0].parentIdField);
		System.assertEquals(null, result.fields[0].format);
		System.assertEquals(2, result.fields[0].scale);
		System.assertEquals(false, result.fields[0].isChildRelation);
		System.assertEquals(false, result.fields[0].isConditional);
		System.assertEquals('mt', result.fields[0].matchType);
		System.assertEquals('cv', result.fields[0].conditionalValue);
		System.assertNotEquals(null, result.fields[1]);
		System.assertEquals('STRING', result.fields[1].type);
		System.assertEquals('ProductCode', result.fields[1].name);
		System.assertEquals('Product Code', result.fields[1].label);
		System.assertEquals(null, result.fields[1].relatesTo);
		System.assertEquals(null, result.fields[1].relationship);
		System.assertEquals(null, result.fields[1].parentIdField);
		System.assertEquals(null, result.fields[1].format);
		System.assertEquals(2, result.fields[1].scale);
		System.assertEquals(false, result.fields[1].isChildRelation);
		System.assertEquals(false, result.fields[1].isConditional);
		System.assertEquals('mt', result.fields[1].matchType);
		System.assertEquals('cv', result.fields[1].conditionalValue);

		System.assertEquals(1, Collection.size(root.fields));
		System.assertNotEquals(null, root.fields[0]);
		System.assertEquals('CHILD_RELATIONSHIP', root.fields[0].type);
		System.assertEquals('OpportunityLineItem', root.fields[0].name);
		System.assert(String.isNotBlank(root.fields[0].label));
		System.assertEquals('OpportunityLineItem', root.fields[0].relatesTo);
		System.assertEquals('OpportunityLineItems', root.fields[0].relationship);
		System.assertEquals('OpportunityId', root.fields[0].parentIdField);
		System.assertEquals(null, root.fields[0].format);
		System.assertEquals(null, root.fields[0].scale);
		System.assertEquals(true, root.fields[0].isChildRelation);
		System.assertEquals(false, root.fields[0].isConditional);
		System.assertEquals(null, root.fields[0].matchType);
		System.assertEquals(null, root.fields[0].conditionalValue);

		System.assertEquals(new Set<String> { 'OpportunityLineItem' }, children.keySet());
	}

	@IsTest
	static void test_convert_object_invalid_args() {
		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.convert(null));
		Test.stopTest();
	}

	@IsTest
	static void test_convert_object_success() {
		WordTemplateUpdater.ObjectV1 v1 = new WordTemplateUpdater.ObjectV1();
		v1.apiName = 'Opportunity';
		v1.label = 'Opportunity';
		WordTemplateUpdater.FieldV1 v1f1 = new WordTemplateUpdater.FieldV1();
		v1f1.apiName = 'Name';
		v1f1.dataType = 'STRING';
		v1f1.isConditional = false;
		v1f1.dateFormat = 'df';
		v1f1.currencyFormat = 'cf';
		v1f1.decimalPlaces = 2;
		v1f1.label = 'Opportunity Name';
		v1f1.matchType = 'mt';
		v1f1.conditionalValue = 'cv';
		v1.fieldMappings = new List<WordTemplateUpdater.FieldV1> { v1f1 };

		Test.startTest();
		Gen.ObjectMapping result = WordTemplateUpdater.convert(v1);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.version);
		System.assertEquals(v1.apiName, result.name);
		System.assertEquals(v1.label, result.label);
		System.assertEquals(1, Collection.size(result.fieldMappings));
	}

	@IsTest
	static void test_updateTemplate_undefined_args() {
		GenTemplate__c t = new GenTemplate__c();

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.updateTemplate(null));
		GenTemplate__c result = WordTemplateUpdater.updateTemplate(t);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Gen.TYPE_WORD, result.TemplateType__c);
		System.assertEquals(null, result.ObjectMappings__c);
	}

	static final String v1json = '[{"objLabel":"Opportunity","label":"Opportunity","isPrimary":true,"fieldMappings":[{"matchType":null,"label":"Current Date","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":null,"currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[],"apiName":"CurrentDate"},{"matchType":null,"label":"Amount","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"CURRENCY","currencyFormat":"symbolNoDecimals","conditionalValue":null,"childFieldMappings":[],"apiName":"Amount"},{"matchType":null,"label":"Close Date","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"DATE","currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[],"apiName":"CloseDate"},{"matchType":null,"label":"Email","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"EMAIL","currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[],"apiName":"Owner.Email"},{"matchType":null,"label":"Account Name","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"STRING","currencyFormat":"symbol","conditionalValue":"","childFieldMappings":[],"apiName":"Account.Name"},{"matchType":null,"label":"Name","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"STRING","currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[],"apiName":"Campaign.Name"},{"matchType":null,"label":"OpportunityContactRoles","isConditional":false,"isChildRelation":true,"dateFormat":"default","dataType":"","currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[{"matchType":null,"label":"Primary","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"BOOLEAN","currencyFormat":"symbol","conditionalValue":null,"apiName":"IsPrimary"},{"matchType":null,"label":"Role","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"PICKLIST","currencyFormat":"symbol","conditionalValue":null,"apiName":"Role"}],"apiName":"OpportunityContactRole"},{"matchType":null,"label":"OpportunityLineItems","isConditional":false,"isChildRelation":true,"dateFormat":"default","dataType":"","currencyFormat":"symbol","conditionalValue":null,"childFieldMappings":[{"matchType":null,"label":"Opportunity Product Name","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"STRING","currencyFormat":"symbol","conditionalValue":null,"apiName":"Name"},{"matchType":null,"label":"Product Code","isConditional":false,"isChildRelation":false,"dateFormat":"default","dataType":"STRING","currencyFormat":"symbol","conditionalValue":null,"apiName":"ProductCode"}],"apiName":"OpportunityLineItem"}],"apiName":"Opportunity"}]';
	static final String v2json = '{"version":2,"name":"Opportunity","label":"Opportunity","fieldMappings":[{"type":"ROOT","path":[],"key":"Opportunity","fields":[{"type":"DATE","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"CurrentDate","matchType":null,"label":"Current Date","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"CURRENCY","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Amount","matchType":null,"label":"Amount","isConditional":false,"isChildRelation":false,"format":"symbolNoDecimals","conditionalValue":null},{"type":"DATE","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"CloseDate","matchType":null,"label":"Close Date","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"REFERENCE","scale":null,"relationship":"Owner","relatesTo":"User","parentIdField":"OwnerId","name":"Owner","matchType":null,"label":"Owner ID","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"REFERENCE","scale":null,"relationship":"Account","relatesTo":"Account","parentIdField":"AccountId","name":"Account","matchType":null,"label":"Account ID","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"REFERENCE","scale":null,"relationship":"Campaign","relatesTo":"Campaign","parentIdField":"CampaignId","name":"Campaign","matchType":null,"label":"Campaign ID","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"CHILD_RELATIONSHIP","scale":null,"relationship":"OpportunityContactRoles","relatesTo":"OpportunityContactRole","parentIdField":"OpportunityId","name":"OpportunityContactRole","matchType":null,"label":"Opportunity ID","isConditional":false,"isChildRelation":true,"format":null,"conditionalValue":null},{"type":"CHILD_RELATIONSHIP","scale":null,"relationship":"OpportunityLineItems","relatesTo":"OpportunityLineItem","parentIdField":"OpportunityId","name":"OpportunityLineItem","matchType":null,"label":"Opportunity ID","isConditional":false,"isChildRelation":true,"format":null,"conditionalValue":null}],"depth":1},{"type":"REFERENCE","path":["Owner"],"key":"Owner","fields":[{"type":"EMAIL","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Email","matchType":null,"label":"Email","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":2},{"type":"REFERENCE","path":["Account"],"key":"Account","fields":[{"type":"STRING","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Name","matchType":null,"label":"Account Name","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":""}],"depth":2},{"type":"REFERENCE","path":["Campaign"],"key":"Campaign","fields":[{"type":"STRING","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Name","matchType":null,"label":"Name","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":2},{"type":"CHILD_RELATIONSHIP","path":["OpportunityContactRole"],"key":"OpportunityContactRole","fields":[{"type":"BOOLEAN","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"IsPrimary","matchType":null,"label":"Primary","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"PICKLIST","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Role","matchType":null,"label":"Role","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":2},{"type":"CHILD_RELATIONSHIP","path":["OpportunityLineItem"],"key":"OpportunityLineItem","fields":[{"type":"STRING","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"Name","matchType":null,"label":"Opportunity Product Name","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null},{"type":"STRING","scale":null,"relationship":null,"relatesTo":null,"parentIdField":null,"name":"ProductCode","matchType":null,"label":"Product Code","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":2}]}';

	@IsTest
	static void test_updateTemplate_v1() {
		GenTemplate__c t = new GenTemplate__c(ObjectMappings__c = v1json);

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.updateTemplate(null));
		GenTemplate__c result = WordTemplateUpdater.updateTemplate(t);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Gen.TYPE_WORD, result.TemplateType__c);
		System.assertEquals(v2json, result.ObjectMappings__c);
	}

	@IsTest
	static void test_updateTemplate_v2() {
		GenTemplate__c t = new GenTemplate__c(ObjectMappings__c = v2json);

		Test.startTest();
		System.assertEquals(null, WordTemplateUpdater.updateTemplate(null));
		GenTemplate__c result = WordTemplateUpdater.updateTemplate(t);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(Gen.TYPE_WORD, result.TemplateType__c);
		System.assertEquals(v2json, result.ObjectMappings__c);
	}

	@IsTest
	static void test_UpdateResult_toString() {
		WordTemplateUpdater.UpdateResult ur1 = new WordTemplateUpdater.UpdateResult(5, null);
		WordTemplateUpdater.UpdateResult ur2 = new WordTemplateUpdater.UpdateResult(5, UserInfo.getUserId());

		Test.startTest();
		String result1 = ur1.toString();
		String result2 = ur2.toString();
		Test.stopTest();

		System.assertEquals(String.format(Label.UpgradeTemplatesComplete_1, new List<Object> { 5 }), result1);
		System.assertEquals(String.format(Label.UpgradeTemplatesQueued_2, new List<Object> { 5, UserInfo.getUserId() }), result2);
	}

	static List<GenTemplate__c> createTemplates(String type, Integer num) {
		List<GenTemplate__c> result = new List<GenTemplate__c>();
		for (Integer i = 0; i < num; i++) {
			result.add(new GenTemplate__c(
				TemplateType__c = type,
				ObjectMappings__c = v1json));
		}
		insert result;
		return result;
	}

	@IsTest
	static void test_updateTemplates_unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			try {
				WordTemplateUpdater.updateTemplates();
			} catch (UnauthorizedException ex) {
				System.assertEquals(UnauthorizedException.AccessRequirement.SecurityPermission, ex.requirement);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplates_batch() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			WordTemplateUpdater.batchLimit = 4;
			List<GenTemplate__c> templates = createTemplates(null, 5);
			templates.addAll(createTemplates(Gen.TYPE_ONLINE, 2));

			Test.startTest();
			// Job is only scheduled once
			WordTemplateUpdater.UpdateResult result1 = WordTemplateUpdater.updateTemplates();
			WordTemplateUpdater.UpdateResult result2 = WordTemplateUpdater.updateTemplates();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(String.isNotBlank(result1.jobId));
			System.assertEquals(5, result1.templateCount);
			System.assertNotEquals(null, result2);
			System.assertEquals(result1.jobId, result2.jobId);
			System.assertEquals(5, result2.templateCount);

			AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :result1.jobId LIMIT 1];
			System.assertNotEquals(null, job);
			System.assertEquals('Completed', job.Status);

			templates = [SELECT Id, TemplateType__c, ObjectMappings__c FROM GenTemplate__c WHERE TemplateType__c = :Gen.TYPE_WORD LIMIT 10];
			System.assertEquals(5, Collection.size(templates));
			for (GenTemplate__c t : templates) {
				System.assertNotEquals(null, t);
				System.assertEquals(v2json, t.ObjectMappings__c);
			}

			templates = [SELECT Id, TemplateType__c, ObjectMappings__c FROM GenTemplate__c WHERE TemplateType__c != :Gen.TYPE_WORD LIMIT 10];
			System.assertEquals(2, Collection.size(templates));
			for (GenTemplate__c t : templates) {
				System.assertNotEquals(null, t);
				System.assertEquals(Gen.TYPE_ONLINE, t.TemplateType__c);
				System.assertEquals(v1json, t.ObjectMappings__c);
			}

			System.assert(GenMigrationSettings__c.getOrgDefaults().WordTemplatesUpdated__c);
		}
	}

	@IsTest
	static void test_updateTemplates_immediate() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			List<GenTemplate__c> templates = createTemplates(null, 5);
			templates.addAll(createTemplates(Gen.TYPE_ONLINE, 2));

			Test.startTest();
			WordTemplateUpdater.UpdateResult result = WordTemplateUpdater.updateTemplates();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.jobId);
			System.assertEquals(5, result.templateCount);

			templates = [SELECT Id, TemplateType__c, ObjectMappings__c FROM GenTemplate__c WHERE TemplateType__c = :Gen.TYPE_WORD LIMIT 10];
			System.assertEquals(5, Collection.size(templates));
			for (GenTemplate__c t : templates) {
				System.assertNotEquals(null, t);
				System.assertEquals(v2json, t.ObjectMappings__c);
			}

			templates = [SELECT Id, TemplateType__c, ObjectMappings__c FROM GenTemplate__c WHERE TemplateType__c != :Gen.TYPE_WORD LIMIT 10];
			System.assertEquals(2, Collection.size(templates));
			for (GenTemplate__c t : templates) {
				System.assertNotEquals(null, t);
				System.assertEquals(Gen.TYPE_ONLINE, t.TemplateType__c);
				System.assertEquals(v1json, t.ObjectMappings__c);
			}

			System.assert(GenMigrationSettings__c.getOrgDefaults().WordTemplatesUpdated__c);
		}
	}

	@IsTest
	static void test_shouldExecute_not_upgrade() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);
			WordTemplateUpdater wtu = new WordTemplateUpdater();

			Test.startTest();
			System.assert(!wtu.shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				null,
				false,
				false));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_shouldExecute_later_version() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);
			WordTemplateUpdater wtu = new WordTemplateUpdater();

			Test.startTest();
			System.assert(!wtu.shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 3),
				false,
				true));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_shouldExecute_already_updated() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);
			WordTemplateUpdater wtu = new WordTemplateUpdater();
			GenMigrationSettings__c s = GenMigrationSettings__c.getOrgDefaults();
			s.WordTemplatesUpdated__c = true;
			insert s;

			Test.startTest();
			System.assert(!wtu.shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_shouldExecute_no_templates() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(Gen.TYPE_ONLINE, 1);
			WordTemplateUpdater wtu = new WordTemplateUpdater();

			Test.startTest();
			System.assert(!wtu.shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_shouldExecute_true() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);
			WordTemplateUpdater wtu = new WordTemplateUpdater();

			Test.startTest();
			System.assert(wtu.shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_execute_skip() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 5);

			Test.startTest();
			PostInstallResults result = new WordTemplateUpdater().execute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 2), // Already at target version
				false,
				true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertEquals(Label.UpgradeWordTemplates, result.getSteps()[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SKIPPED, result.getSteps()[0].status);
		}
	}

	@IsTest
	static void test_execute_failure() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);
		}

		System.runAs(UserMock.createDocuSignGenerator(false)) { // Unauthorized
			Test.startTest();
			PostInstallResults result = new WordTemplateUpdater().execute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.success);
			System.assertEquals(Label.UpgradeWordTemplates, result.getSteps()[0].name);
			System.assertEquals(PostInstallResults.StepStatus.FAILURE, result.getSteps()[0].status);

			// Should only run once successfully
			System.assert(new WordTemplateUpdater().shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true));
		}
	}

	@IsTest
	static void test_execute_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			createTemplates(null, 1);

			Test.startTest();
			PostInstallResults result = new WordTemplateUpdater().execute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
			System.assertEquals(Label.UpgradeWordTemplates, result.getSteps()[0].name);
			System.assertEquals(PostInstallResults.StepStatus.SUCCESS, result.getSteps()[0].status);

			// Should only run once successfully
			System.assert(!new WordTemplateUpdater().shouldExecute(
				UserInfo.getOrganizationId(),
				UserInfo.getUserId(),
				new Version(2, 1),
				false,
				true));
		}
	}
}
