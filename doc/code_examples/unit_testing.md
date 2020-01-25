# Unit Testing with the Apex Toolkit
This example shows you how to integrate the Apex Toolkit into your unit tests.

## Before You Begin
1. Install the [DocuSign Apps Launcher](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FK9gtUAD) managed package.
1. Navigate to the DocuSign Setup tab and complete the login step.
1. Use the code provided in your application's Apex classes as a basis for your implementation of unit tests.

## Create a Unit Test
Use the [`dfsle.TestUtils`](/salesforce/apex-toolkit-reference/testutils.html), [`dfsle.ESignatureAPIMock`](/salesforce/apex-toolkit-reference/esignatureapimock.html), and [`dfsle.UserMock`](/salesforce/apex-toolkit-reference/usermock.html) classes to test your integration with the Apex Toolkit. In this example we are testing an existing Apex Toolkit method to send an envelope.

```Apex
@IsTest
private class UnitTestExample {

    @IsTest
    static void test_send_envelope() {

        // Mock the DocuSign eSignature API.
        dfsle.TestUtils.setMock(new dfsle.ESignatureAPIMock());
		
        // Run the test as a DocuSign Sender. This is required by dfsle.EnvelopeService.sendEnvelope.
        System.runAs(dfsle.UserMock.createDocuSignSender()) {

            // Create test data
            Account myAccount = new Account(Name = 'Test Account');
            insert myAccount;
             
            Contact myContact = new Contact(
                AccountId = myAccount.Id,
                FirstName = 'Test',
                LastName = 'Contact',
                Phone = '555-1234',
                Email = 'test.contact@example.com');
            insert myContact;
        
            // Create a test envelope with one document and one recipient
            dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(myAccount.Id))
                .withDocuments(new List<dfsle.Document> { 
                    dfsle.Document.fromTemplate(
                        dfsle.UUID.randomUUID(),
                        'test template')
                 })
                .withRecipients(new List<dfsle.Recipient> {
                    dfsle.Recipient.fromSource(
                        myContact.FirstName + ' ' + myContact.LastName,
                        myContact.Email,
                        myContact.Phone,
                        'Signer 1',
                        new dfsle.Entity(myContact.Id))
                });
    
            // Perform the test
            Test.startTest();
            dfsle.Envelope myResult = dfsle.EnvelopeService.sendEnvelope(myEnvelope, true);
            Test.stopTest();
        
            // Verify the results
            System.assertNotEquals(null, myResult);
            // etc...
        }
    }
}
```
