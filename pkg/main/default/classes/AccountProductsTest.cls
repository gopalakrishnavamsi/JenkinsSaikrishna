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
	static void test_getProducts_success() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			List<Product> productsList = AccountProducts.getProducts();
			Test.stopTest();

			System.assertNotEquals(null, productsList);
			System.assertEquals(4, productsList.size());
		}
	}

	@IsTest
	static void test_getInstance_undefined_arguments() {
		Test.startTest();
		try {
			AccountProducts.getInstance(
				null,
				new Url('https://esign.test.docusign.net/'),
				UUID.randomUUID(),
				'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			AccountProducts.getInstance(
				new Url('https://provisioning.test.docusign.net/'),
				null,
				UUID.randomUUID(),
				'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			AccountProducts.getInstance(
				new Url('https://provisioning.test.docusign.net/'),
				new Url('https://esign.test.docusign.net/'),
				null,
				'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			AccountProducts.getInstance(
				new Url('https://provisioning.test.docusign.net/'),
				new Url('https://esign.test.docusign.net/'),
				UUID.randomUUID(),
				'\t');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getInstance_invalid_environment() {
		Test.startTest();
		try {
			AccountProducts.getInstance(
				new Url('https://provisioning.test.bad-docusign.net/'),
				new Url('https://esign.test.docusign.net/'),
				UUID.randomUUID(),
				'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		try {
			AccountProducts.getInstance(
				new Url('https://provisioning.test.docusign.net/'),
				new Url('https://example.com/'),
				UUID.randomUUID(),
				'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getInstance_setup() {
		DocuSignAPIMock.success();

		Test.startTest();
		AccountProducts result = AccountProducts.getInstance(
			new Url('https://provisioning.test.docusign.net/'),
			new Url('https://esign.test.docusign.net/'),
			UUID.randomUUID(),
			'unit.test');
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	static AccountProducts newAccountProducts(final Map<String, Product> products) {
		return new AccountProducts(products, null, null, false);
	}

	@IsTest
	static void test_isESignatureTrialExpired() {
		AccountProducts aps1 = newAccountProducts(null);
		AccountProducts aps2 = newAccountProducts(new Map<String, Product>());
		AccountProducts aps3 = newAccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = newAccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, false, Date.today().addDays(-1), null) });
		AccountProducts aps5 = newAccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

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
		AccountProducts aps1 = newAccountProducts(null);
		AccountProducts aps2 = newAccountProducts(new Map<String, Product>());
		AccountProducts aps3 = newAccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null) });
		AccountProducts aps4 = newAccountProducts(new Map<String, Product> { Product.ESIGNATURE => new ESignatureProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null) });

		Test.startTest();
		System.assert(!aps1.isESignatureEnabled());
		System.assert(!aps2.isESignatureEnabled());
		System.assert(!aps3.isESignatureEnabled());
		System.assert(aps4.isESignatureEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isGenEnabled() {
		AccountProducts aps1 = newAccountProducts(null);
		AccountProducts aps2 = newAccountProducts(new Map<String, Product>());
		AccountProducts aps3 = newAccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null, null) });
		AccountProducts aps4 = newAccountProducts(new Map<String, Product> { Product.GEN => new GenProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null, null) });

		Test.startTest();
		System.assert(!aps1.isGenEnabled());
		System.assert(!aps2.isGenEnabled());
		System.assert(!aps3.isGenEnabled());
		System.assert(aps4.isGenEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isNegotiateEnabled() {
		AccountProducts aps1 = newAccountProducts(null);
		AccountProducts aps2 = newAccountProducts(new Map<String, Product>());
		AccountProducts aps3 = newAccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null, null) });
		AccountProducts aps4 = newAccountProducts(new Map<String, Product> { Product.NEGOTIATE => new NegotiateProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null, null) });

		Test.startTest();
		System.assert(!aps1.isNegotiateEnabled());
		System.assert(!aps2.isNegotiateEnabled());
		System.assert(!aps3.isNegotiateEnabled());
		System.assert(aps4.isNegotiateEnabled());
		Test.stopTest();
	}

	@IsTest
	static void test_isClmEnabled() {
		AccountProducts aps1 = newAccountProducts(null);
		AccountProducts aps2 = newAccountProducts(new Map<String, Product>());
		AccountProducts aps3 = newAccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(-1), null, null) });
		AccountProducts aps4 = newAccountProducts(new Map<String, Product> { Product.CLM => new ClmProduct(Product.STATUS_ACTIVE, true, Date.today().addDays(1), null, null) });

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
			AccountProducts result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addDays(-1),
				1,
				new Url('https://provisioning.test.docusign.net'),
				new Url('https://esign.test.docusign.net'),
				UUID.randomUUID(),
				'unit.test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.products);
			System.assertEquals(4, result.products.size());
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
			AccountProducts result = AccountProducts.resolveProducts(
				new Map<String, Product> { Product.ESIGNATURE => esign },
				Datetime.now().addMinutes(-1),
				60,
				new Url('https://provisioning.test.docusign.net'),
				new Url('https://esign.test.docusign.net'),
				UUID.randomUUID(),
				'unit.test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.products);
			System.assertEquals(1, result.products.size());
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
		System.assertEquals(flags, AccountProducts.DB.packFeatures(features));
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
		System.assertEquals(features, AccountProducts.DB.unpackFeatures(flags));
		Test.stopTest();
	}

	@IsTest
	static void test_startTrial_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrials(null);
				throw new AssertException('Expected startTrials to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrials_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountProducts.getInstance().startTrials(null);
				throw new AssertException('Expected startTrials to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrials(new Set<String>());
				throw new AssertException('Expected startTrials to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AccountProducts.getInstance().startTrials(new Set<String> { Product.CLM });
				throw new AssertException('Expected startTrials to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(
					String.format(Label.InvalidTrialProduct_1, new List<String> { Product.CLM }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_startTrials_success() {
		ProductAPIMock.success();

		System.runAs(UserMock.createDocuSignAdministrator()) {
			delete ProductSettings__c.getAll().values();
			ProductSettings__c ps = new ProductSettings__c(
				Name = Product.GEN
			);
			insert ps;

			Test.startTest();
			List<Product> result = AccountProducts.getInstance().startTrials(
				new Set<String> { Product.GEN, Product.NEGOTIATE });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));

			Map<String, ProductSettings__c> pss = ProductSettings__c.getAll();
			System.assertNotEquals(null, pss);
			System.assertEquals(2, pss.size());
			System.assertEquals(new Set<String> { Product.GEN, Product.NEGOTIATE }, pss.keySet());
			System.assertEquals(ps.Id, pss.get(Product.GEN).Id);
			System.assertEquals(true, pss.get(Product.GEN).IsTrial__c);
			System.assertEquals(true, pss.get(Product.NEGOTIATE).IsTrial__c);

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
					ESignatureProductAPI.PlanId pid = new ESignatureProductAPI.PlanId();
					pid.planId = '8b7c743b-5321-401f-8615-275021832201';
					ESignatureProductAPI.BillingPlans bps = new ESignatureProductAPI.BillingPlans();
					bps.billingPlan = pid;
					response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
					response.setBody(JSON.serialize(bps));
				} else { // get account
					ESignatureProductAPI.APIAccount a = new ESignatureProductAPI.APIAccount();
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
	static void test_getScmWebBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://auth.test.springcm.com/'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));

		Test.startTest();
		Url result1 = newAccountProducts(null).getScmWebBaseUrl();
		Url result2 = newAccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmWebBaseUrl();
		Url result3 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmWebBaseUrl();
		Url result4 = newAccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmWebBaseUrl();
		Url result5 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmWebBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assertEquals('https://web.test.springcm.com/atlas/', result2.toExternalForm());
		System.assertNotEquals(null, result3);
		System.assertEquals('https://web.test.springcm.com/atlas/', result3.toExternalForm());
		System.assertNotEquals(null, result4);
		System.assertEquals('https://web.test.springcm.com/atlas/', result4.toExternalForm());
		System.assertNotEquals(null, result5);
		System.assertEquals('https://web.test.springcm.com/atlas/', result5.toExternalForm());
	}

	@IsTest
	static void test_getScmApiBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://auth.test.springcm.com/'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));

		Test.startTest();
		Url result1 = newAccountProducts(null).getScmApiBaseUrl();
		Url result2 = newAccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmApiBaseUrl();
		Url result3 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmApiBaseUrl();
		Url result4 = newAccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmApiBaseUrl();
		Url result5 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmApiBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertEquals(null, result2);
		System.assertNotEquals(null, result3);
		System.assertEquals('https://api.test.springcm.com/', result3.toExternalForm());
		System.assertNotEquals(null, result4);
		System.assertEquals('https://api.test.springcm.com/', result4.toExternalForm());
		System.assertNotEquals(null, result5);
		System.assertEquals('https://api.test.springcm.com/', result5.toExternalForm());
	}

	@IsTest
	static void test_getScmMergeBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://auth.test.springcm.com/'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));

		Test.startTest();
		Url result1 = newAccountProducts(null).getScmMergeBaseUrl();
		Url result2 = newAccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmMergeBaseUrl();
		Url result3 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmMergeBaseUrl();
		Url result4 = newAccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmMergeBaseUrl();
		Url result5 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmMergeBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertEquals(null, result2);
		System.assertNotEquals(null, result3);
		System.assertEquals('https://merge.test.springcm.com/gen/', result3.toExternalForm());
		System.assertNotEquals(null, result4);
		System.assertEquals('https://merge.test.springcm.com/gen/', result4.toExternalForm());
		System.assertNotEquals(null, result5);
		System.assertEquals('https://merge.test.springcm.com/gen/', result5.toExternalForm());
	}

	@IsTest
	static void test_getScmAuthBaseUrl() {
		ClmProduct clm = new ClmProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://auth.test.springcm.com/'));
		GenProduct gen = new GenProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));
		NegotiateProduct neg = new NegotiateProduct(Product.STATUS_ACTIVE, false, null,
			new Url('https://web.test.springcm.com/atlas/'),
			new Url('https://api.test.springcm.com/'),
			new Url('https://merge.test.springcm.com/gen/'));

		Test.startTest();
		Url result1 = newAccountProducts(null).getScmAuthBaseUrl();
		Url result2 = newAccountProducts(new Map<String, Product> {
			Product.CLM => clm
		}).getScmAuthBaseUrl();
		Url result3 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen
		}).getScmAuthBaseUrl();
		Url result4 = newAccountProducts(new Map<String, Product> {
			Product.NEGOTIATE => neg
		}).getScmAuthBaseUrl();
		Url result5 = newAccountProducts(new Map<String, Product> {
			Product.GEN => gen,
			Product.NEGOTIATE => neg,
			Product.CLM => clm
		}).getScmAuthBaseUrl();
		Test.stopTest();

		System.assertEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assertEquals('https://auth.test.springcm.com/', result2.toExternalForm());
		System.assertEquals(null, result3);
		System.assertEquals(null, result4);
		System.assertNotEquals(null, result5);
		System.assertEquals('https://auth.test.springcm.com/', result5.toExternalForm());
	}

	@IsTest
	static void test_saveRoles_no_change() {
		insert new List<ProductRoleSettings__c> {
			new ProductRoleSettings__c(Name = 'prs1', ProductName__c = 'p1'),
			new ProductRoleSettings__c(Name = 'prs2', ProductName__c = 'p2'),
			new ProductRoleSettings__c(Name = 'prs3', ProductName__c = 'p2')
		};
		Set<String> oldProducts = new Set<String> { 'p1', 'p2' };
		Set<String> newProducts = new Set<String> { 'p1', 'p2' };

		Test.startTest();
		System.assert(!AccountProducts.saveRoles(oldProducts, newProducts));
		Test.stopTest();

		System.assertEquals(3, Collection.size(ProductRoleSettings__c.getAll().values()));
	}

	@IsTest
	static void test_saveRoles_adding() {
		insert new List<ProductRoleSettings__c> {
			new ProductRoleSettings__c(Name = 'prs1', ProductName__c = 'p1'),
			new ProductRoleSettings__c(Name = 'prs2', ProductName__c = 'p2'),
			new ProductRoleSettings__c(Name = 'prs3', ProductName__c = 'p2')
		};
		Set<String> oldProducts = new Set<String> { 'p1', 'p2' };
		Set<String> newProducts = new Set<String> { 'p2', 'p3' };

		Test.startTest();
		System.assert(AccountProducts.saveRoles(oldProducts, newProducts));
		Test.stopTest();

		System.assertEquals(0, Collection.size(ProductRoleSettings__c.getAll().values()));
	}

	@IsTest
	static void test_saveRoles_removing() {
		insert new List<ProductRoleSettings__c> {
			new ProductRoleSettings__c(Name = 'prs1', ProductName__c = 'p1'),
			new ProductRoleSettings__c(Name = 'prs2', ProductName__c = 'p2'),
			new ProductRoleSettings__c(Name = 'prs3', ProductName__c = 'p2')
		};
		Set<String> oldProducts = new Set<String> { 'p1', 'p2' };
		Set<String> newProducts = new Set<String> { 'p2' };

		Test.startTest();
		System.assert(AccountProducts.saveRoles(oldProducts, newProducts));
		Test.stopTest();

		System.assertEquals(2, Collection.size(ProductRoleSettings__c.getAll().values()));
	}

	@IsTest
	static void test_save_uninitialized() {
		Test.startTest();
		System.assert(!AccountProducts.save());
		Test.stopTest();

		System.assert(ProductSettings__c.getAll().isEmpty());
	}

	@IsTest
	static void test_save_clean() {
		ESignatureProduct esign = new ESignatureProduct(
			'active', false, null, new Set<ESignatureProduct.Feature>());
		ProductSettings__c p = AccountProducts.DB.convert(esign);
		insert p;
		AccountSettings__c a = AccountSettings__c.getOrgDefaults();
		a.ProductsLastChecked__c = Datetime.now();
		a.ProductsCheckFrequency__c = 60;
		insert a;
		AccountProducts ap = AccountProducts.getInstance(
			new Url('https://provisioning.test.docusign.net'),
			new Url('https://esign.test.docusign.net'),
			UUID.randomUUID(),
			'unit.test');
		System.assertNotEquals(null, ap);
		System.assert(ap === AccountProducts.self);
		System.assert(!ap.isDirty);

		Test.startTest();
		System.assert(!AccountProducts.save());
		Test.stopTest();
	}

	@IsTest
	static void test_save_dirty() {
		DocuSignAPIMock.success();

		System.runAs(UserMock.createDocuSignSender()) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			s.ScmWebBaseUrl__c = null;
			s.ScmApiBaseUrl__c = null;
			s.ScmMergeBaseUrl__c = null;
			s.ScmAuthBaseUrl__c = null;
			s.ProductsLastChecked__c = null;
			s.ProductsCheckFrequency__c = null;
			update s;

			Test.startTest();
			AccountProducts ap = AccountProducts.getInstance();
			System.assertNotEquals(null, ap);
			System.assert(ap === AccountProducts.self);
			System.assert(ap.isDirty);
			System.assert(AccountProducts.save());
			Test.stopTest();

			System.assertEquals(4, ProductSettings__c.getAll().size());
			System.assertNotEquals(null, AccountSettings__c.getInstance().ProductsLastChecked__c);
			System.assertNotEquals(null, AccountSettings__c.getInstance().ProductsCheckFrequency__c);
		}
	}

	@IsTest
	static void test_getRoles_empty() {
		Test.startTest();
		try {
			AccountProducts.getRoles(null);
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			AccountProducts.getRoles(new Set<String>());
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getRoles_unsupported_products() {
		Test.startTest();
		try {
			AccountProducts.getRoles(new Set<String> { 'foo' });
			throw new AssertException('Expected failure');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UnsupportedProducts, ex.getMessage());
		}
	}

	@IsTest
	static void test_getRoles_uncached() {
		RoleAPIMock.success();

		System.runAs(UserMock.createDocuSignSender()) {
			ProductRoleSettings__c pr1 = new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.GEN, GenProduct.ROLE_GENERATOR),
				IsAdministrator__c = false,
				ProductName__c = Product.GEN,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = GenProduct.ROLE_GENERATOR);
			insert pr1;

			Test.startTest();
			Map<String, List<Product.Role>> result = AccountProducts.getRoles(new Set<String> {
				Product.GEN, Product.NEGOTIATE, Product.ESIGNATURE, Product.CLM
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(new Set<String> {
				Product.GEN, Product.NEGOTIATE, Product.ESIGNATURE, Product.CLM
			}, result.keySet());
			System.assertNotEquals(null, result.get(Product.ESIGNATURE));
			System.assertEquals(3, result.get(Product.ESIGNATURE).size());
			System.assertNotEquals(null, result.get(Product.GEN));
			System.assertEquals(1, result.get(Product.GEN).size());
			System.assertNotEquals(null, result.get(Product.NEGOTIATE));
			System.assertEquals(1, result.get(Product.NEGOTIATE).size());
			System.assertNotEquals(null, result.get(Product.CLM));
			System.assertEquals(3, result.get(Product.CLM).size());

			for (String p : result.keySet()) {
				for (Product.Role pr : result.get(p)) {
					System.assert(Product.isValidRole(pr));
				}
			}

			Map<String, ProductRoleSettings__c> pss = ProductRoleSettings__c.getAll();
			System.assertNotEquals(null, pss);
			System.assertEquals(8, pss.size());
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_USER)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.GEN, GenProduct.ROLE_GENERATOR)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.NEGOTIATE, NegotiateProduct.ROLE_NEGOTIATOR)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_ADMINISTRATOR)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_USER)));
			System.assert(pss.containsKey(AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_VIEWER)));
		}
	}

	@IsTest
	static void test_getRoles_cached() {
		insert new List<ProductRoleSettings__c> {
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_ADMINISTRATOR),
				IsAdministrator__c = true,
				ProductName__c = Product.ESIGNATURE,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ESignatureProduct.ROLE_ADMINISTRATOR),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_USER),
				IsAdministrator__c = false,
				ProductName__c = Product.ESIGNATURE,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ESignatureProduct.ROLE_USER),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.ESIGNATURE, ESignatureProduct.ROLE_SENDER),
				IsAdministrator__c = false,
				ProductName__c = Product.ESIGNATURE,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ESignatureProduct.ROLE_SENDER),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.GEN, GenProduct.ROLE_GENERATOR),
				IsAdministrator__c = false,
				ProductName__c = Product.GEN,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = GenProduct.ROLE_GENERATOR),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.NEGOTIATE, NegotiateProduct.ROLE_NEGOTIATOR),
				IsAdministrator__c = false,
				ProductName__c = Product.NEGOTIATE,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = NegotiateProduct.ROLE_NEGOTIATOR),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_ADMINISTRATOR),
				IsAdministrator__c = true,
				ProductName__c = Product.CLM,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ClmProduct.ROLE_ADMINISTRATOR),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_USER),
				IsAdministrator__c = false,
				ProductName__c = Product.CLM,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ClmProduct.ROLE_USER),
			new ProductRoleSettings__c(
				Name = AccountProducts.DB.getProductRoleKey(Product.CLM, ClmProduct.ROLE_VIEWER),
				IsAdministrator__c = false,
				ProductName__c = Product.CLM,
				RoleId__c = UUID.randomUUID().toString(),
				RoleName__c = ClmProduct.ROLE_VIEWER)
		};

		Test.startTest();
		Map<String, List<Product.Role>> result = AccountProducts.getRoles(new Set<String> {
			Product.GEN, Product.NEGOTIATE, Product.CLM, Product.ESIGNATURE
		});
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<String> {
			Product.GEN, Product.NEGOTIATE, Product.ESIGNATURE, Product.CLM
		}, result.keySet());
		System.assertNotEquals(null, result.get(Product.ESIGNATURE));
		System.assertEquals(3, result.get(Product.ESIGNATURE).size());
		System.assertNotEquals(null, result.get(Product.GEN));
		System.assertEquals(1, result.get(Product.GEN).size());
		System.assertNotEquals(null, result.get(Product.NEGOTIATE));
		System.assertEquals(1, result.get(Product.NEGOTIATE).size());
		System.assertNotEquals(null, result.get(Product.CLM));
		System.assertEquals(3, result.get(Product.CLM).size());

		for (String p : result.keySet()) {
			for (Product.Role pr : result.get(p)) {
				System.assert(Product.isValidRole(pr));
			}
		}
	}

	@IsTest
	static void test_clear() {
		insert new List<ProductSettings__c> {
			new ProductSettings__c(Name = 'ps1'),
			new ProductSettings__c(Name = 'ps2')
		};
		insert new List<ProductRoleSettings__c> {
			new ProductRoleSettings__c(Name = 'prs1'),
			new ProductRoleSettings__c(Name = 'prs2')
		};

		Test.startTest();
		System.assert(AccountProducts.clear());
		Test.stopTest();

		System.assert(Collection.isEmpty(ProductSettings__c.getAll()));
		System.assert(Collection.isEmpty(ProductRoleSettings__c.getAll()));
	}
}
