@IsTest
private class ReturnControllerTest {

	@IsTest
	static void test_parseDocuSignAction() {
		System.assertEquals(ReturnController.DocuSignAction.Tag, ReturnController.parseDocuSignAction('TAG'));
		System.assertEquals(ReturnController.DocuSignAction.Sign, ReturnController.parseDocuSignAction('sign'));
		System.assertEquals(ReturnController.DocuSignAction.Unknown, ReturnController.parseDocuSignAction(null));
	}

	@IsTest
	static void test_constructor() {
		PageReference pg = Page.ReturnFromDocuSign;
		Map<String, String> ps = pg.getParameters();
		ps.put(QueryString.PARAM_SOURCE_ID, UserInfo.getUserId());
		ps.put(QueryString.PARAM_ENVELOPE_ID, UserInfo.getOrganizationId());
		ps.put(QueryString.PARAM_DOCUSIGN_ACTION, 'sign');
		ps.put('event', 'signed');
		Test.setCurrentPage(pg);

		Test.startTest();
		ReturnController result = new ReturnController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(UserInfo.getUserId(), result.sourceId);
		System.assertEquals(Site.getPathPrefix(), result.pathPrefix);
		System.assertEquals(UserInfo.getOrganizationId(), result.envelopeId);
		System.assertEquals(ReturnController.DocuSignAction.Sign, result.action);
		System.assertEquals('signed', result.event);
	}

	@IsTest
	static void test_onReturn_cancel() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			ReturnController rc = new ReturnController(a.Id, e.Id, ReturnController.DocuSignAction.Tag, 'cancel');

			Test.startTest();
			PageReference result = rc.onReturn();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('/' + a.Id, result.getUrl());
			System.assert(Collection.isEmpty([SELECT Id FROM Envelope__c WHERE Id = :e.Id]));
		}
	}

	@IsTest
	static void test_onReturn_send() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			Envelope__c e = TestUtils.createEnvelope(a.Id);
			ReturnController rc = new ReturnController(a.Id, e.Id, ReturnController.DocuSignAction.Tag, 'send');

			Test.startTest();
			PageReference result = rc.onReturn();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('/' + a.Id, result.getUrl());
			System.assertNotEquals(null, [SELECT Sent__c FROM Envelope__c WHERE Id = :e.Id].Sent__c);
		}
	}
}
