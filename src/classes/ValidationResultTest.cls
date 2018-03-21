@IsTest
private class ValidationResultTest {

	static testMethod void test_ValidationResult() {
		Test.startTest();
		ValidationResult vr = new ValidationResult();
		System.assertNotEquals(null, vr);
		System.assert(vr.isValid);
		System.assertEquals('', vr.toString());

		vr = new ValidationResult('Message1');
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message1', vr.toString());

		vr = new ValidationResult(new List<String> { 'Message2', 'Message3' });
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message2\nMessage3', vr.toString());

		vr = vr.add('Message4');
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message2\nMessage3\nMessage4', vr.toString());

		vr = vr.add(new List<String> { 'Message5', 'Message6' });
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message2\nMessage3\nMessage4\nMessage5\nMessage6', vr.toString());

		vr = new ValidationResult('Message1').add(vr);
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message1\nMessage2\nMessage3\nMessage4\nMessage5\nMessage6', vr.toString());

		vr = new ValidationResult('Message1').add(new Permissions.FlsResults(
			Permissions.FlsAccess.Queryable,
			false,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.OK),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.NotFound)
			}));
		System.assertNotEquals(null, vr);
		System.assert(!vr.isValid);
		System.assertEquals('Message1\n' + String.format(Label.CannotQueryFields_2, new List<String> {
			'Unit', 'Test2 (NotFound)'
		}), vr.toString());

		vr = new ValidationResult().add(new Permissions.FlsResults(
			Permissions.FlsAccess.Queryable,
			true,
			new Permissions.FlsResult('Unit', Permissions.FlsStatus.OK),
			new List<Permissions.FlsResult> {
				new Permissions.FlsResult('Test1', Permissions.FlsStatus.OK),
				new Permissions.FlsResult('Test2', Permissions.FlsStatus.OK)
			}));
		System.assertNotEquals(null, vr);
		System.assert(vr.isValid);
		System.assertEquals('', vr.toString());
		Test.stopTest();
	}
}
