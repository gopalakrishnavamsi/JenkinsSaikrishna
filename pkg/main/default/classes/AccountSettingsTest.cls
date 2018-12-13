@IsTest(IsParallel = true)
private class AccountSettingsTest {

	@IsTest
	static void test_getInstance() {
		Test.startTest();
		AccountSettings result1 = AccountSettings.getInstance();
		AccountSettings result2 = AccountSettings.getInstance();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(result1 === result2);
	}

	@IsTest
	static void test_save() {
		AccountSettings s = new AccountSettings(
			12345,
			new List<String> { 'er1', 'er2' },
			new List<String> { 'dr1', 'dr2' },
			new List<String> { 'rr1', 'rr2' },
			'CompoundMatchBeginning');

		Test.startTest();
		AccountSettings result1 = AccountSettings.getInstance();
		AccountSettings result2 = AccountSettings.save(s);
		AccountSettings result3 = AccountSettings.getInstance();
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!(result1 === result2));
		System.assertNotEquals(null, result2);
		System.assert(result2 === result3);
		System.assertEquals(12345, result3.calloutTimeout);
		System.assertEquals(new List<String> { 'er1', 'er2' }, result3.entityResolvers);
		System.assertEquals(new List<String> { 'dr1', 'dr2' }, result3.documentResolvers);
		System.assertEquals(new List<String> { 'rr1', 'rr2' }, result3.recipientResolvers);
		System.assertEquals(Recipient.SearchBehavior.CompoundMatchBeginning.name(), result3.recipientSearchBehavior);
	}
}
