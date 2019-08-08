@IsTest
private class AccountProductsTest {

	@IsTest
	static void test_getInstance_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignSender()) {
			Test.startTest();
			AccountProducts result1 = AccountProducts.getInstance();
			AccountProducts result2 = AccountProducts.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertNotEquals(null, result1.eSignature);
			System.assertNotEquals(null, result1.gen);
			System.assertNotEquals(null, result1.negotiate);
			System.assertNotEquals(null, result1.clm);
		}
	}

	@IsTest
	static void test_getInstance_error() {
		DocuSignAPIMock.failure();

		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			AccountProducts result = AccountProducts.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(null, result.eSignature);
			System.assertEquals(null, result.gen);
			System.assertEquals(null, result.negotiate);
			System.assertEquals(null, result.clm);
		}
	}

	@IsTest
	static void test_isESignatureTrialExpired() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, false, Date.today().addDays(-1), null) });
		AccountProducts aps5 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isESignatureTrialExpired());
		System.assert(!aps2.isESignatureTrialExpired());
		System.assert(aps3.isESignatureTrialExpired());
		System.assert(!aps4.isESignatureTrialExpired());
		System.assert(!aps5.isESignatureTrialExpired());
		Test.stopTest();
	}

	@IsTest
	static void test_isESignatureEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isESignatureEnabled());
		System.assert(!aps2.isESignatureEnabled());
		System.assert(!aps3.isESignatureEnabled());
		System.assert(aps4.isESignatureEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isGenEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null) });

		Test.startTest();
		System.assert(!aps1.isGenEnabled());
		System.assert(!aps2.isGenEnabled());
		System.assert(!aps3.isGenEnabled());
		System.assert(aps4.isGenEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isNegotiateEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null) });

		Test.startTest();
		System.assert(!aps1.isNegotiateEnabled());
		System.assert(!aps2.isNegotiateEnabled());
		System.assert(!aps3.isNegotiateEnabled());
		System.assert(aps4.isNegotiateEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isClmEnabled() {
		AccountProducts aps1 = new AccountProducts(null);
		AccountProducts aps2 = new AccountProducts(new Map<String, Product>());
		AccountProducts aps3 = new AccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null, null) });
		AccountProducts aps4 = new AccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null, null) });

		Test.startTest();
		System.assert(!aps1.isClmEnabled());
		System.assert(!aps2.isClmEnabled());
		System.assert(!aps3.isClmEnabled());
		System.assert(aps4.isClmEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_resolveProducts_update() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignUser()) {
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			accountSettings.ProductsLastChecked__c = null;
			update accountSettings;
			delete ProductSettings__c.getAll().values();
			ESignatureProduct esign = new ESignatureProduct(
				'expired',
				true,
				Date.today().addDays(-1),
				new Set<ESignatureProduct.Feature> { ESignatureProduct.Feature.Templates });

			Test.startTest();
			Map<String, Product> result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addDays(-1),
				1);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(4, result.size());
			System.assertNotEquals(null, AccountSettings__c.getOrgDefaults().ProductsLastChecked__c);
			System.assertEquals(4, Collection.size(ProductSettings__c.getAll().values()));
		}
	}

	@IsTest
	static void test_resolveProducts_cached() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			ESignatureProduct esign = new ESignatureProduct(
				'expired',
				true,
				Date.today().addDays(-1),
				new Set<ESignatureProduct.Feature> { ESignatureProduct.Feature.Templates });

			Test.startTest();
			Map<String, Product> result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addMinutes(-1),
				60);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, result.size());
			System.assertEquals(null, AccountSettings__c.getOrgDefaults().ProductsLastChecked__c);
			System.assertEquals(0, Collection.size(ProductSettings__c.getAll().values()));
		}
	}

	@IsTest
	static void test_packFeatures() {
		Integer flags = AccountProducts.FLAG_BULK_SENDING
			| AccountProducts.FLAG_MERGE_FIELDS
			| AccountProducts.FLAG_SIGNING_GROUPS
			| AccountProducts.FLAG_SMS_AUTHENTICATION
			| AccountProducts.FLAG_TEMPLATES;
		Set<ESignatureProduct.Feature> features = new Set<ESignatureProduct.Feature> {
			ESignatureProduct.Feature.BulkSending,
			ESignatureProduct.Feature.MergeFields,
			ESignatureProduct.Feature.SigningGroups,
			ESignatureProduct.Feature.SmsAuthentication,
			ESignatureProduct.Feature.Templates
		};

		Test.startTest();
		System.assertEquals(flags, AccountProducts.packFeatures(features));
		Test.stopTest();
	}

	@IsTest
	static void test_unpackFeatures() {
		Integer flags = AccountProducts.FLAG_BULK_SENDING
			| AccountProducts.FLAG_MERGE_FIELDS
			| AccountProducts.FLAG_SIGNING_GROUPS
			| AccountProducts.FLAG_SMS_AUTHENTICATION
			| AccountProducts.FLAG_TEMPLATES;
		Set<ESignatureProduct.Feature> features = new Set<ESignatureProduct.Feature> {
			ESignatureProduct.Feature.BulkSending,
			ESignatureProduct.Feature.MergeFields,
			ESignatureProduct.Feature.SigningGroups,
			ESignatureProduct.Feature.SmsAuthentication,
			ESignatureProduct.Feature.Templates
		};

		Test.startTest();
		System.assertEquals(features, AccountProducts.unpackFeatures(flags));
		Test.stopTest();
	}

	@IsTest
	static void test_startTrial_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrial(null);
				throw new AssertException('Expected startTrial to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrial_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrial(null);
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrial('  ');
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrial(Product.CLM);
				throw new AssertException('Expected startTrial to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(
					String.format(Label.InvalidTrialProduct_1, new List<String> { Product.CLM }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrial_success() {
		ProvisioningAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			delete ProductSettings__c.getAll().values();
			ProductSettings__c ps = new ProductSettings__c(
				Name = Product.GEN
			);
			insert ps;

			Test.startTest();
			Product result1 = AccountProducts.getInstance().startTrial(Product.GEN);
			Product result2 = AccountProducts.getInstance().startTrial(Product.NEGOTIATE);
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(null, result2);

			Map<String, ProductSettings__c> pss = ProductSettings__c.getAll();
			System.assertNotEquals(null, pss);
			System.assertEquals(2, pss.size());
			System.assertEquals(new Set<String> { Product.GEN, Product.NEGOTIATE }, pss.keySet());
			System.assertEquals(ps.Id, pss.get(Product.GEN).Id);

		}
	}

	class ProductActivationMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			if (request.getMethod() == 'GET') {
				if (request.getEndpoint().contains('/provision')) {
					response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
					response.setBody('{"id":"' + s.AccountId__c + '","name":"' + s.AccountName__c + '","products":[{"id":"f3495ac5-25a0-4c0b-a911-0ad0ec1dfa18","product":"gen","product_id":"Gen","product_account_id":"20856","provision_status":"pending","provision_date":"2019-07-25T22:05:57.8032029Z","activation_date":"2019-07-25T22:06:00.0526866Z","activation_properties":[{"name":"api_base_uri","value":"https://apiqana11.springcm.com"},{"name":"merge_uri","value":"https://apiqana11.springcm.com/gen"},{"name":"site","value":"na11"},{"name":"web_base_uri","value":"https://qana11.springcm.com/atlas/"}],"free_trial":false},{"id":"da1007b8-f1d8-4042-8f97-16e6d53ce220","product":"e_sign","product_id":"d258872d-733e-4628-825c-efb0f2b4c7fa","provision_status":"pending","provision_date":"2019-08-06T18:52:05.7668814Z","activation_date":"2019-07-25T22:05:57.7407234Z","free_trial":false},{"id":"14160549-271b-4474-92b5-4480b796dc14","product":"negotiate","product_id":"Negotiate","product_account_id":"20856","provision_status":"pending","provision_date":"2019-08-06T18:52:05.9387488Z","activation_date":"2019-08-07T15:25:44.0305127Z","activation_properties":[{"name":"api_base_uri","value":"https://apiqana11.springcm.com"},{"name":"merge_uri","value":"https://apiqana11.springcm.com/gen"},{"name":"site","value":"na11"},{"name":"web_base_uri","value":"https://qana11.springcm.com/atlas/"}],"free_trial":false},{"id":"cd74aae5-4a63-4539-b360-cafd14ee5a3d","product":"clm","product_id":"clm","product_account_id":"20856","provision_status":"pending","provision_date":"2019-08-05T21:14:01.7745305Z","activation_date":"2019-08-05T21:14:23.8838217Z","activation_properties":[{"name":"site","value":"na11"},{"name":"web_base_uri","value":"https://qana11.springcm.com/atlas/"},{"name":"admin_uri","value":"https://qana11.springcm.com/atlas/Admin/AccountSettings"},{"name":"landing_page_uri","value":"https://qana11.springcm.com/atlas/LandingPage"}],"free_trial":false},{"id":"cd74aae5-4a63-4539-b360-cafd14eeffff","product":"other","product_id":"other","product_account_id":"20856","provision_status":"pending","provision_date":"2019-08-05T21:14:01.7745305Z","activation_date":"2019-08-05T21:14:23.8838217Z","activation_properties":[],"free_trial":false}]}');
				} else if (request.getEndpoint().contains('/settings')) {
					Map<String, Object> settings = new Map<String, Object> {
						'accountSettings' => new List<UserAPI.APISetting> {
							new UserAPI.APISetting('allowMergeFields', 'true'),
							new UserAPI.APISetting('sharedCustomTabsEnabled', 'true'),
							new UserAPI.APISetting('savingCustomTabsEnabled', 'true'),
							new UserAPI.APISetting('dataFieldRegexEnabled', 'true'),
							new UserAPI.APISetting('dataFieldSizeEnabled', 'true'),
							new UserAPI.APISetting('tabTextFormattingEnabled', 'true'),
							new UserAPI.APISetting('allowSigningGroups', 'true'),
							new UserAPI.APISetting('tabDataLabelEnabled', 'true'),
							new UserAPI.APISetting('enableSMSAuthentication', 'true'),
							new UserAPI.APISetting('allowServerTemplates', 'true'),
							new UserAPI.APISetting('allowBulkSend', 'true')
						}
					};
					response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
					response.setBody(JSON.serialize(settings));
				} else if (request.getEndpoint().contains('/billing_plan')) {
					AccountAPI.PlanId pid = new AccountAPI.PlanId();
					pid.planId = '8b7c743b-5321-401f-8615-275021832201';
					AccountAPI.BillingPlans bps = new AccountAPI.BillingPlans();
					bps.billingPlan = pid;
					response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
					response.setBody(JSON.serialize(bps));
				} else { // get account
					AccountAPI.APIAccount a = new AccountAPI.APIAccount();
					a.currentPlanId = 'd1d8e549-4f0f-464a-a474-813b21c659da';
					a.planName = 'DEVCENTER_DEMO_APRIL2013';
					a.planStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					a.planEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
					a.billingPeriodStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					a.billingPeriodEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
					a.accountName = s.AccountName__c;
					a.accountIdGuid = s.AccountId__c;
					a.externalAccountId = String.valueOf(s.AccountNumber__c);
					a.connectPermission = 'full';
					a.suspensionStatus = null;
					a.suspensionDate = null;
					response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
					response.setBody(JSON.serialize(a));
				}
			} else { // activate product
				Map<String, Object> req = (Map<String, Object>)JSON.deserializeUntyped(request.getBody());

				response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
				response.setBody('{"id":"' + UUID.randomUUID() + '","product":"' + (String)req.get('product') + '","product_id":"' + (String)req.get('product') + '","product_account_id":"20856","provision_status":"active","provision_date":"2019-08-06T18:52:05.9387488Z","activation_date":"2019-08-07T15:25:44.0305127Z","activation_properties":[{"name":"api_base_uri","value":"https://apiqana11.springcm.com"},{"name":"merge_uri","value":"https://apiqana11.springcm.com/gen"},{"name":"site","value":"na11"},{"name":"web_base_uri","value":"https://qana11.springcm.com/atlas/"}],"free_trial":false}');
			}

			return response;
		}
	}

	@IsTest
	static void test_product_activation() {
		Test.setMock(HttpCalloutMock.class, new ProductActivationMock());

		System.runAs(UserMock.createDocuSignSender()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.ProductsLastChecked__c = null;
			update s;

			Test.startTest();
			AccountProducts result = AccountProducts.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.eSignature);
			System.assertEquals(Product.STATUS_ACTIVE, result.eSignature.status);
			System.assertNotEquals(null, result.gen);
			System.assertEquals(Product.STATUS_ACTIVE, result.gen.status);
			System.assertNotEquals(null, result.negotiate);
			System.assertEquals(Product.STATUS_ACTIVE, result.negotiate.status);
			System.assertNotEquals(null, result.clm);
			System.assertEquals(Product.STATUS_ACTIVE, result.clm.status);
		}
	}

	@IsTest
	static void test_getScmAuthBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://test.springcm.com/landing'),
			new Url('https://test.springcm.com/admin'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.springcm.com/admin'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.springcm.com/admin'));

		Test.startTest();
		Url result1 = new AccountProducts(null).getScmAuthBaseUrl();
		Url result2 = new AccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmAuthBaseUrl();
		Url result3 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmAuthBaseUrl();
		Url result4 = new AccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmAuthBaseUrl();
		Url result5 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmAuthBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assertEquals('https://auth.test.springcm.com', result2.toExternalForm());
		System.assertNotEquals(null, result3);
		System.assertEquals('https://auth.test.springcm.com', result3.toExternalForm());
		System.assertNotEquals(null, result4);
		System.assertEquals('https://auth.test.springcm.com', result4.toExternalForm());
		System.assertNotEquals(null, result5);
		System.assertEquals('https://auth.test.springcm.com', result5.toExternalForm());
	}

	@IsTest
	static void test_getScmApiBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://test.springcm.com/landing'),
			new Url('https://test.springcm.com/admin'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));

		Test.startTest();
		Url result1 = new AccountProducts(null).getScmApiBaseUrl();
		Url result2 = new AccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmApiBaseUrl();
		Url result3 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmApiBaseUrl();
		Url result4 = new AccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmApiBaseUrl();
		Url result5 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmApiBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertEquals(null, result2);
		System.assertNotEquals(null, result3);
		System.assertEquals('https://api.test.springcm.com', result3.toExternalForm());
		System.assertNotEquals(null, result4);
		System.assertEquals('https://api.test.springcm.com', result4.toExternalForm());
		System.assertNotEquals(null, result5);
		System.assertEquals('https://api.test.springcm.com', result5.toExternalForm());
	}

	@IsTest
	static void test_getClmAdminUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://test.springcm.com/landing'),
			new Url('https://test.springcm.com/admin'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));

		Test.startTest();
		Url result1 = new AccountProducts(null).getClmAdminUrl();
		Url result2 = new AccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getClmAdminUrl();
		Url result3 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getClmAdminUrl();
		Url result4 = new AccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getClmAdminUrl();
		Url result5 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getClmAdminUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assertEquals('https://test.springcm.com/admin', result2.toExternalForm());
		System.assertEquals(null, result3);
		System.assertEquals(null, result4);
		System.assertNotEquals(null, result5);
		System.assertEquals('https://test.springcm.com/admin', result5.toExternalForm());
	}

	@IsTest
	static void test_getClmLandingPageUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://test.springcm.com/landing'),
			new Url('https://test.springcm.com/admin'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://auth.test.springcm.com'), new Url('https://api.test.springcm.com'));

		Test.startTest();
		Url result1 = new AccountProducts(null).getClmLandingPageUrl();
		Url result2 = new AccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getClmLandingPageUrl();
		Url result3 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getClmLandingPageUrl();
		Url result4 = new AccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getClmLandingPageUrl();
		Url result5 = new AccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getClmLandingPageUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assertEquals('https://test.springcm.com/landing', result2.toExternalForm());
		System.assertEquals(null, result3);
		System.assertEquals(null, result4);
		System.assertNotEquals(null, result5);
		System.assertEquals('https://test.springcm.com/landing', result5.toExternalForm());
	}
}
