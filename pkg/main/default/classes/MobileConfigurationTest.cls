@IsTest
private class MobileConfigurationTest {

	@IsTest
	static void test_getInstance() {
		Test.startTest();
		MobileConfiguration mc1 = MobileConfiguration.getInstance();
		MobileConfiguration mc2 = MobileConfiguration.getInstance();
		Test.stopTest();

		System.assertNotEquals(null, mc1);
		System.assert(mc1 === mc2);
		System.assert(mc1.isValid);
		System.assertNotEquals(null, mc1.currentDevice);
		System.assertEquals(Device.OS.Other, mc1.currentDevice.os);
		System.assertEquals(Device.Type.Other, mc1.currentDevice.type);
		System.assert(!mc1.showMobileTagger);
		System.assert(mc1.showIFrameTagger);
		System.assert(!mc1.allowInPersonSigning);
	}

	@IsTest
	static void test_getInstance_from_current_page() {
		System.runAs(UserMock.createDocuSignUser()) {
			PageReference pg = new PageReference('/apex/UnitTest');
			// iPad native SF1 user agent
			pg.getHeaders().put('User-Agent', 'Mozilla/5.0 (iPad; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A465 Safari/8536.25 SalesforceTouchContainer (3B92C18B-D9DE-4CB7-A02A-22FD2AF17C8F)');
			Test.setCurrentPage(pg);

			Test.startTest();
			MobileConfiguration mc = MobileConfiguration.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, mc);
			System.assertNotEquals(null, mc.currentDevice);
			System.assertEquals(Device.OS.IOS, mc.currentDevice.os);
			System.assertEquals(Device.Type.Tablet, mc.currentDevice.type);
			System.assert(!mc.showMobileTagger);
			System.assert(mc.showIFrameTagger);
			System.assert(mc.allowInPersonSigning);
		}
	}

	@IsTest
	static void test_getInstance_from_user_agent() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			MobileConfiguration mc = MobileConfiguration.getInstance('Mozilla/5.0 (iPad; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A465 Safari/8536.25 SalesforceTouchContainer (3B92C18B-D9DE-4CB7-A02A-22FD2AF17C8F)');
			Test.stopTest();

			System.assertNotEquals(null, mc);
			System.assertNotEquals(null, mc.currentDevice);
			System.assertEquals(Device.OS.IOS, mc.currentDevice.os);
			System.assertEquals(Device.Type.Tablet, mc.currentDevice.type);
			System.assert(!mc.showMobileTagger);
			System.assert(mc.showIFrameTagger);
			System.assert(mc.allowInPersonSigning);
		}
	}

	@IsTest
	static void test_showMobileTagger() {
		// SF1 native => showMobileTagger
		Device d1 = new Device(Device.OS.Android, Device.Type.Phone, true);
		// !SF1 native => !showMobileTaggger
		Device d2 = new Device(Device.OS.Android, Device.Type.Phone, false);

		Test.startTest();
		MobileConfiguration mc1 = new MobileConfiguration(d1, true, null);
		MobileConfiguration mc2 = new MobileConfiguration(d2, true, null);
		Test.stopTest();

		System.assertNotEquals(null, mc1);
		System.assert(mc1.showMobileTagger);
		System.assertNotEquals(null, mc2);
		System.assert(!mc2.showMobileTagger);
	}

	@IsTest
	static void test_showIFrameTagger() {
		// Other device => showIFrameTagger
		Device d1 = new Device(Device.OS.Other, Device.Type.Other, true);
		// !iPad => !showIframeTagger
		Device d2 = new Device(Device.OS.Android, Device.Type.Tablet, true);
		// iPad => showIFrameTagger
		Device d3 = new Device(Device.OS.IOS, Device.Type.Tablet, true);

		Test.startTest();
		MobileConfiguration mc1 = new MobileConfiguration(d1, true, null);
		MobileConfiguration mc2 = new MobileConfiguration(d1, false, null);
		MobileConfiguration mc3 = new MobileConfiguration(d2, true, null);
		MobileConfiguration mc4 = new MobileConfiguration(d2, false, null);
		MobileConfiguration mc5 = new MobileConfiguration(d3, true, null);
		MobileConfiguration mc6 = new MobileConfiguration(d3, false, null);
		Test.stopTest();

		System.assertNotEquals(null, mc1);
		System.assert(mc1.showIFrameTagger);
		System.assertNotEquals(null, mc2);
		System.assert(mc2.showIFrameTagger);
		System.assertNotEquals(null, mc3);
		System.assert(!mc3.showIFrameTagger);
		System.assertNotEquals(null, mc4);
		System.assert(!mc4.showIFrameTagger);
		System.assertNotEquals(null, mc5);
		System.assert(!mc5.showIFrameTagger);
		System.assertNotEquals(null, mc6);
		System.assert(mc6.showIFrameTagger);
	}

	@IsTest
	static void test_allowInPersonSigning() {
		// !iPad => !allowInPersonSigning
		Device d1 = new Device(Device.OS.Android, Device.Type.Tablet, true);
		// iPad => allowInPersonSigning && !isMobileTaggerEnabled
		Device d2 = new Device(Device.OS.IOS, Device.Type.Tablet, true);

		Test.startTest();
		MobileConfiguration mc1 = new MobileConfiguration(d1, false, null);
		MobileConfiguration mc2 = new MobileConfiguration(d2, false, null);
		MobileConfiguration mc3 = new MobileConfiguration(d2, true, null);
		Test.stopTest();

		System.assertNotEquals(null, mc1);
		System.assert(!mc1.allowInPersonSigning);
		System.assertNotEquals(null, mc2);
		System.assert(mc2.allowInPersonSigning);
		System.assertNotEquals(null, mc3);
		System.assert(!mc3.allowInPersonSigning);
	}
}
