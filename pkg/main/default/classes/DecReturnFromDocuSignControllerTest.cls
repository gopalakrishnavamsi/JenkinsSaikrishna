@IsTest
public class DecReturnFromDocuSignControllerTest {

	@IsTest
	static void test_onReturn() {
		PageReference pg = Page.DecReturnFromDocuSign;
		PageReference testPg;
		Map<String, String> ps = pg.getParameters();
		ps.put(QueryString.PARAM_SOURCE_ID, UserInfo.getUserId());
		Test.setCurrentPage(pg);

		Test.startTest();
		DecReturnFromDocuSignController result = new DecReturnFromDocuSignController();
		testPg = result.onReturn();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(UserInfo.getUserId(), result.decTemplateId);
		System.assertEquals('5', result.afterDecTaggerStep);
		System.assertNotEquals(null, testPg);
		System.assertEquals(testPg.getParameters().get('id'), UserInfo.getUserId());
		System.assertEquals(testPg.getParameters().get('step'), '5');
	}

}