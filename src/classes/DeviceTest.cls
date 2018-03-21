@IsTest
private class DeviceTest {

	static testMethod void test_constructor() {
		Test.startTest();
		Device d1 = new Device(Device.OS.Other, Device.Type.Other, false);
		Device d2 = new Device(Device.OS.IOS, Device.Type.Phone, true);
		Test.stopTest();

		System.assertNotEquals(null, d1);
		System.assertEquals(Device.OS.Other, d1.os);
		System.assertEquals(Device.Type.Other, d1.type);
		System.assert(!d1.isSalesforce1Native);
		System.assert(!d1.isMobile);

		System.assertNotEquals(null, d2);
		System.assertEquals(Device.OS.IOS, d2.os);
		System.assertEquals(Device.Type.Phone, d2.type);
		System.assert(d2.isSalesforce1Native);
		System.assert(d2.isMobile);
	}

	static testMethod void test_fromUserAgent() {
		String otherUA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36';
		String iPhoneUA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_1 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/10.0 Mobile/14A403 Safari/602.1';
		String iPadUA = 'Mozilla/5.0 (iPad; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A465 Safari/8536.25 (3B92C18B-D9DE-4CB7-A02A-22FD2AF17C8F)';
		String iPadNativeUA = 'Mozilla/5.0 (iPad; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A465 Safari/8536.25 SalesforceTouchContainer (3B92C18B-D9DE-4CB7-A02A-22FD2AF17C8F)';
		String androidPhoneUA = 'Mozilla/5.0 (Linux; Android 7.0;SAMSUNG SM-G955F Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/5.2 Chrome/51.0.2704.106 Mobile Safari/537.36';
		String androidTabletUA = 'Mozilla/5.0 (Linux; U; Android 3.0; en-us; Xoom Build/HRI39) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13';

		Test.startTest();
		Device other1 = Device.fromUserAgent(null);
		Device other2 = Device.fromUserAgent('');
		Device other3 = Device.fromUserAgent(' \r');
		Device other4 = Device.fromUserAgent(otherUA);
		Device iPhone = Device.fromUserAgent(iPhoneUA);
		Device iPad = Device.fromUserAgent(iPadUA);
		Device iPadNative = Device.fromUserAgent(iPadNativeUA);
		Device androidPhone = Device.fromUserAgent(androidPhoneUA);
		Device androidTablet = Device.fromUserAgent(androidTabletUA);
		Test.stopTest();

		System.assertNotEquals(null, other1);
		System.assertEquals(Device.OS.Other, other1.os);
		System.assertEquals(Device.Type.Other, other1.type);
		System.assert(!other1.isMobile);
		System.assert(!other1.isSalesforce1Native);

		System.assertNotEquals(null, other2);
		System.assertEquals(Device.OS.Other, other2.os);
		System.assertEquals(Device.Type.Other, other2.type);
		System.assert(!other2.isMobile);
		System.assert(!other2.isSalesforce1Native);

		System.assertNotEquals(null, other3);
		System.assertEquals(Device.OS.Other, other3.os);
		System.assertEquals(Device.Type.Other, other3.type);
		System.assert(!other3.isMobile);
		System.assert(!other3.isSalesforce1Native);

		System.assertNotEquals(null, other4);
		System.assertEquals(Device.OS.Other, other4.os);
		System.assertEquals(Device.Type.Other, other4.type);
		System.assert(!other4.isMobile);
		System.assert(!other4.isSalesforce1Native);

		System.assertNotEquals(null, iPhone);
		System.assertEquals(Device.OS.IOS, iPhone.os);
		System.assertEquals(Device.Type.Phone, iPhone.type);
		System.assert(iPhone.isMobile);
		System.assert(!iPhone.isSalesforce1Native);

		System.assertNotEquals(null, iPad);
		System.assertEquals(Device.OS.IOS, iPad.os);
		System.assertEquals(Device.Type.Tablet, iPad.type);
		System.assert(iPad.isMobile);
		System.assert(!iPad.isSalesforce1Native);

		System.assertNotEquals(null, iPadNative);
		System.assertEquals(Device.OS.IOS, iPadNative.os);
		System.assertEquals(Device.Type.Tablet, iPadNative.type);
		System.assert(iPadNative.isMobile);
		System.assert(iPadNative.isSalesforce1Native);

		System.assertNotEquals(null, androidPhone);
		System.assertEquals(Device.OS.Android, androidPhone.os);
		System.assertEquals(Device.Type.Phone, androidPhone.type);
		System.assert(androidPhone.isMobile);
		System.assert(!androidPhone.isSalesforce1Native);

		System.assertNotEquals(null, androidTablet);
		System.assertEquals(Device.OS.Android, androidTablet.os);
		System.assertEquals(Device.Type.Tablet, androidTablet.type);
		System.assert(androidTablet.isMobile);
		System.assert(!androidTablet.isSalesforce1Native);
	}
}
