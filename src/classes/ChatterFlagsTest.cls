@IsTest
private class ChatterFlagsTest {

	static testMethod void test_pack() {
		Test.startTest();
		System.assertEquals(788, ChatterFlags.pack(false, false, true, false, true, false, false, false, true, true));
		Test.stopTest();
	}
}
