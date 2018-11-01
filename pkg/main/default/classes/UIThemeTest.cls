@IsTest(isParallel = true)
private class UIThemeTest {

	@IsTest
	static void test_currentTheme() {
		System.assertNotEquals(null, UITheme.currentTheme);
	}

	@IsTest
	static void test_Classic_Theme1() {
		UITheme.setTheme('Theme1');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Classic, UITheme.currentTheme);
		System.assert(UITheme.isClassic);
		System.assert(!UITheme.isSalesforce1);
		System.assert(!UITheme.isLightning);
		Test.stopTest();
	}

	@IsTest
	static void test_Classic_Theme2() {
		UITheme.setTheme('Theme2');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Classic, UITheme.currentTheme);
		System.assert(UITheme.isClassic);
		System.assert(!UITheme.isSalesforce1);
		System.assert(!UITheme.isLightning);
		Test.stopTest();
	}

	@IsTest
	static void test_Classic_Theme3() {
		UITheme.setTheme('Theme3');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Classic, UITheme.currentTheme);
		System.assert(UITheme.isClassic);
		System.assert(!UITheme.isSalesforce1);
		System.assert(!UITheme.isLightning);
		Test.stopTest();
	}

	@IsTest
	static void test_Salesforce1() {
		UITheme.setTheme('Theme4t');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Salesforce1, UITheme.currentTheme);
		System.assert(!UITheme.isClassic);
		System.assert(UITheme.isSalesforce1);
		System.assert(!UITheme.isLightning);
		Test.stopTest();
	}

	@IsTest
	static void test_Lightning() {
		UITheme.setTheme('Theme4d');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Lightning, UITheme.currentTheme);
		System.assert(!UITheme.isClassic);
		System.assert(!UITheme.isSalesforce1);
		System.assert(UITheme.isLightning);
		Test.stopTest();
	}

	@IsTest
	static void test_other() {
		UITheme.setTheme('PortalDefault');

		Test.startTest();
		System.assertEquals(UITheme.Theme.Other, UITheme.currentTheme);
		System.assert(!UITheme.isClassic);
		System.assert(!UITheme.isSalesforce1);
		System.assert(!UITheme.isLightning);
		Test.stopTest();
	}
}