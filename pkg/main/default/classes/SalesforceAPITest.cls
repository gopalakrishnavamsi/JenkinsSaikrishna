@IsTest(IsParallel = true)
public with sharing class SalesforceAPITest {

	public class FailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"errorCode":"UNIT_TEST_ERROR","message":"Unit test error"}');
			return response;
		}
	}

	@IsTest
	static void test_getMergeObjects_success() {
		Test.setMock(HttpCalloutMock.class, new SalesforceAPIMock());
		final SalesforceAPI sfService = SalesforceAPI.getInstance();

		Test.startTest();
		final List<Salesforce.MergeObject> sfObjects = sfService.getMergeObjects();
		Test.stopTest();

		System.assertNotEquals(null, sfObjects);
		System.assert(!sfObjects.isEmpty());
		System.assertEquals(2, sfObjects.size());
		System.assertEquals('Account', sfObjects[0].name);
		System.assertEquals('Opportunity', sfObjects[1].name);
	}

	@IsTest
	static void test_getMergeObjects_failure() {
		Test.setMock(HttpCalloutMock.class, new FailureMock());
		final SalesforceAPI sfService = SalesforceAPI.getInstance();
		APIException ex = null;

		Test.startTest();
		try {
			sfService.getMergeObjects();
		} catch (APIException ex2) {
			ex = ex2;
		}
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(400, ex.error.code);
	}

	@IsTest
	static void test_getMergeFields_success() {
		Test.setMock(HttpCalloutMock.class, new SalesforceAPIMock());
		final SalesforceAPI sfService = SalesforceAPI.getInstance();

		Test.startTest();
		final List<Salesforce.MergeField> accountDesc = sfService.getMergeFields('Account', 1);
		final List<Salesforce.MergeField> oppoDescLevel1 = sfService.getMergeFields('Opportunity', 1);
		final List<Salesforce.MergeField> oppoDescLevel2 = sfService.getMergeFields('Opportunity', 2);
		final List<Salesforce.MergeField> oppoDescLevel3 = sfService.getMergeFields('Opportunity', 3);
		Test.stopTest();

		System.assertNotEquals(null, accountDesc);
		System.assert(!accountDesc.isEmpty());
		System.assertEquals(1, accountDesc.size());
		System.assertEquals('Name', accountDesc[0].name);

		System.assertNotEquals(null, oppoDescLevel1);
		System.assert(!oppoDescLevel1.isEmpty());
		System.assertEquals(68, oppoDescLevel1.size());
		System.assertEquals('IsPrivate', oppoDescLevel1[2].name);

		System.assertNotEquals(null, oppoDescLevel2);
		System.assert(!oppoDescLevel2.isEmpty());
		System.assertEquals(40, oppoDescLevel2.size());
		System.assertEquals('IsPrivate', oppoDescLevel2[2].name);

		System.assertNotEquals(null, oppoDescLevel3);
		System.assert(!oppoDescLevel3.isEmpty());
		System.assertEquals(34, oppoDescLevel3.size());
		System.assertEquals('Name', oppoDescLevel3[2].name);
	}

	@IsTest
	static void test_getMergeFields_failure() {
		Test.setMock(HttpCalloutMock.class, new FailureMock());
		final SalesforceAPI sfService = SalesforceAPI.getInstance();
		APIException ex = null;

		Test.startTest();
		try {
			sfService.getMergeFields('Whatever', 1);
		} catch (APIException ex2) {
			ex = ex2;
		}
		Test.stopTest();

		System.assertNotEquals(null, ex);
		System.assertEquals(400, ex.error.code);
	}

	public class SalesforceApiErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			final HttpResponse res = new HttpResponse();
			final String endpoint = req.getEndpoint();
			if (endpoint.endsWith('null_json')) {
				res.setHeader('Content-Type', 'application/json');
				res.setStatusCode(200);
			} else if (endpoint.endsWith('invalid_json')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"bad":{}');
				res.setStatusCode(200);
			} else if (endpoint.endsWith('invalid_error_json')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"message":"Error message"errorCode":"GENERIC_ERROR"}');
				res.setStatusCode(400);
			} else if (endpoint.endsWith('not_json')) {
				res.setHeader('Content-Type', 'text/xml');
				res.setBody('<?xml version="1.0" encoding="UTF-8"?><foo>bar</foo>');
				res.setStatusCode(200);
			} else if (endpoint.endsWith('not_error_json')) {
				res.setHeader('Content-Type', 'text/xml');
				res.setBody('<?xml version="1.0" encoding="UTF-8"?><error><message>foo</message><errorCode>bar</errorCode></error>');
				res.setStatusCode(400);
			} else if (endpoint.endsWith('internal')) {
				res.setHeader('Content-Type', 'text/html');
				res.setBody('<p>FAIL</p>');
				res.setStatusCode(500);
			} else if (endpoint.endsWith('valid_error')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('[{"message":"Error message","errorCode":"GENERIC_ERROR"}]');
				res.setStatusCode(400);
			} else if (endpoint.endsWith('generic_exception')) {
				throw new StringException('error');
			} else if (endpoint.endsWith('callout_exception')) {
				throw new CalloutException('callout error');
			} else if (endpoint.endsWith('md_api_exception')) {
				throw new CalloutException('Something bad happened calling SFDC API: ' + Url.getSalesforceBaseUrl().toExternalForm());
			} else {
				res.setStatusCode(500);
			}

			return res;
		}
	}

	@IsTest
	static void test_SFDC_errors() {
		Test.setMock(HttpCalloutMock.class, new SalesforceApiErrorMock());
		final SalesforceAPI sfService = SalesforceAPI.getInstance();

		Test.startTest();
		try {
			sfService.get('null_resp', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { Label.Unknown }), ex.getMessage());
		}

		try {
			sfService.get('null_json', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { '' }), ex.getMessage());
		}

		try {
			sfService.get('invalid_json', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { '' }), ex.getMessage());
		}

		try {
			sfService.get('invalid_error_json', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { Label.SalesforceApiErrorUnexpectedResponse }), ex.getMessage());
		}

		try {
			sfService.get('not_error_json', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { Label.SalesforceApiErrorUnexpectedResponse }), ex.getMessage());
		}

		try {
			sfService.get('not_json', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { Label.SalesforceApiErrorUnexpectedResponse }), ex.getMessage());
		}

		try {
			sfService.get('internal', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { Label.Unknown }), ex.getMessage());
		}

		try {
			sfService.get('valid_error', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { '[GENERIC_ERROR] Error message' }), ex.getMessage());
		}

		try {
			sfService.get('generic_exception', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { 'error' }), ex.getMessage());
		}

		try {
			sfService.get('callout_exception', 2000);
		} catch (APIException ex) {
			System.assertEquals(String.format(Label.SalesforceApiError_1, new List<String> { 'callout error' }), ex.getMessage());
		}

		try {
			sfService.get('md_api_exception', 2000);
		} catch (Salesforce.MetadataApiNotSupportedException ex) {
			System.assertEquals(String.format(Label.RemoteSiteMissing_1, new List<String> { Url.getSalesforceBaseUrl().toExternalForm() }), ex.getMessage());
		}
		Test.stopTest();
	}
}
