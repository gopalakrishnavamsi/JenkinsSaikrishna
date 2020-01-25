# Unit Testing with the Apex Toolkit

According to best practices and mandated by Salesforce in some cases, your Apex code must be covered by unit tests. When dealing with third-party code, this can be a difficult proposition. We strive to simplify this process via the Apex Toolkit. To that end, we have exposed a number of test utility methods and web service mocks.

Almost every Apex Toolkit method requires the current user to have some level of DocuSign access granted via permission sets. Without these permissions, service methods will throw `UnauthorizedException`s. While it is desirable to test and verify that unauthorized users are unable to access certain functionality, the reverse is also true. To enable this, the Apex Tookit exposes a number of [`dfsle.UserMock`](/salesforce/apex-toolkit-reference/usermock.html]) methods:
* `dfsle.UserMock.createDocuSignAdministrator`: Creates a test user that can be used for administrative Apex Toolkit functionality.
* `dfsle.UserMock.createDocuSignUser`: Creates a test user that can be used for non-administrative Apex Toolkit functionality.
* `dfsle.UserMock.createDocuSignSender`: Creates a test user that can be used for basic envelope sending.

Only one DocuSign test user may be used with each unit test.

Another common unit testing concern is mocking web service responses. Many Apex Toolkit methods involve callouts to DocuSign web services. Mocking each response would be time-consuming and require deep familiarity with the underlying APIs. Instead, the Apex Toolkit has you covered with the [`dfsle.ESignatureAPIMock`](/salesforce/apex-toolkit-reference/esignatureapimock.html) class. You can easily mock realistic responses from our eSignature REST API using this class. 

There are some limitations to keep in mind when mocking web services:
* You can only mock a single REST service per unit test.
* Because [`dfsle.ESignatureAPIMock`](/salesforce/apex-toolkit-reference/esignatureapimock.html) is in a managed package, you cannot use `Test.setMock`. Instead use [`dfsle.TestUtils.setMock`](/salesforce/apex-toolkit-reference/testutils.html) to set your mock class.

## Next Steps

For an example of how to integrate this into your unit tests, please check out our [Unit Testing Code Example](/salesforce/code-examples/salesforce-unit-testing).
